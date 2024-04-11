# vfox-mongo plugin

mongo [vfox](https://github.com/version-fox) plugin. Use the vfox to manage multiple mongo server versions in Linux/Darwin/Windows. vofx-mongo plugin would download and install the mongo server version from : https://www.mongodb.com/download-center/community/releases/archive.

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
