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
sed -Ei "/\/targets\/$TARGET\/$SUBTARGET\/packages/{ \
	s,downloads.openwrt.org/(releases/$VERSION|snapshots),raw.githubusercontent.com/$REPO/$TARGETBRANCH, \
}" repositories
sed -i "/\/targets\/$TARGET\/$SUBTARGET\/kmods/d" repositories
```
OR
<details><summary>Expand/Collapse</summary>

``` shell
REPO=fantastic-packages/rebuild
VERSION=<openwrt-imagebuilder-version> # e.g. 23.05.3
TARGET=<openwrt-imagebuilder-target> # e.g. x86
SUBTARGET=<openwrt-imagebuilder-subtarget> # e.g. 64
TARGETBRANCH=$VERSION-$TARGET-$SUBTARGET
sed -Ei "/\/targets\/$TARGET\/$SUBTARGET\/packages/{ \
	s,downloads.openwrt.org/(releases/$VERSION|snapshots),fastly.jsdelivr.net/gh/$REPO@$TARGETBRANCH, \
}" repositories
sed -i "/\/targets\/$TARGET\/$SUBTARGET\/kmods/d" repositories
```
</details>

Something is wrong with system image. You need to execute the following code to fix it.

``` shell
REPO=fantastic-packages/rebuild
VERSION=<openwrt-imagebuilder-version> # e.g. 23.05.3
TARGET=<openwrt-imagebuilder-target> # e.g. x86
SUBTARGET=<openwrt-imagebuilder-subtarget> # e.g. 64
TARGETBRANCH=$VERSION-$TARGET-$SUBTARGET
sed -Ei "/\/targets\/$TARGET\/$SUBTARGET\/packages/{ \
	s,downloads.openwrt.org/(releases/$VERSION|snapshots),raw.githubusercontent.com/$REPO/$TARGETBRANCH, \
}" /etc/apk/repositories.d/distfeeds.list
sed -i "/\/targets\/$TARGET\/$SUBTARGET\/kmods/d" /etc/apk/repositories.d/distfeeds.list
```
OR
<details><summary>Expand/Collapse</summary>

``` shell
REPO=fantastic-packages/rebuild
VERSION=<openwrt-imagebuilder-version> # e.g. 23.05.3
TARGET=<openwrt-imagebuilder-target> # e.g. x86
SUBTARGET=<openwrt-imagebuilder-subtarget> # e.g. 64
TARGETBRANCH=$VERSION-$TARGET-$SUBTARGET
sed -Ei "/\/targets\/$TARGET\/$SUBTARGET\/packages/{ \
	s,downloads.openwrt.org/(releases/$VERSION|snapshots),fastly.jsdelivr.net/gh/$REPO@$TARGETBRANCH, \
}" /etc/apk/repositories.d/distfeeds.list
sed -i "/\/targets\/$TARGET\/$SUBTARGET\/kmods/d" /etc/apk/repositories.d/distfeeds.list
```
</details>
