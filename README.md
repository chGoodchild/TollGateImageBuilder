# Build Tollgate Device Firmware

This script uses OpenWRT's image-builder to create a base firmware for supported devices without needing to recompile all packages. 


To build:

```bash
# build-firmware <model>
# for example
./build-firmware gl-mt300n-v2
```

installing:
```bash
# scp -O /tmp/openwrt-build/openwrt-imagebuilder-23.05.3-<platform>-<type>.Linux-x86_64/bin/targets/<platform>/<type>/openwrt-23.05.3-<target-device>-<profile>-squashfs-sysupgrade.bin root@<dest>:/tmp

# for example 
scp -O /tmp/openwrt-build/openwrt-imagebuilder-23.05.3-ramips-mt76x8.Linux-x86_64/bin/targets/ramips/mt76x8/openwrt-23.05.3-ramips-mt76x8-glinet_gl-mt300n-v2-squashfs-sysupgrade.bin root@<dest>:/tmp

ssh <device>
sysupgrade -v /tmp/firmware-file
```

Next steps would be to cross-compile any binaries outside of the OpenWRT ecosystem and have them pulled into the base image build process.