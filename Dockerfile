# syntax=docker/dockerfile:1
#
# This Dockerfile creates a container image running OpenWrt in a QEMU VM.
# https://openwrt.org/docs/guide-user/virtualization/docker_openwrt_image
#
# To connect to the VM serial console, connect to the running container
# and execute this command:
#
#     socat -,raw,echo=0,icanon=0 unix-connect:/tmp/qemu-console.sock
#     socat -,echo=0,icanon=0 unix-connect:/tmp/qemu-monitor.sock
#
# To enable remote admin, set a password on the root account:
#
#     passwd
#
# and enable HTTP and SSH on the WAN interface exposed by QEMU to the
# container:
#
#     uci add firewall rule
#     uci set firewall.@rule[-1].name='Allow-Admin'
#     uci set firewall.@rule[-1].enabled='true'
#     uci set firewall.@rule[-1].src='wan'
#     uci set firewall.@rule[-1].proto='tcp'
#     uci set firewall.@rule[-1].dest_port='22 80'
#     uci set firewall.@rule[-1].target='ACCEPT'
#     service firewall restart

FROM docker.io/library/alpine:3.15

RUN apk add --no-cache \
        curl \
        qemu-system-arm \
        qemu-system-mips \
        qemu-img \
        socat

# Create directories with proper permissions
RUN mkdir -p /var/lib/qemu /var/lib/qemu/images && \
    chmod 777 /var/lib/qemu /var/lib/qemu/images

# Download MIPS kernel for QEMU
RUN curl -L https://downloads.openwrt.org/releases/23.05.3/targets/malta/be/openwrt-23.05.3-malta-be-vmlinux.elf -o /var/lib/qemu/vmlinux-malta && \
    chmod 644 /var/lib/qemu/vmlinux-malta

COPY start-qemu.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-qemu.sh

EXPOSE 30022
EXPOSE 30080
EXPOSE 30443
VOLUME /var/lib/qemu/images
WORKDIR /var/lib/qemu

# Remove USER directive to run as root
ENTRYPOINT ["/usr/local/bin/start-qemu.sh"]
