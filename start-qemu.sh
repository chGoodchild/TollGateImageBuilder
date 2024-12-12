#!/bin/sh

TARGET="$1"
IMAGE="$2"

# Convert sysupgrade image to qcow2 format
qemu-img convert -f raw -O qcow2 $IMAGE /var/lib/qemu/image.qcow2

case "$TARGET" in
    "gl-mt300n-v2"|"gl-e750")
        # MIPS architecture
        QEMU_CMD="qemu-system-mips"
        MACHINE="malta"
        CPU="24Kc"
        ;;
    "gl-ar300m")
        # MIPS architecture (Atheros)
        QEMU_CMD="qemu-system-mips"
        MACHINE="malta"
        CPU="24Kc"
        ;;
    "gl-mt3000"|"gl-mt6000")
        # ARM architecture (MediaTek)
        QEMU_CMD="qemu-system-arm"
        MACHINE="virt"
        CPU="cortex-a53"
        ;;
    *)
        echo "Unsupported target: $TARGET"
        exit 1
        ;;
esac

exec $QEMU_CMD \
    -M $MACHINE \
    -cpu $CPU \
    -nodefaults \
    -display none \
    -m 256M \
    -smp 2 \
    -nic "user,model=virtio,restrict=on,ipv6=off,net=192.168.1.0/24,host=192.168.1.2" \
    -nic "user,model=virtio,net=172.16.0.0/24,hostfwd=tcp::30022-:22,hostfwd=tcp::30080-:80,hostfwd=tcp::30443-:443" \
    -chardev socket,id=chr0,path=/tmp/qemu-console.sock,mux=on,logfile=/dev/stdout,signal=off,server=on,wait=off \
    -serial chardev:chr0 \
    -monitor unix:/tmp/qemu-monitor.sock,server,nowait \
    -drive file=/var/lib/qemu/image.qcow2,if=virtio,format=qcow2
