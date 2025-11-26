#####################
# SERVER FUNCTIONS
#####################

: "${USER_NAME:=jesse}"
: "${REMOTE_SERVER:=rockybox}"

serva() {
  local cmd=$1
  local src=$2
  local dest=$3

  case $cmd in
    pull)
      rsync -avz "$USER_NAME@$REMOTE_SERVER:$src" "$dest"
      ;;
    push)
      rsync -avz "$src" "$USER_NAME@$REMOTE_SERVER:$dest"
      ;;
    *)
      echo "Usage: remote-server {pull|push} <source> <destination>"
      ;;
  esac
}
