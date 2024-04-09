--- Returns some pre-installed information, such as version number, download address, local files, etc.
--- If checksum is provided, vfox will automatically check it for you.
--- @param ctx table
--- @field ctx.version string User-input version
--- @return table Version information
function PLUGIN:PreInstall(ctx)
    local mongo_version = ctx.version    
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