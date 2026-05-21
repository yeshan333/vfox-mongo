--[[
  Unit tests for lib/mongosh_utils.lua

  Run with:  lua tests/test_mongosh_utils.lua
  (requires Lua 5.3 or later; no network access needed)
--]]

-- Minimal vfox runtime stub
RUNTIME = { osType = "linux", archType = "amd64" }

-- Stub the http module with a controllable get function
local http_stub = {}
http_stub.response = { status_code = 200, body = "2.8.3\n2.8.2\n2.7.0\n" }
http_stub.err = nil
http_stub.get = function(_) return http_stub.response, http_stub.err end
package.loaded["http"] = http_stub

-- Point require() at the lib directory
package.path = "./lib/?.lua;" .. package.path

local mongosh_utils = require("mongosh_utils")

-- helpers
local pass_count = 0
local fail_count = 0

local function assert_eq(label, got, expected)
    if got == expected then
        pass_count = pass_count + 1
    else
        fail_count = fail_count + 1
        print("FAIL  " .. label)
        print("      expected: " .. tostring(expected))
        print("      got:      " .. tostring(got))
    end
end

-- normalize_arch
RUNTIME.archType = "amd64"
assert_eq("amd64 -> x64", mongosh_utils.normalize_arch(), "x64")

RUNTIME.archType = "arm64"
assert_eq("arm64 -> arm64", mongosh_utils.normalize_arch(), "arm64")

RUNTIME.archType = "x86_64"
assert_eq("x86_64 -> x86_64", mongosh_utils.normalize_arch(), "x86_64")

-- get_platform_info
RUNTIME.osType = "darwin"; RUNTIME.archType = "arm64"
local plat, arch, ext = mongosh_utils.get_platform_info()
assert_eq("darwin platform", plat, "darwin")
assert_eq("darwin arch arm64", arch, "arm64")
assert_eq("darwin ext", ext, "zip")

RUNTIME.osType = "darwin"; RUNTIME.archType = "amd64"
plat, arch, ext = mongosh_utils.get_platform_info()
assert_eq("darwin amd64 arch", arch, "x64")

RUNTIME.osType = "linux"; RUNTIME.archType = "amd64"
plat, arch, ext = mongosh_utils.get_platform_info()
assert_eq("linux platform", plat, "linux")
assert_eq("linux arch amd64", arch, "x64")
assert_eq("linux ext", ext, "tgz")

RUNTIME.osType = "linux"; RUNTIME.archType = "arm64"
plat, arch, ext = mongosh_utils.get_platform_info()
assert_eq("linux arm64 arch", arch, "arm64")

RUNTIME.osType = "windows"; RUNTIME.archType = "amd64"
plat, arch, ext = mongosh_utils.get_platform_info()
assert_eq("windows platform", plat, "win32")
assert_eq("windows arch", arch, "x64")
assert_eq("windows ext", ext, "zip")

-- get_download_url
RUNTIME.osType = "darwin"; RUNTIME.archType = "arm64"
local url, filename, fext = mongosh_utils.get_download_url("2.8.3")
assert_eq("darwin arm64 url",
    url,
    "https://github.com/mongodb-js/mongosh/releases/download/v2.8.3/mongosh-2.8.3-darwin-arm64.zip")
assert_eq("darwin arm64 filename", filename, "mongosh-2.8.3-darwin-arm64.zip")
assert_eq("darwin arm64 ext", fext, "zip")

RUNTIME.osType = "linux"; RUNTIME.archType = "amd64"
url, filename, fext = mongosh_utils.get_download_url("2.8.3")
assert_eq("linux x64 url",
    url,
    "https://github.com/mongodb-js/mongosh/releases/download/v2.8.3/mongosh-2.8.3-linux-x64.tgz")
assert_eq("linux x64 filename", filename, "mongosh-2.8.3-linux-x64.tgz")

RUNTIME.osType = "windows"; RUNTIME.archType = "amd64"
url, filename, fext = mongosh_utils.get_download_url("2.8.3")
assert_eq("windows url",
    url,
    "https://github.com/mongodb-js/mongosh/releases/download/v2.8.3/mongosh-2.8.3-win32-x64.zip")
assert_eq("windows filename", filename, "mongosh-2.8.3-win32-x64.zip")

-- get_versions_from_remote (success)
http_stub.response = { status_code = 200, body = "2.8.3\n2.8.2\n2.7.0\n" }
http_stub.err = nil
local versions, err = mongosh_utils.get_versions_from_remote()
assert_eq("versions_from_remote no error", err, nil)
assert_eq("versions_from_remote count", #versions, 3)
assert_eq("versions_from_remote first", versions[1], "2.8.3")
assert_eq("versions_from_remote last", versions[3], "2.7.0")

-- get_latest_version (success)
local latest, lerr = mongosh_utils.get_latest_version()
assert_eq("get_latest_version no error", lerr, nil)
assert_eq("get_latest_version value", latest, "2.8.3")

-- get_versions_from_remote (http error)
http_stub.response = nil
http_stub.err = "connection refused"
versions, err = mongosh_utils.get_versions_from_remote()
assert_eq("versions_from_remote http err returns nil", versions, nil)
assert_eq("versions_from_remote http err msg", err ~= nil, true)

-- get_versions_from_remote (non-200 status)
http_stub.response = { status_code = 403, body = "" }
http_stub.err = nil
versions, err = mongosh_utils.get_versions_from_remote()
assert_eq("versions_from_remote 403 returns nil", versions, nil)
assert_eq("versions_from_remote 403 err msg", err ~= nil, true)

-- get_versions_from_remote (empty body)
http_stub.response = { status_code = 200, body = "" }
http_stub.err = nil
versions, err = mongosh_utils.get_versions_from_remote()
assert_eq("versions_from_remote empty returns nil", versions, nil)
assert_eq("versions_from_remote empty err msg", err ~= nil, true)

-- summary
print(string.format("\n%d passed, %d failed", pass_count, fail_count))
if fail_count > 0 then
    os.exit(1)
end
