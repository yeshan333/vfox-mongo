# vfox-mongo plugin

<div align="center">

[![E2E tests](https://github.com/yeshan333/vfox-mongo/actions/workflows/e2e_test.yaml/badge.svg)](https://github.com/yeshan333/vfox-mongo/actions/workflows/e2e_test.yaml)

</div>

mongo [vfox](https://github.com/version-fox) plugin. Use the vfox to manage multiple mongo server versions in Linux/Darwin/Windows. vfox-mongo plugin would download and install the mongo server version from : [https://www.mongodb.com/download-center/community/releases/archive].

**mongosh auto-install**: Since MongoDB 6.0+, the legacy `mongo` shell is no longer bundled in the server tarball. This plugin automatically installs the latest [mongosh](https://github.com/mongodb-js/mongosh) alongside the server. If the mongosh download fails (e.g., network issues), a warning is printed but the MongoDB server installation still succeeds.

To install a specific mongosh version, set the `MONGOSH_VERSION` environment variable:

```shell
MONGOSH_VERSION=2.8.3 vfox install mongo@8.0.6
```

## Usage

### Install with vfox

```shell
# install plugin
vfox add --source https://github.com/yeshan333/vfox-mongo/archive/refs/heads/main.zip mongo

# search available versions
vfox search mongo

# install a specific version (platform is auto-detected)
vfox install mongo@8.0.6

# activate
vfox use -g mongo@8.0.6
```

### Install with mise

The vfox-mongo plugin can also be used through [mise](https://mise.jdx.dev/), which supports vfox plugins.

```shell
# install the plugin
mise plugin install mongo https://github.com/yeshan333/vfox-mongo/archive/refs/heads/main.zip

# search available versions
mise ls-remote mongo

# install and activate
mise use -g mongo@8.0.6

# run mongod
mongod --help
```

You can also find an available version from the [Linux & Darwin & Windows version list](https://fastly.jsdelivr.net/gh/yeshan333/vfox-mongo@main/assets/).

