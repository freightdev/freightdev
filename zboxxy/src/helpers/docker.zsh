#!  ╔═══════════════════════════════════════════╗
#?    Docker Helpers - Environment Source (Zsh)  
#!  ╚═══════════════════════════════════════════╝

# Docker cleanup: prune unused resources
docker-clean() {
    if ! command -v docker &>/dev/null; then
        echo "docker command not found"
        return 1
    fi

    echo "=== Docker Cleanup ==="
    docker container prune -f
    docker image prune -f
    docker volume prune -f
    docker network prune -f
    echo "Docker cleanup complete!"
    echo "Timestamp: $(date '+%d-%m-%Y %H:%M:%S')"
}

# Docker nuke: remove all containers, images, volumes, networks
docker-nuke() {
    if ! command -v docker &>/dev/null; then
        echo "docker command not found"
        return 1
    fi

    echo "=== WARNING: This will remove ALL Docker containers, images, volumes, and networks! ==="
    read "?Are you sure? [y/N]: " response
    if [[ $response =~ ^[Yy]$ ]]; then
        local cids iids vids nids

        cids=$(docker ps -aq)
        iids=$(docker images -q)
        vids=$(docker volume ls -q)
        nids=$(docker network ls -q)

        [[ -n $cids ]] && docker stop $cids 2>/dev/null && docker rm $cids 2>/dev/null
        [[ -n $iids ]] && docker rmi $iids 2>/dev/null
        [[ -n $vids ]] && docker volume rm $vids 2>/dev/null
        [[ -n $nids ]] && docker network rm $nids 2>/dev/null

        echo "Docker nuked!"
        echo "Timestamp: $(date '+%d-%m-%Y %H:%M:%S')"
    else
        echo "Operation canceled."
    fi
}

