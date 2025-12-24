senda() {
    for box in helpbox hostbox callbox; do
        rsync -avz -e "ssh" "$1" admin@"$box":"$3"
    done
}
