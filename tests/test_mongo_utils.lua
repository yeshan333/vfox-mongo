--[[
  Unit tests for lib/mongo_utils.lua

  Run with:  lua tests/test_mongo_utils.lua
  (requires Lua 5.3 or later; no network access needed)
--]]

-- Minimal vfox runtime stub
RUNTIME = { osType = "linux", archType = "amd64" }

-- Stub the http module so the library loads without a network call
package.loaded["http"] = {}

-- Point require() at the lib directory
package.path = "./lib/?.lua;" .. package.path

local mongo_utils = require("mongo_utils")

-- ── helpers ─────────────────────────────────────────────────────────────────

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

-- ── extract_version_number ───────────────────────────────────────────────────

assert_eq("extract stable (linux)",        mongo_utils.extract_version_number("x86_64-ubuntu2404-8.3.2"),             "8.3.2")
assert_eq("extract stable (enterprise)",   mongo_utils.extract_version_number("x86_64-enterprise-ubuntu2404-8.3.2"),  "8.3.2")
assert_eq("extract stable (aarch64)",      mongo_utils.extract_version_number("aarch64-ubuntu2204-8.3.2"),            "8.3.2")
assert_eq("extract rc (darwin arm64)",     mongo_utils.extract_version_number("macos-arm64-8.3.0-rc5"),               "8.3.0-rc5")
assert_eq("extract alpha (darwin ent)",    mongo_utils.extract_version_number("macos-x86_64-enterprise-8.3.0-alpha6"),"8.3.0-alpha6")
assert_eq("extract stable (windows)",      mongo_utils.extract_version_number("windows-x86_64-8.2.1"),                "8.2.1")
assert_eq("extract rc (windows ent)",      mongo_utils.extract_version_number("windows-x86_64-enterprise-8.2.1-rc1"), "8.2.1-rc1")

-- ── normalize_arch ───────────────────────────────────────────────────────────

RUNTIME.osType = "linux";   RUNTIME.archType = "amd64"
assert_eq("linux amd64  -> x86_64",  mongo_utils.normalize_arch(), "x86_64")

RUNTIME.osType = "linux";   RUNTIME.archType = "arm64"
assert_eq("linux arm64  -> aarch64", mongo_utils.normalize_arch(), "aarch64")

RUNTIME.osType = "darwin";  RUNTIME.archType = "amd64"
assert_eq("darwin amd64 -> x86_64",  mongo_utils.normalize_arch(), "x86_64")

RUNTIME.osType = "darwin";  RUNTIME.archType = "arm64"
assert_eq("darwin arm64 -> arm64",   mongo_utils.normalize_arch(), "arm64")

RUNTIME.osType = "windows"; RUNTIME.archType = "amd64"
assert_eq("win amd64   -> x86_64",   mongo_utils.normalize_arch(), "x86_64")

-- ── detect_linux_target ──────────────────────────────────────────────────────

local orig_io_open = io.open

local function fake_os_release(content)
    io.open = function(path, mode)
        if path == "/etc/os-release" then
            return {
                read  = function(self, _) return content end,
                close = function(self) end,
            }
        end
        return orig_io_open(path, mode)
    end
end

fake_os_release('ID=ubuntu\nVERSION_ID="22.04"\n')
assert_eq("detect ubuntu 22.04", mongo_utils.detect_linux_target(), "ubuntu2204")

fake_os_release('ID=ubuntu\nVERSION_ID="20.04"\n')
assert_eq("detect ubuntu 20.04", mongo_utils.detect_linux_target(), "ubuntu2004")

fake_os_release('ID=ubuntu\nVERSION_ID="24.04"\n')
assert_eq("detect ubuntu 24.04", mongo_utils.detect_linux_target(), "ubuntu2404")

fake_os_release('ID=debian\nVERSION_ID="12"\n')
assert_eq("detect debian 12", mongo_utils.detect_linux_target(), "debian12")

fake_os_release('ID=rhel\nVERSION_ID="8"\n')
assert_eq("detect rhel 8", mongo_utils.detect_linux_target(), "rhel8")

fake_os_release('ID="centos"\nVERSION_ID="7"\n')
assert_eq("detect centos 7 -> rhel7", mongo_utils.detect_linux_target(), "rhel7")

fake_os_release('ID=rocky\nVERSION_ID="9"\n')
assert_eq("detect rocky 9 -> rhel9", mongo_utils.detect_linux_target(), "rhel9")

fake_os_release('ID=almalinux\nVERSION_ID="8"\n')
assert_eq("detect almalinux 8 -> rhel8", mongo_utils.detect_linux_target(), "rhel8")

fake_os_release('ID=amzn\nVERSION_ID=2023\n')
assert_eq("detect amazon linux 2023", mongo_utils.detect_linux_target(), "amazon2023")

fake_os_release('ID=sles\nVERSION_ID="15"\n')
assert_eq("detect sles 15 -> suse15", mongo_utils.detect_linux_target(), "suse15")

-- No /etc/os-release
io.open = function(path, mode)
    if path == "/etc/os-release" then return nil end
    return orig_io_open(path, mode)
end
assert_eq("detect nil when no /etc/os-release", mongo_utils.detect_linux_target(), nil)

io.open = orig_io_open

-- ── find_matching_version ────────────────────────────────────────────────────

local linux_versions = {
    "x86_64-enterprise-ubuntu2404-8.3.2",
    "x86_64-ubuntu2404-8.3.2",
    "aarch64-enterprise-ubuntu2404-8.3.2",
    "aarch64-ubuntu2404-8.3.2",
    "x86_64-ubuntu2204-8.3.2",
    "aarch64-ubuntu2204-8.3.2",
    "x86_64-rhel8-8.3.2",
    "aarch64-rhel8-8.3.2",
    "x86_64-debian12-8.3.2",
    "x86_64-amazon2023-8.3.2",
}

local darwin_versions = {
    "macos-arm64-enterprise-8.3.2",
    "macos-arm64-8.3.2",
    "macos-x86_64-8.3.2",
    "macos-x86_64-enterprise-8.3.2",
    "macos-arm64-8.3.0-rc5",
    "macos-x86_64-8.3.0-rc5",
}

local windows_versions = {
    "windows-x86_64-8.3.2",
    "windows-x86_64-enterprise-8.3.2",
}

-- Linux amd64: detected ubuntu 22.04 -> exact match
RUNTIME.osType = "linux"; RUNTIME.archType = "amd64"
fake_os_release('ID=ubuntu\nVERSION_ID="22.04"\n')
assert_eq("linux/amd64/ubuntu2204 exact", mongo_utils.find_matching_version("8.3.2", linux_versions), "x86_64-ubuntu2204-8.3.2")
io.open = orig_io_open

-- Linux arm64: detected ubuntu 24.04 -> exact match
RUNTIME.osType = "linux"; RUNTIME.archType = "arm64"
fake_os_release('ID=ubuntu\nVERSION_ID="24.04"\n')
assert_eq("linux/arm64/ubuntu2404 exact", mongo_utils.find_matching_version("8.3.2", linux_versions), "aarch64-ubuntu2404-8.3.2")
io.open = orig_io_open

-- Linux amd64: detected rhel 8 -> exact match
RUNTIME.osType = "linux"; RUNTIME.archType = "amd64"
fake_os_release('ID=rhel\nVERSION_ID="8"\n')
assert_eq("linux/amd64/rhel8 exact", mongo_utils.find_matching_version("8.3.2", linux_versions), "x86_64-rhel8-8.3.2")
io.open = orig_io_open

-- Linux amd64: unknown distro -> fallback ubuntu2204
RUNTIME.osType = "linux"; RUNTIME.archType = "amd64"
io.open = function(path) return nil end   -- no /etc/os-release
assert_eq("linux/amd64/fallback -> ubuntu2204", mongo_utils.find_matching_version("8.3.2", linux_versions), "x86_64-ubuntu2204-8.3.2")
io.open = orig_io_open

-- Linux: version not in list -> nil
RUNTIME.osType = "linux"; RUNTIME.archType = "amd64"
io.open = function(path) return nil end
assert_eq("linux: version not found -> nil", mongo_utils.find_matching_version("0.0.0", linux_versions), nil)
io.open = orig_io_open

-- macOS arm64 -> community edition
RUNTIME.osType = "darwin"; RUNTIME.archType = "arm64"
assert_eq("darwin/arm64 stable", mongo_utils.find_matching_version("8.3.2", darwin_versions), "macos-arm64-8.3.2")

-- macOS amd64 -> community edition
RUNTIME.osType = "darwin"; RUNTIME.archType = "amd64"
assert_eq("darwin/amd64 stable", mongo_utils.find_matching_version("8.3.2", darwin_versions), "macos-x86_64-8.3.2")

-- macOS arm64 pre-release
RUNTIME.osType = "darwin"; RUNTIME.archType = "arm64"
assert_eq("darwin/arm64 rc5", mongo_utils.find_matching_version("8.3.0-rc5", darwin_versions), "macos-arm64-8.3.0-rc5")

-- Windows amd64
RUNTIME.osType = "windows"; RUNTIME.archType = "amd64"
assert_eq("windows/amd64 stable", mongo_utils.find_matching_version("8.3.2", windows_versions), "windows-x86_64-8.3.2")

-- Windows: version not in list -> nil
RUNTIME.osType = "windows"; RUNTIME.archType = "amd64"
assert_eq("windows: version not found -> nil", mongo_utils.find_matching_version("0.0.0", windows_versions), nil)

-- ── summary ──────────────────────────────────────────────────────────────────

print(string.format("\n%d passed, %d failed", pass_count, fail_count))
if fail_count > 0 then
    os.exit(1)
end
