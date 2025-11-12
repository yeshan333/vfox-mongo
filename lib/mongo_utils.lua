local http = require("http")

local mongo_utils = {}

-- Detect Linux distribution and version from /etc/os-release
function mongo_utils.detect_linux_distro()
    local file = io.open("/etc/os-release", "r")
    if not file then
        return nil
    end
    
    local id = nil
    local version_id = nil
    
    for line in file:lines() do
        local key, value = line:match("^([^=]+)=(.+)$")
        if key and value then
            -- Remove quotes from value
            value = value:gsub('^"', ''):gsub('"$', '')
            value = value:gsub("^'", ''):gsub("'$", '')
            
            if key == "ID" then
                id = value
            elseif key == "VERSION_ID" then
                version_id = value
            end
        end
    end
    file:close()
    
    if id and version_id then
        -- Convert version to MongoDB format (e.g., "22.04" -> "2204", "8" -> "8")
        local mongo_version = version_id:gsub("%.", "")
        
        -- Map common distro names to MongoDB naming
        local distro_map = {
            ubuntu = "ubuntu",
            debian = "debian",
            rhel = "rhel",
            centos = "rhel",  -- CentOS uses RHEL packages
            amzn = "amazon",
            sles = "suse",
            opensuse = "suse"
        }
        
        local distro = distro_map[id] or id
        return distro .. mongo_version
    end
    
    return nil
end

-- Get the architecture prefix for version matching
function mongo_utils.get_arch_prefix()
    local arch = RUNTIME.archType
    
    -- Map vfox architecture names to MongoDB naming conventions
    local arch_map = {
        amd64 = "x86_64",
        ["386"] = "i686",
        arm64 = "arm64",  -- for some older Ubuntu versions
        aarch64 = "aarch64"  -- for newer versions
    }
    
    -- For Linux, we might need to check both arm64 and aarch64
    if RUNTIME.osType == "linux" and arch == "arm64" then
        return {"arm64", "aarch64"}
    end
    
    local mapped_arch = arch_map[arch] or arch
    return {mapped_arch}
end

-- Get platform-specific prefix for filtering versions
function mongo_utils.get_platform_prefixes()
    local prefixes = {}
    
    if RUNTIME.osType == "darwin" then
        -- For macOS, the format is "macos-{arch}-"
        local archs = mongo_utils.get_arch_prefix()
        for _, arch in ipairs(archs) do
            table.insert(prefixes, "macos-" .. arch .. "-")
        end
    elseif RUNTIME.osType == "windows" then
        -- For Windows, the format is "windows-{arch}-"
        local archs = mongo_utils.get_arch_prefix()
        for _, arch in ipairs(archs) do
            table.insert(prefixes, "windows-" .. arch .. "-")
        end
    elseif RUNTIME.osType == "linux" then
        -- For Linux, try to detect distro and architecture
        local distro = mongo_utils.detect_linux_distro()
        local archs = mongo_utils.get_arch_prefix()
        
        if distro then
            -- Format: "{arch}-{distro}-"
            for _, arch in ipairs(archs) do
                table.insert(prefixes, arch .. "-" .. distro .. "-")
            end
        else
            -- If distro detection fails, use all versions for this architecture
            for _, arch in ipairs(archs) do
                table.insert(prefixes, arch .. "-")
            end
        end
    end
    
    return prefixes
end

-- Extract version number from full version string
function mongo_utils.extract_version_number(full_version, prefix)
    if full_version:sub(1, #prefix) == prefix then
        local remainder = full_version:sub(#prefix + 1)
        -- Remove "enterprise-" prefix if present
        remainder = remainder:gsub("^enterprise%-", "")
        -- If the prefix was just arch (e.g., "x86_64-"), remove the distro part too
        -- This handles the fallback case when distro detection fails
        -- Format: ubuntu2404-8.0.6 -> 8.0.6
        remainder = remainder:gsub("^[^%-]+%-([0-9])", "%1")
        return remainder
    end
    return nil
end

-- Store mapping of simplified versions to full versions
mongo_utils.version_map = {}

function mongo_utils.get_mongo_release_verions()
    local fetch_url = "https://fastly.jsdelivr.net/gh/yeshan333/vfox-mongo@main/assets/" .. RUNTIME.osType .. "_versions.txt"
    local resp, err = http.get({
        url = fetch_url
    })
    
    if err ~= nil or resp.status_code ~= 200 then
        return {}
    end
    
    local prefixes = mongo_utils.get_platform_prefixes()
    local seen_versions = {}
    local result = {}
    
    -- Clear previous version map
    mongo_utils.version_map = {}
    
    for full_version in string.gmatch(resp.body, '([^\n]+)') do
        -- Try to match with any of our prefixes
        for _, prefix in ipairs(prefixes) do
            local version_number = mongo_utils.extract_version_number(full_version, prefix)
            if version_number then
                -- Only add if we haven't seen this version number yet
                if not seen_versions[version_number] then
                    seen_versions[version_number] = true
                    table.insert(result, {
                        version = version_number
                    })
                end
                
                -- Store the full version mapping, preferring non-enterprise versions
                if not mongo_utils.version_map[version_number] then
                    mongo_utils.version_map[version_number] = full_version
                elseif not string.match(full_version, "%-enterprise%-") and string.match(mongo_utils.version_map[version_number], "%-enterprise%-") then
                    -- Replace enterprise version with non-enterprise version
                    mongo_utils.version_map[version_number] = full_version
                end
                
                break  -- Found a match, no need to check other prefixes
            end
        end
    end
    
    return result
end

-- Get full version string from simplified version
function mongo_utils.get_full_version(simplified_version)
    return mongo_utils.version_map[simplified_version] or simplified_version
end

return mongo_utils