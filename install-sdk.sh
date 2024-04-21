#!/bin/bash
#
selfname="$(basename $0 | sed -E 's|\.[^\.]+$||')"
confinfo="${selfname/install-sdk_/}"
version=$(echo "$confinfo" | cut -f1 -d'-')

# .config
CONFIG_AUTOREMOVE=$(sed -n '/^CONFIG_AUTOREMOVE=/{s|^.*=||p}' .config)
CONFIG_VERSION_REPO=$(sed -n '/^CONFIG_VERSION_REPO=/{s|^.*=||p}' .config)
CONFIG_arm=$(sed -n '/^CONFIG_arm=/{s|^.*=||p}' .config)

# rules.mk
VERSION="$version"
ARCH=`eval "$(sed -n '/^CONFIG_ARCH=/{s|^.*=||p}' .config)"`
	[ "$ARCH" = "i486" -o "$ARCH" = "i586" -o "$ARCH" = "i686" ] && ARCH=i386
ARCH_SUFFIX=`eval "$(sed -n '/^CONFIG_CPU_TYPE=/{s|^.*=|echo |p}' .config)"`
	[ -z "$ARCH_SUFFIX" ] && ARCH_SUFFIX=_${ARCH_SUFFIX}
	[ -n "$CONFIG_MIPS64_ABI" -a "$CONFIG_MIPS64_ABI_O32" = "y" ] && ARCH_SUFFIX=${ARCH_SUFFIX}_$(eval "$(sed -n '/^CONFIG_MIPS64_ABI=/{s|^.*=|echo |p}' .config)")
BOARD=`eval "$(sed -n '/^CONFIG_TARGET_BOARD=/{s|^.*=|echo |p}' .config)"`
SUBTARGET=`eval "$(sed -n '/^CONFIG_TARGET_SUBTARGET=/{s|^.*=|echo |p}' .config)"`
TARGET_SUFFIX=`eval "$(sed -n '/^CONFIG_TARGET_SUFFIX=/{s|^.*=|echo |p}' .config)"`
BUILD_SUFFIX=`eval "$(sed -n '/^CONFIG_BUILD_SUFFIX=/{s|^.*=|echo |p}' .config)"`
NPROC=$(sysctl -n hw.ncpu 2>/dev/null || nproc)
#
TOPDIR="$(cd $(dirname "$0"); pwd)"
BUILD_DIR_BASE="$TOPDIR/build_dir"
STAGING_DIR_BASE="$TOPDIR/staging_dir"
#
GCCV=`eval "$(sed -n '/^CONFIG_GCC_VERSION=/{s|^.*=|echo |p}' .config)"`
LIBC=`eval "$(sed -n '/^CONFIG_LIBC=/{s|^.*=|echo |p}' .config)"`
DIR_SUFFIX=_${LIBC}$([ "$CONFIG_arm" = "y" ] && echo _eabi)
TOOLCHAIN_DIR_NAME=toolchain-${ARCH}${ARCH_SUFFIX}_gcc-${GCCV}${DIR_SUFFIX}
#
BUILD_DIR_TOOLCHAIN="$BUILD_DIR_BASE/$TOOLCHAIN_DIR_NAME"
TOOLCHAIN_DIR="$STAGING_DIR_BASE/$TOOLCHAIN_DIR_NAME"
#
BUILD_DIR_HOST="$BUILD_DIR_BASE/host"
STAGING_DIR_HOST="$STAGING_DIR_BASE/host"
#
confvar() { echo $(for v in $1; do echo "$v=${!v}"; done) | md5sum|awk '{print $1}'; }

# depends.mk
DEP_FINDPARAMS='-x "*/.svn*" -x ".*" -x "*:*" -x "*\!*" -x "* *" -x "*\\\#*" -x "*/.*_check" -x "*/.*.swp" -x "*/.pkgdir*"'
#
find_md5() { eval 'find '"$1"' -type f '"${DEP_FINDPARAMS//-x/-and -not -path}"' -printf "%p%T@\n" | LC_ALL=C sort | md5sum|awk '"'{print \$1}'"; }
find_md5_reproducible() { eval 'find '"$1"' -type f '"${DEP_FINDPARAMS//-x/-and -not -path}"' -print0 | xargs -0 md5sum|awk '"'{print \$1}'"' | LC_ALL=C sort | md5sum|awk '"'{print \$1}'"; }


toolsbuild() {
	# host-build.mk
	local HOST_BUILD_PREFIX="$STAGING_DIR_HOST"
	local tools_srcdir="$(find ./tools/ -type f -name "Makefile" | sed 's|./tools/||;s|Makefile$||')"
	local tools_built="$(make tools/check | sed -n '/\btools\/.* check$/{s| check||;s|^.*\btools/||;p}')"
	rm -rf "$HOST_BUILD_PREFIX"
	mkdir -p "$HOST_BUILD_PREFIX"
	cp ./openwrt-sdk-${VERSION}-${BOARD}-${SUBTARGET}/root/staging_dir/host/* "$HOST_BUILD_PREFIX/"
	#
	local HOST_BUILD_DIR PKG_NAME PKG_VERSION PKG_SOURCE_DATE PKG_SOURCE_VERSION prepared_md5 prepared_confvar
	mkdir -p "$HOST_BUILD_PREFIX/stamp" 2>/dev/null
	for a in $tools_srcdir; do
		if echo "$tools_built" | grep -q "\b${a%/}\b"; then
			PKG_NAME=$(cat "./tools/${a}Makefile" | sed -n '/^PKG_NAME\b/{s|^[^=]*=\s*||;s|#.*||;p}')
			PKG_VERSION=$(cat "./tools/${a}Makefile" | sed -n '/^PKG_VERSION\b/{s|^[^=]*=\s*||;s|#.*||;p}')
			PKG_SOURCE_DATE=$(cat "./tools/${a}Makefile" | sed -n '/^PKG_SOURCE_DATE\b/{s|^[^=]*=\s*||;s|#.*||;p}')
			PKG_SOURCE_VERSION=$(cat "./tools/${a}Makefile" | sed -n '/^PKG_SOURCE_VERSION\b/{s|^[^=]*=\s*||;s|#.*||;p}')
			[ -z "$PKG_VERSION" ] && PKG_VERSION=$(echo "$PKG_SOURCE_DATE-${PKG_SOURCE_VERSION:0:8}" | sed 's|^-||;s|-$||')
			# build_dir/host
			if [ "$CONFIG_AUTOREMOVE" = "y" ]; then
				prepared_md5=$(find_md5_reproducible "$TOPDIR/tools/${a%/} $PKG_FILE_DEPENDS")
			else
				prepared_md5=$(find_md5 "$TOPDIR/tools/${a%/} $PKG_FILE_DEPENDS")
			fi
			prepared_confvar=$(confvar "CONFIG_AUTOREMOVE $HOST_PREPARED_DEPENDS")
			HOST_BUILD_DIR="$BUILD_DIR_HOST/$PKG_NAME${PKG_VERSION:+-$PKG_VERSION}"
			mkdir -p "$HOST_BUILD_DIR" 2>/dev/null
			touch "$HOST_BUILD_DIR/.prepared${prepared_md5}_${prepared_confvar}"
			touch "$HOST_BUILD_DIR/.configured"
			touch "$HOST_BUILD_DIR/.built"
			# staging_dir/host
			touch "$HOST_BUILD_PREFIX/stamp/.${PKG_NAME}_installed"
		fi
	done
	#
	make tools/compile -j$NPROC
}


# Ref: https://www.cnblogs.com/NueXini/p/16557669.html
# Ref: https://blog.csdn.net/Helloguoke/article/details/38066765
