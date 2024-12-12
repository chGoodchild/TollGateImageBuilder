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
        qemu-system-x86_64 \
        qemu-img \
        socat \
        && \
    rm -f /usr/share/qemu/edk2-*

ENV IMAGE_URL="https://downloads.openwrt.org/releases/23.05.3/targets/x86/64/openwrt-23.05.3-x86-64-generic-ext4-d.img.gz"
ENV IMAGE_FILE="openwrt-23.05.3-x86-64-generic-ext4-combined.img.gz"
ENV IMAGE_SHA256="28cf53e6bd9bb68958aae7958e7950d967f02b46"

# Rest of the Dockerfile remains the same
WORKDIR /var/lib/qemu-image
RUN curl -L "${IMAGE_URL}" -o "${IMAGE_FILE}" && \
    sh -x -c '[ "$(sha256sum "${IMAGE_FILE}")" = "${IMAGE_SHA256}  ${IMAGE_FILE}" ]'

RUN echo -e '#!/bin/sh\n\
set -ex \n\
if [ ! -f /var/lib/qemu/image.qcow2 ]; then \n\
    gunzip --stdout "/var/lib/qemu-image/${IMAGE_FILE}" > /var/lib/qemu/image.raw || true \n\
    qemu-img convert -f raw -O qcow2 /var/lib/qemu/image.raw /var/lib/qemu/image.qcow2 \n\
    rm /var/lib/qemu/image.raw \n\
    qemu-img resize /var/lib/qemu/image.qcow2 1G \n\
fi \n\
exec /usr/bin/qemu-system-x86_64 \\\n\
    -nodefaults \\\n\
    -display none \\\n\
    -m 256M \\\n\
    -smp 2 \\\n\
    -nic "user,model=virtio,restrict=on,ipv6=off,net=192.168.1.0/24,host=192.168.1.2" \\\n\
    -nic "user,model=virtio,net=172.16.0.0/24,hostfwd=tcp::30022-:22,hostfwd=tcp::30080-:80,hostfwd=tcp::30443-:443" \\\n\
    -chardev socket,id=chr0,path=/tmp/qemu-console.sock,mux=on,logfile=/dev/stdout,signal=off,server=on,wait=off \\\n\
    -serial chardev:chr0 \\\n\
    -monitor unix:/tmp/qemu-monitor.sock,server,nowait \\\n\
    -drive file=/var/lib/qemu/image.qcow2,if=virtio \\\n\
\n' > /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 30022
EXPOSE 30080
EXPOSE 30443
VOLUME /var/lib/qemu
WORKDIR /tmp
USER 1001
CMD ["/usr/local/bin/entrypoint.sh"]
