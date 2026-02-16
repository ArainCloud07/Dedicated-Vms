#!/bin/bash

NETWORK="macvlan_pub"
IMAGE="darkkop/ubuntu-systemd:22.04"

pause() {
    echo ""
    read -p "Press Enter To Go To MENU..."
}

header() {
    clear
    echo "====================================="
    echo "        DOCKER VPS MANAGER"
    echo "====================================="
}

list_vps() {
    header
    echo "Running VPS Containers:"
    echo ""

    docker ps --filter "ancestor=$IMAGE" \
    --format "table {{.Names}}\t{{.Status}}"

    COUNT=$(docker ps --filter "ancestor=$IMAGE" -q | wc -l)
    echo ""
    echo "Total VPS Running: $COUNT"

    pause
}

create_vps() {
    header
    echo "CREATE VPS"
    echo ""

    read -p "VPS name: " NAME
    read -p "IP address: " IP
    read -s -p "Root password: " PASS
    echo ""

    docker run -d \
      --name $NAME \
      --hostname $NAME \
      --privileged \
      --cgroupns=host \
      -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
      $IMAGE /sbin/init

    docker network connect --ip $IP $NETWORK $NAME
    docker exec $NAME bash -c "echo root:$PASS | chpasswd"

    echo ""
    echo "===== VPS CREATED ====="
    echo "IP: $IP"
    echo "Username: root"
    echo "Password: $PASS"
    echo "ssh root@$IP"

    pause
}

delete_vps() {
    header
    read -p "VPS name: " NAME
    docker rm -f $NAME
    pause
}

start_vps() {
    header
    read -p "VPS name: " NAME
    docker start $NAME
    pause
}

stop_vps() {
    header
    read -p "VPS name: " NAME
    docker stop $NAME
    pause
}

change_ip() {
    header
    read -p "VPS name: " NAME
    read -p "New IP: " NEWIP

    docker network disconnect $NETWORK $NAME
    docker network connect --ip $NEWIP $NETWORK $NAME

    pause
}

menu() {
    while true; do
        header
        echo "1. Create VPS"
        echo "2. Delete VPS"
        echo "3. Start VPS"
        echo "4. Stop VPS"
        echo "5. Change IP"
        echo "6. List VPS"
        echo "7. Exit"
        echo ""

        read -p "Select: " CHOICE

        case $CHOICE in
            1) create_vps ;;
            2) delete_vps ;;
            3) start_vps ;;
            4) stop_vps ;;
            5) change_ip ;;
            6) list_vps ;;
            7) clear; exit ;;
        esac
    done
}

menu
