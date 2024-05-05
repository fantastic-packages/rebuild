# rebuild

How to clone this project

```shell
umask 022
git clone --branch conf --single-branch --no-tags --recurse-submodules https://github.com/fantastic-packages/rebuild.git fantastic_rebuild
```

Something is wrong with ImageBuilder. You need to execute the following code to fix it.

``` shell
REPO=fantastic-packages/rebuild
VERSION=<openwrt-imagebuilder-version> # e.g. 23.05.3
TARGET=<openwrt-imagebuilder-target> # e.g. x86
SUBTARGET=<openwrt-imagebuilder-subtarget> # e.g. 64
TARGETBRANCH=$VERSION-$TARGET-$SUBTARGET
sed -i "/src\/gz rebuild_core /{ \
	s|downloads.openwrt.org/releases/$VERSION|github.com/$REPO/raw/$TARGETBRANCH| \
}" repositories.conf
```
OR
<details><summary>Expand/Collapse</summary>

``` shell
REPO=fantastic-packages/rebuild
VERSION=<openwrt-imagebuilder-version> # e.g. 23.05.3
TARGET=<openwrt-imagebuilder-target> # e.g. x86
SUBTARGET=<openwrt-imagebuilder-subtarget> # e.g. 64
TARGETBRANCH=$VERSION-$TARGET-$SUBTARGET
sed -i "/src\/gz rebuild_core /{ \
	s|downloads.openwrt.org/releases/$VERSION|fastly.jsdelivr.net/gh/$REPO@$TARGETBRANCH| \
}" repositories.conf
```
</details>

Something is wrong with system image. You need to execute the following code to fix it.

``` shell
REPO=fantastic-packages/rebuild
VERSION=<openwrt-imagebuilder-version> # e.g. 23.05.3
TARGET=<openwrt-imagebuilder-target> # e.g. x86
SUBTARGET=<openwrt-imagebuilder-subtarget> # e.g. 64
TARGETBRANCH=$VERSION-$TARGET-$SUBTARGET
sed -i "/src\/gz rebuild_core /{ \
	s|downloads.openwrt.org/releases/$VERSION|github.com/$REPO/raw/$TARGETBRANCH| \
}" /etc/opkg/distfeeds.conf
```
OR
<details><summary>Expand/Collapse</summary>

``` shell
REPO=fantastic-packages/rebuild
VERSION=<openwrt-imagebuilder-version> # e.g. 23.05.3
TARGET=<openwrt-imagebuilder-target> # e.g. x86
SUBTARGET=<openwrt-imagebuilder-subtarget> # e.g. 64
TARGETBRANCH=$VERSION-$TARGET-$SUBTARGET
sed -i "/src\/gz rebuild_core /{ \
	s|downloads.openwrt.org/releases/$VERSION|fastly.jsdelivr.net/gh/$REPO@$TARGETBRANCH| \
}" /etc/opkg/distfeeds.conf
```
</details>
