local http = require("http")

local mongo_utils = {}

function mongo_utils.get_mongo_release_verions()
    local fetch_url = "https://fastly.jsdelivr.net/gh/yeshan333/vfox-mongo@main/assets/" .. RUNTIME.osType .. "_versions.txt"
    local resp, err = http.get({
        url = fetch_url
    })
    local result = {}
    for version in string.gmatch(resp.body, '([^\n]+)') do
        table.insert(result, {
            version = version
        })
    end
    return result
end

return mongo_utils