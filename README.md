# rebuild

## About branches

`master`: Stable branch. No `push --force`. Compatible with the minimum version of OpenWrt that is not EOL.\
`$Verioson`: Often `push --force`. Compatible with specific OpenWrt versions. For example, `24.10`.\
`snapshot`: Often `push --force`. Not often used, only used to complete compatibility work before a breaking changes releases. For example, package management switches from `opkg` to `apk`.

## How to clone this project

```shell
umask 022
git clone --branch master --single-branch --no-tags --recurse-submodules https://github.com/fantastic-packages/rebuild.git fantastic_rebuild
```
