local mongo_utils = require("mongo_utils")

--- Returns some pre-installed information, such as version number, download address, local files, etc.
--- If checksum is provided, vfox will automatically check it for you.
--- @param ctx table
--- @field ctx.version string User-input version
--- @return table Version information
function PLUGIN:PreInstall(ctx)
    local version_number = ctx.version

    -- Fetch the full platform-specific version list and find the best match
    -- for the current OS and architecture.
    local all_versions = mongo_utils.get_all_versions_raw()
    local mongo_version = mongo_utils.find_matching_version(version_number, all_versions)
    if mongo_version == nil then
        error("No matching MongoDB package found for version " .. version_number
              .. " on " .. RUNTIME.osType .. "/" .. RUNTIME.archType
              .. ". Please check that the version exists.")
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
        version = version_number,
        url = download_url,
    }
end