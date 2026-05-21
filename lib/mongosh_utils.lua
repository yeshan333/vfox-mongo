local http = require("http")
local json = require("json")

local mongosh_utils = {}

function mongosh_utils.get_latest_version()
    local resp, err = http.get({
        url = "https://api.github.com/repos/mongodb-js/mongosh/releases/latest",
        headers = { ["Accept"] = "application/vnd.github.v3+json" }
    })
    if err ~= nil then
        return nil, "Failed to fetch mongosh latest version: " .. tostring(err)
    end
    if resp.status_code ~= 200 then
        return nil, "GitHub API returned status " .. resp.status_code
    end
    local data = json.decode(resp.body)
    if data == nil or data.tag_name == nil then
        return nil, "Failed to parse mongosh release info"
    end
    return string.gsub(data.tag_name, "^v", ""), nil
end

function mongosh_utils.normalize_arch()
    local arch = RUNTIME.archType
    if arch == "amd64" then
        return "x64"
    end
    return arch
end

function mongosh_utils.get_platform_info()
    local arch = mongosh_utils.normalize_arch()
    if RUNTIME.osType == "darwin" then
        return "darwin", arch, "zip"
    elseif RUNTIME.osType == "windows" then
        return "win32", "x64", "zip"
    else
        return "linux", arch, "tgz"
    end
end

function mongosh_utils.get_download_url(version)
    local platform, arch, ext = mongosh_utils.get_platform_info()
    local filename = "mongosh-" .. version .. "-" .. platform .. "-" .. arch .. "." .. ext
    local url = "https://github.com/mongodb-js/mongosh/releases/download/v"
        .. version .. "/" .. filename
    return url, filename, ext
end

function mongosh_utils.exec(cmd)
    local ok = os.execute(cmd)
    return ok == true or ok == 0
end

function mongosh_utils.install_to(target_bin_dir)
    local version, err
    local user_version = os.getenv("MONGOSH_VERSION")
    if user_version and user_version ~= "" then
        version = string.gsub(user_version, "^v", "")
    else
        version, err = mongosh_utils.get_latest_version()
        if err then
            return false, err
        end
    end

    local url, filename, ext = mongosh_utils.get_download_url(version)
    print("[mongosh] Installing mongosh " .. version .. " ...")
    print("[mongosh] Download URL: " .. url)

    if RUNTIME.osType == "windows" then
        return mongosh_utils.install_windows(url, filename, version, target_bin_dir)
    end
    return mongosh_utils.install_unix(url, filename, ext, version, target_bin_dir)
end

function mongosh_utils.install_unix(url, filename, ext, version, target_bin_dir)
    local tmp_dir = os.tmpname() .. "_mongosh"
    if not mongosh_utils.exec("mkdir -p " .. tmp_dir) then
        return false, "Failed to create temp directory"
    end

    local archive_path = tmp_dir .. "/" .. filename
    if not mongosh_utils.exec("curl -fsSL -o " .. archive_path .. " " .. url) then
        mongosh_utils.exec("rm -rf " .. tmp_dir)
        return false, "Failed to download mongosh"
    end

    local extract_cmd
    if ext == "tgz" then
        extract_cmd = "tar -xzf " .. archive_path .. " -C " .. tmp_dir
    else
        extract_cmd = "unzip -qo " .. archive_path .. " -d " .. tmp_dir
    end
    if not mongosh_utils.exec(extract_cmd) then
        mongosh_utils.exec("rm -rf " .. tmp_dir)
        return false, "Failed to extract mongosh archive"
    end

    local platform, arch = mongosh_utils.get_platform_info()
    local extracted_bin = tmp_dir .. "/mongosh-" .. version .. "-" .. platform .. "-" .. arch .. "/bin"

    if not mongosh_utils.exec("cp -f " .. extracted_bin .. "/mongosh " .. target_bin_dir .. "/") then
        mongosh_utils.exec("rm -rf " .. tmp_dir)
        return false, "Failed to copy mongosh binary"
    end
    -- Copy shared libraries if present (mongosh_crypt_v1.so/.dylib)
    mongosh_utils.exec("cp -f " .. extracted_bin .. "/mongosh_crypt_v1* " .. target_bin_dir .. "/ 2>/dev/null")

    mongosh_utils.exec("rm -rf " .. tmp_dir)
    print("[mongosh] Successfully installed mongosh " .. version)
    return true, nil
end

function mongosh_utils.install_windows(url, filename, version, target_bin_dir)
    local tmp_dir = os.getenv("TEMP") .. "\\mongosh_install"
    local ps_mkdir = 'powershell -Command "New-Item -ItemType Directory -Force -Path \'' .. tmp_dir .. '\'"'
    if not mongosh_utils.exec(ps_mkdir) then
        return false, "Failed to create temp directory"
    end

    local archive_path = tmp_dir .. "\\" .. filename
    local dl_cmd = "curl.exe -fsSL -o \"" .. archive_path .. "\" \"" .. url .. "\""
    if not mongosh_utils.exec(dl_cmd) then
        mongosh_utils.exec('powershell -Command "Remove-Item -Recurse -Force \'' .. tmp_dir .. '\'"')
        return false, "Failed to download mongosh"
    end

    local extract_cmd = 'powershell -Command "Expand-Archive -Force -Path \''
        .. archive_path .. '\' -DestinationPath \'' .. tmp_dir .. '\'"'
    if not mongosh_utils.exec(extract_cmd) then
        mongosh_utils.exec('powershell -Command "Remove-Item -Recurse -Force \'' .. tmp_dir .. '\'"')
        return false, "Failed to extract mongosh archive"
    end

    local extracted_bin = tmp_dir .. "\\mongosh-" .. version .. "-win32-x64\\bin"
    local copy_cmd = 'powershell -Command "Copy-Item -Force \'' .. extracted_bin .. "\\*\" '" .. target_bin_dir .. "\\'\""
    if not mongosh_utils.exec(copy_cmd) then
        mongosh_utils.exec('powershell -Command "Remove-Item -Recurse -Force \'' .. tmp_dir .. '\'"')
        return false, "Failed to copy mongosh binaries"
    end

    mongosh_utils.exec('powershell -Command "Remove-Item -Recurse -Force \'' .. tmp_dir .. '\'"')
    print("[mongosh] Successfully installed mongosh " .. version)
    return true, nil
end

return mongosh_utils
