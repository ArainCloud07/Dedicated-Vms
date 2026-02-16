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
    echo "     DEDICATED IPv4 VPS MANAGER"
    echo "====================================="
}

show_vps() {
    docker ps -a --filter "ancestor=$IMAGE" \
    --format " - {{.Names}} ({{.Status}})"
}

find_free_ips() {
    header
    echo "FIND FREE IPs (SSH port closed)"
    echo ""

    read -p "Subnet (example 138.252.100): " SUBNET
    read -p "Start range: " START
    read -p "End range: " END

    echo ""
    echo "Scanning..."
    echo ""

    for ((i=$START;i<=$END;i++)); do
        IP="$SUBNET.$i"
        timeout 1 bash -c "</dev/tcp/$IP/22" &>/dev/null

        if [ $? -ne 0 ]; then
            echo "FREE: $IP"
        fi
    done

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
    echo "DELETE VPS"
    echo ""
    show_vps
    echo ""
    read -p "Enter VPS name: " NAME
    docker rm -f $NAME
    pause
}

start_vps() {
    header
    echo "START VPS"
    echo ""
    show_vps
    echo ""
    read -p "Enter VPS name: " NAME
    docker start $NAME
    pause
}

stop_vps() {
    header
    echo "STOP VPS"
    echo ""
    show_vps
    echo ""
    read -p "Enter VPS name: " NAME
    docker stop $NAME
    pause
}

change_ip() {
    header
    echo "CHANGE VPS IP"
    echo ""
    show_vps
    echo ""
    read -p "Enter VPS name: " NAME
    read -p "New IP: " NEWIP

    docker network disconnect $NETWORK $NAME
    docker network connect --ip $NEWIP $NETWORK $NAME

    pause
}

list_vps() {
    header
    echo "VPS LIST"
    echo ""
    show_vps
    echo ""
    COUNT=$(docker ps --filter "ancestor=$IMAGE" -q | wc -l)
    echo "Total VPS Running: $COUNT"
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
        echo "7. Find Free IPs"
        echo "8. Exit"
        echo ""

        read -p "Select: " CHOICE

        case $CHOICE in
            1) create_vps ;;
            2) delete_vps ;;
            3) start_vps ;;
            4) stop_vps ;;
            5) change_ip ;;
            6) list_vps ;;
            7) find_free_ips ;;
            8) clear; exit ;;
        esac
    done
}

menu
