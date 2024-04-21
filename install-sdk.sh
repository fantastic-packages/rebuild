#!/bin/bash
#
selfname="$(basename $0 | sed -E 's|\.[^\.]+$||')"
confinfo="${selfname/install-sdk_/}"
version=$(echo "$confinfo" | cut -f1 -d'-')

isEmpty() {
	[ -z "$1" ] && return
	echo "$1" | grep -q '^\s*$' && return
	return 1
}

# .config
CONFIG_AUTOREMOVE=`eval "$(sed -n '/^CONFIG_AUTOREMOVE=/{s|^.*=|echo |p}' .config)"`
CONFIG_arm=`eval "$(sed -n '/^CONFIG_arm=/{s|^.*=|echo |p}' .config)"`
CONFIG_MIPS64_ABI=`eval "$(sed -n '/^CONFIG_MIPS64_ABI=/{s|^.*=|echo |p}' .config)"`
CONFIG_MIPS64_ABI_O32=`eval "$(sed -n '/^CONFIG_MIPS64_ABI_O32=/{s|^.*=|echo |p}' .config)"`
#
CONFIG_BINUTILS_VERSION=`eval "$(sed -n '/^CONFIG_BINUTILS_VERSION=/{s|^.*=|echo |p}' .config)"`
CONFIG_GCC_VERSION=`eval "$(sed -n '/^CONFIG_GCC_VERSION=/{s|^.*=|echo |p}' .config)"`

# rules.mk
VERSION="$version"
ARCH=`eval "$(sed -n '/^CONFIG_ARCH=/{s|^.*=|echo |p}' .config)"`
	[ "$ARCH" = "i486" -o "$ARCH" = "i586" -o "$ARCH" = "i686" ] && ARCH=i386
ARCH_SUFFIX=`eval "$(sed -n '/^CONFIG_CPU_TYPE=/{s|^.*=|echo |p}' .config)"`
	isEmpty "$ARCH_SUFFIX" && ARCH_SUFFIX=
	[ -n "$ARCH_SUFFIX" ] && ARCH_SUFFIX=_${ARCH_SUFFIX}
	( ! isEmpty "$CONFIG_MIPS64_ABI" && [ "$CONFIG_MIPS64_ABI_O32" != "y" ] ) && ARCH_SUFFIX=${ARCH_SUFFIX}_${CONFIG_MIPS64_ABI}
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


#search_dotconfig() {
#	local tmp=`eval "$(sed -n "/^$1=/{s|^.*=|echo |p}" "$TOPDIR/.config")"`
#	echo "$tmp"
#}

track_missing_vars() {
	local rawdata="$1"
	local srcdir="$2"
	local args="$(echo "$rawdata" | tr '$' '\n' | sed -En 's|^.*\{([^\}]+)\}.*$|\1|p')"

	search_v() {
		local v="$(sed -n "/^\s*$1\b/{s|^[^=]*=\s*||;s|#.*||;s|(|\{|g;s|)|\}|g;p}" "$2")"
		if [ -n "$v" ]; then
			# contains variables?
			if echo "$v" | grep -q '\$' && ! (echo "$v" | grep -q "\b$1\b"); then
				eval "$1=\"\$(track_missing_vars \"\$v\" \"\$srcdir\")\""
			else
				eval "$1=\"$v\""
			fi
			return
		else
			return 1
		fi
	}

	pushd "$srcdir" >/dev/null
	local k v m
	for k in $args; do
		[ -n "${!k}" ] && continue
		eval "local $k"
		# search ./Makefile
		search_v "$k" ./Makefile && continue
		# search include ./*.mk from ./Makefile
		local includemk="$(sed -En '/^include\s+\.\/.+\.mk/{s|.+(\./.+\.mk).*|\1|p}' ./Makefile)"
		for m in $includemk; do
			# search ./*.mk
			search_v "$k" "$m" && continue
		done
	done
	popd >/dev/null
	eval "echo \"$rawdata\""
}

hostbuild() {
	local type="$1"
	local srcdir="$2"
	local built="$3"

	local _topsrc _src PKG_NAME PKG_VERSION PKG_SOURCE_DATE PKG_SOURCE_VERSION HOST_BUILD_DIR prepared_md5 prepared_confvar
	mkdir -p "$HOST_BUILD_PREFIX/stamp" 2>/dev/null
	for a in $srcdir; do
		if echo "$built" | grep -q "\b${a%/}\b"; then
			_topsrc="$TOPDIR/$type/${a%%/*}"
			_src="$TOPDIR/$type/${a%/}"
			PKG_NAME=$(cat "$_src/Makefile" "$_topsrc/"**.mk 2>/dev/null | sed -n '/^\s*PKG_NAME\b/{s|^[^=]*=\s*||;s|#.*||;p}')
			PKG_VERSION=$(cat "$_src/Makefile" "$_topsrc/"**.mk 2>/dev/null | sed -n '/^\s*PKG_VERSION\b/{s|^[^=]*=\s*||;s|#.*||;p}')
			PKG_SOURCE_DATE=$(cat "$_src/Makefile" "$_topsrc/"**.mk 2>/dev/null | sed -n '/^\s*PKG_SOURCE_DATE\b/{s|^[^=]*=\s*||;s|#.*||;p}')
			PKG_SOURCE_VERSION=$(cat "$_src/Makefile" "$_topsrc/"**.mk 2>/dev/null | sed -n '/^\s*PKG_SOURCE_VERSION\b/{s|^[^=]*=\s*||;s|#.*||;p}')
			HOST_BUILD_DIR="$(cat "$_src/Makefile" "$_topsrc/"**.mk 2>/dev/null | sed -n '/^\s*HOST_BUILD_DIR\b/{s|^[^=]*=\s*||;s|#.*||;s|(|\{|g;s|)|\}|g;p}')"
			#
			case "$PKG_NAME" in
				gcc) local GCC_VARIANT="$(track_missing_vars '${GCC_VARIANT}' "$_src")";;
				linux) continue;;
			esac
			#
			[ -z "$PKG_VERSION" ] && PKG_VERSION=$(echo "$PKG_SOURCE_DATE-${PKG_SOURCE_VERSION:0:8}" | sed 's|^-||;s|-$||')
			echo "$PKG_VERSION" | grep -q '\$' && {
			#echo "$PKG_VERSION" | grep -q '^\$(call qstrip,' && {
			#	PKG_VERSION=`eval echo "$(echo "$PKG_VERSION" | sed 's|\$(call qstrip,||;s|)$||;s|(|\{|g;s|)|\}|g')"`
			#} || {
				case "$PKG_NAME" in
					binutils) PKG_VERSION=$CONFIG_BINUTILS_VERSION;;
					gcc) PKG_VERSION=$(echo "$CONFIG_GCC_VERSION" | cut -f1 -d'+');;
				esac
				echo [$PKG_NAME-$PKG_VERSION]: Unique PKG_VERSION: $PKG_VERSION
			}
			#
			if [ -z "$HOST_BUILD_DIR" ]; then
				HOST_BUILD_DIR="$BUILD_DIR_HOST/$PKG_NAME${PKG_VERSION:+-$PKG_VERSION}"
			else
				case "$PKG_NAME" in
					gcc) [ "$GCC_VARIANT" != "minimal" ] && HOST_BUILD_DIR="$BUILD_DIR_HOST/$PKG_NAME${PKG_VERSION:+-$PKG_VERSION}-$GCC_VARIANT";;
					*) HOST_BUILD_DIR="$(track_missing_vars "$HOST_BUILD_DIR" "$_src")";;
				esac
				echo [$PKG_NAME${PKG_VERSION:+-$PKG_VERSION}]: Unique HOST_BUILD_DIR: $HOST_BUILD_DIR
			fi
			#
			if [ "$CONFIG_AUTOREMOVE" = "y" ]; then
				prepared_md5=$(find_md5_reproducible "$_src $PKG_FILE_DEPENDS")
			else
				prepared_md5=$(find_md5 "$_src $PKG_FILE_DEPENDS")
			fi
			prepared_confvar=$(confvar "CONFIG_AUTOREMOVE $HOST_PREPARED_DEPENDS")
			# build_dir/*
			mkdir -p "$HOST_BUILD_DIR" 2>/dev/null
			case "$type" in
				tools) touch "$HOST_BUILD_DIR/.prepared${prepared_md5}_${prepared_confvar}";;
				toolchain)
					case "${a%/}" in
						musl) touch "$HOST_BUILD_DIR/.prepared${prepared_md5}_${prepared_confvar}";;
						*) touch "$HOST_BUILD_DIR/.prepared";;
					esac
				;;
			esac
			touch "$HOST_BUILD_DIR/.configured"
			touch "$HOST_BUILD_DIR/.built"
			# staging_dir/*
			case "$PKG_NAME" in
				gcc)
					touch "$HOST_BUILD_PREFIX/stamp/.${PKG_NAME}_${GCC_VARIANT}_installed"
					unset GCC_VARIANT
				;;
				*) touch "$HOST_BUILD_PREFIX/stamp/.${PKG_NAME}_installed";;
			esac
		fi
	done
}

toolsbuild() {
	# host-build.mk
	local HOST_BUILD_PREFIX="$STAGING_DIR_HOST"
	local tools_srcdir="$(find ./tools/ -type f -name "Makefile" | sed 's|./tools/||;s|Makefile$||')"
	local tools_built="$(make tools/check | sed -n '/\btools\/.* check$/{s| check||;s|^.*\btools/||;p}')"
	rm -rf "$HOST_BUILD_PREFIX"
	rm -rf "$BUILD_DIR_HOST"
	mkdir -p "$HOST_BUILD_PREFIX"
	cp -r ./openwrt-sdk-${VERSION}-${BOARD}-${SUBTARGET}/root/staging_dir/host/* "$HOST_BUILD_PREFIX/"
	#
	hostbuild tools "$tools_srcdir" "$tools_built"
	#
	make tools/compile -j$NPROC
}

toolchainbuild() {
	# toolchain-build.mk
	local HOST_BUILD_PREFIX="$TOOLCHAIN_DIR"
	local BUILD_DIR_HOST="$BUILD_DIR_TOOLCHAIN"
	local toolchain_srcdir="$(find ./toolchain/ -type f -name "Makefile" | sed 's|./toolchain/||;s|Makefile$||')"
	local toolchain_built="$(make toolchain/check | sed -n '/\btoolchain\/.* check$/{s| check||;s|^.*\btoolchain/||;p}')"
	rm -rf "$HOST_BUILD_PREFIX"
	rm -rf "$BUILD_DIR_HOST"
	mkdir -p "$HOST_BUILD_PREFIX"
	cp -r ./openwrt-sdk-${VERSION}-${BOARD}-${SUBTARGET}/root/staging_dir/toolchain-*/* "$HOST_BUILD_PREFIX/"
	#
	hostbuild toolchain "$toolchain_srcdir" "$toolchain_built"
	#
	make toolchain/compile -j$NPROC
}


# Ref: https://www.cnblogs.com/NueXini/p/16557669.html
# Ref: https://blog.csdn.net/Helloguoke/article/details/38066765
