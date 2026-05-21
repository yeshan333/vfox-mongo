local mongosh_utils = require("mongosh_utils")

--- Extension point, called after PreInstall, can perform additional operations,
--- such as file operations for the SDK installation directory or compile source code
function PLUGIN:PostInstall(ctx)
    local sdkInfo = ctx.sdkInfo['mongo']
    local path = sdkInfo.path
    print("mongo installed path: " .. path)

    local bin_dir = path .. "/bin"
    local ok, err = mongosh_utils.install_to(bin_dir)
    if not ok then
        print("[mongosh] WARNING: " .. err)
        print("[mongosh] You can install mongosh manually later: https://github.com/mongodb-js/mongosh")
    end
end
