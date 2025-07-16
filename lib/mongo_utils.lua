local http = require("http")

local mongo_utils = {}

function mongo_utils.get_mongo_release_verions()
    local fetch_url = "https://fastly.jsdelivr.net/gh/yeshan333/vfox-mongo@main/assets/" .. RUNTIME.osType .. "_versions.txt"
    local resp, err = http.get({
        url = fetch_url
    })
    local result = {}
    local seen_versions = {}
    
    for version in string.gmatch(resp.body, '([^\n]+)') do
        -- Extract semantic version from complex version string
        -- Pattern matches versions like: 8.1.0, 8.1.0-rc0, 8.0.6, 7.0.12, etc.
        local semantic_version = string.match(version, '(%d+%.%d+%.%d+[%w%-]*)$') or
                                string.match(version, '(%d+%.%d+%.%d+[%w%-]*)[^/]*$')
        
        -- Fallback to the original version if no semantic version found
        local display_version = semantic_version or version
        
        -- Only add unique versions
        if not seen_versions[display_version] then
            seen_versions[display_version] = true
            table.insert(result, {
                version = display_version
            })
        end
    end
    
    -- Sort versions in descending order (newest first)
    table.sort(result, function(a, b)
        return a.version > b.version
    end)
    
    return result
end

return mongo_utils