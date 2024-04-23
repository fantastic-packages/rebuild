# rebuild

## How to use

``` shell
version=23.05.3
target=x86
subtarget=64
vermagic=e496746edd89318b9810e48e36a8bd9c

# Fetch the latest version
git clone https://github.com/openwrt/openwrt.git
cd openwrt
git remote update -p

# Download necessary tools
sha256sums="$(curl -L "https://downloads.openwrt.org/releases/${version}/targets/${target}/${subtarget}/sha256sums")"
curl -Lo config_${version}-${target}-${subtarget}.buildinfo "https://github.com/fantastic-packages/rebuild/tree/gh-pages/releases/${version}/targets/${target}/${subtarget}/config.buildinfo"
curl -Lo install-sdk_${version}.sh "https://github.com/fantastic-packages/rebuild/tree/master/install-sdk.sh"
curl -Lo openwrt-sdk-${version}-${target}-${subtarget}.tar.xz "https://downloads.openwrt.org/releases/${version}/targets/${target}/${subtarget}/$(echo "$sha256sums" | sed -n '/\bsdk\b/{s|^[[:xdigit:]]*\s*\*||;p}')"

# Checkout to specific version
git checkout -f v${version}

# Initialize build environment
make dirclean; rm -rf ./llvm-bpf*
cp -f config_${version}-${target}-${subtarget}.buildinfo .config
make menuconfig
./scripts/feeds update -a

# Install prebuilt host-tools
chmod +x install-sdk_*.sh
mkdir -p ./openwrt-sdk-${version}-${target}-${subtarget} 2>/dev/null
rm -rf ./openwrt-sdk-${version}-${target}-${subtarget}/*
ballpath="$(tar --no-recursion --exclude="*/*/*" -tJf ./openwrt-sdk-${version}-${target}-${subtarget}.tar.xz | grep staging_dir)"
tar -C ./openwrt-sdk-${version}-${target}-${subtarget}/ -xJf ./openwrt-sdk-${version}-${target}-${subtarget}.tar.xz "$ballpath"
mv ./openwrt-sdk-${version}-${target}-${subtarget}/* ./openwrt-sdk-${version}-${target}-${subtarget}/root
bash ./install-sdk_${version}.sh

# Build toolchain
make toolchain/compile -j$(nproc)
```

