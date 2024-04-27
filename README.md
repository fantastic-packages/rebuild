# rebuild

Something is wrong with ImageBuilder. You need to execute the following code to fix it.

``` shell
VERSION=<openwrt-imagebuilder-version> # e.g. 23.05.3
TARGET=<openwrt-imagebuilder-target> # e.g. x86
SUBTARGET=<openwrt-imagebuilder-subtarget> # e.g. 64
sed -i "/src\/gz openwrt_core /{s|downloads.openwrt.org/releases/$VERSION|github.com/fantastic-packages/rebuild/raw/$VERSION-$TARGET-$SUBTARGET|}" repositories.conf
```

Something is wrong with system image. You need to execute the following code to fix it.

``` shell
VERSION=<openwrt-imagebuilder-version> # e.g. 23.05.3
TARGET=<openwrt-imagebuilder-target> # e.g. x86
SUBTARGET=<openwrt-imagebuilder-subtarget> # e.g. 64
sed -i "/src\/gz openwrt_core /{s|downloads.openwrt.org/releases/$VERSION|github.com/fantastic-packages/rebuild/raw/$VERSION-$TARGET-$SUBTARGET|}" /etc/opkg/distfeeds.conf
```
