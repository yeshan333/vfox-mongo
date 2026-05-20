local http = require("http")

local mongo_utils = {}

-- Extract the version number from a full platform-specific version string.
-- e.g., "x86_64-ubuntu2404-8.3.2"        -> "8.3.2"
-- e.g., "macos-arm64-8.3.0-rc5"           -> "8.3.0-rc5"
-- e.g., "windows-x86_64-enterprise-8.2.1" -> "8.2.1"
function mongo_utils.extract_version_number(version_str)
    return string.match(version_str, "(%d+%.%d+%.%d+[%-%a%d]*)$")
end

-- Fetch all raw platform-specific version strings for the current OS.
function mongo_utils.get_all_versions_raw()
    local fetch_url = "https://fastly.jsdelivr.net/gh/yeshan333/vfox-mongo@main/assets/" .. RUNTIME.osType .. "_versions.txt"
    local resp, err = http.get({
        url = fetch_url
    })
    if err ~= nil then
        error("Failed to fetch version list: " .. tostring(err))
    end
    local versions = {}
    for version in string.gmatch(resp.body, '([^\n]+)') do
        table.insert(versions, version)
    end
    return versions
end

-- Return deduplicated, human-readable version numbers for `vfox search`.
function mongo_utils.get_mongo_release_verions()
    local all_versions = mongo_utils.get_all_versions_raw()
    local seen = {}
    local result = {}
    for _, version_str in ipairs(all_versions) do
        local ver = mongo_utils.extract_version_number(version_str)
        if ver ~= nil and not seen[ver] then
            seen[ver] = true
            table.insert(result, { version = ver })
        end
    end
    return result
end

-- Map RUNTIME.archType to the architecture name used in MongoDB version strings.
-- Linux:  amd64 -> x86_64, arm64 -> aarch64
-- macOS:  amd64 -> x86_64, arm64 -> arm64
function mongo_utils.normalize_arch()
    local arch = RUNTIME.archType
    if arch == "amd64" then
        return "x86_64"
    elseif arch == "arm64" and RUNTIME.osType == "linux" then
        return "aarch64"
    end
    return arch
end

-- Parse /etc/os-release and return the MongoDB distribution target string.
-- e.g., Ubuntu 22.04 -> "ubuntu2204", Debian 12 -> "debian12", RHEL 8 -> "rhel8"
function mongo_utils.detect_linux_target()
    local f = io.open("/etc/os-release", "r")
    if f == nil then
        return nil
    end
    local content = f:read("*all")
    f:close()

    local id = string.match(content, '\nID=([^\n]+)') or string.match(content, '^ID=([^\n]+)')
    if id then
        id = string.lower(string.gsub(id, '"', ''))
    end

    local version_id = string.match(content, 'VERSION_ID="?([^"\n]+)"?')
    if version_id then
        version_id = string.gsub(version_id, '"', '')
    end

    if id == nil then
        return nil
    end

    if id == "ubuntu" and version_id then
        local major, minor = string.match(version_id, "(%d+)%.(%d+)")
        if major and minor then
            return "ubuntu" .. major .. minor
        end
    elseif id == "debian" and version_id then
        local major = string.match(version_id, "(%d+)")
        if major then
            return "debian" .. major
        end
    elseif (id == "rhel" or id == "centos" or id == "rocky" or id == "almalinux") and version_id then
        local major = string.match(version_id, "(%d+)")
        if major then
            return "rhel" .. major
        end
    elseif (id == "sles" or id == "opensuse-leap") and version_id then
        local major = string.match(version_id, "(%d+)")
        if major then
            return "suse" .. major
        end
    elseif id == "amzn" and version_id then
        return "amazon" .. version_id
    end

    return nil
end

-- Find the best-matching community-edition platform version string for a given
-- version number and the current OS/arch.  Falls back through common distros
-- when the exact detected distro is not found.
-- Returns the full version string (e.g. "x86_64-ubuntu2204-8.3.2") or nil.
function mongo_utils.find_matching_version(version_number, all_versions)
    local arch = mongo_utils.normalize_arch()

    if RUNTIME.osType == "darwin" then
        -- Community: macos-{arch}-{version}
        local target = "macos-" .. arch .. "-" .. version_number
        for _, v in ipairs(all_versions) do
            if v == target then
                return v
            end
        end
        -- Fallback: any entry containing the arch and version
        for _, v in ipairs(all_versions) do
            local escaped = version_number:gsub("%-", "%%-")
            if string.match(v, escaped .. "$") and string.find(v, arch, 1, true) then
                return v
            end
        end

    elseif RUNTIME.osType == "windows" then
        -- Community: windows-x86_64-{version}
        local target = "windows-x86_64-" .. version_number
        for _, v in ipairs(all_versions) do
            if v == target then
                return v
            end
        end

    elseif RUNTIME.osType == "linux" then
        local linux_target = mongo_utils.detect_linux_target()
        -- Try the detected distro first (community edition)
        if linux_target then
            local target = arch .. "-" .. linux_target .. "-" .. version_number
            for _, v in ipairs(all_versions) do
                if v == target then
                    return v
                end
            end
        end
        -- Fallback chain for common Linux distros
        local fallbacks = { "ubuntu2204", "ubuntu2004", "rhel8", "debian12", "amazon2023" }
        for _, fb in ipairs(fallbacks) do
            local target = arch .. "-" .. fb .. "-" .. version_number
            for _, v in ipairs(all_versions) do
                if v == target then
                    return v
                end
            end
        end
    end

    return nil
end

return mongo_utils