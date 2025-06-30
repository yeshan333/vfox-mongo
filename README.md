# vfox-mongo plugin

<div align="center">

[![E2E tests](https://github.com/yeshan333/vfox-mongo/actions/workflows/e2e_test.yaml/badge.svg)](https://github.com/yeshan333/vfox-mongo/actions/workflows/e2e_test.yaml)

</div>

mongo [vfox](https://github.com/version-fox) plugin. Use the vfox to manage multiple mongo server versions in Linux/Darwin/Windows. vofx-mongo plugin would download and install the mongo server version from : [https://www.mongodb.com/download-center/community/releases/archive].

## Usage

```shell
# install plugin
vfox add --source https://github.com/yeshan333/vfox-mongo/archive/refs/heads/main.zip mongo

# install an available version
vofx search mongo
# eg: install in ubuntu 20.04
vfox install mongo@x86_64-ubuntu2004-8.0.0-rc0
vfox use -p mongo@x86_64-ubuntu2004-8.0.0-rc0
```

You can also find an available version from the [Linux & Darwin & Windows version list](https://fastly.jsdelivr.net/gh/yeshan333/vfox-mongo@main/assets/).

