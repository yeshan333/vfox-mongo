local mongo_utils = require("mongo_utils")

--- Returns some pre-installed information, such as version number, download address, local files, etc.
--- If checksum is provided, vfox will automatically check it for you.
--- @param ctx table
--- @field ctx.version string User-input version
--- @return table Version information
function PLUGIN:PreInstall(ctx)
    local user_version = ctx.version
    
    -- Get the full version string if user provided a simplified version
    local mongo_version = mongo_utils.get_full_version(user_version)
    
    -- If the version map is empty (e.g., user directly specified a full version),
    -- use the version as-is
    if mongo_version == user_version and not string.match(user_version, "^[0-9]") then
        -- This looks like a full version string already, use it directly
        mongo_version = user_version
    elseif mongo_version == user_version then
        -- This is a simplified version but no mapping exists, need to reconstruct
        -- This happens when user bypasses the search and directly installs
        print("Warning: Using simplified version format. Full version will be auto-detected.")
        mongo_version = user_version
    end
    
    local download_url
    if RUNTIME.osType == "linux" then
        download_url = "https://fastdl.mongodb.org/linux/mongodb-linux-" .. mongo_version .. ".tgz"
    elseif RUNTIME.osType == "windows" then
        download_url = "https://fastdl.mongodb.org/windows/mongodb-" .. mongo_version .. ".zip"
    else
        download_url = "https://fastdl.mongodb.org/osx/mongodb-" .. mongo_version .. ".tgz"
    end
    print("mongo download url: " .. download_url)
    
    return {
        version = mongo_version,
        url = download_url,
    }
end