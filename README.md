# vfox-mongo plugin

<div align="center">

[![E2E tests](https://github.com/yeshan333/vfox-mongo/actions/workflows/e2e_test.yaml/badge.svg)](https://github.com/yeshan333/vfox-mongo/actions/workflows/e2e_test.yaml)

</div>

mongo [vfox](https://github.com/version-fox) plugin. Use the vfox to manage multiple mongo server versions in Linux/Darwin/Windows. vofx-mongo plugin would download and install the mongo server version from : [https://www.mongodb.com/download-center/community/releases/archive].

## Usage

```shell
# install plugin
vfox add --source https://github.com/yeshan333/vfox-mongo/archive/refs/heads/main.zip mongo

# search for available versions (auto-detects your system)
vfox search mongo

# install a version (using simplified version number)
vfox install mongo@8.0.6
vfox use -p mongo@8.0.6

# or install with full version string (still supported)
# eg: install in ubuntu 20.04
vfox install mongo@x86_64-ubuntu2004-8.0.0-rc0
vfox use -p mongo@x86_64-ubuntu2004-8.0.0-rc0
```

**Note**: The `vfox search mongo` command now automatically detects your system type (OS, architecture, and Linux distribution) and displays only compatible versions in a simplified format (e.g., `8.0.6` instead of `x86_64-ubuntu2004-8.0.6`). You can use either the simplified version number or the full version string when installing.

You can also find an available version from the [Linux & Darwin & Windows version list](https://fastly.jsdelivr.net/gh/yeshan333/vfox-mongo@main/assets/).

