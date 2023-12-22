umask 0077

export PATH=/usr/bin:$PATH

XDG_RUNTIME_DIR=/var/docker/.docker/run/bus
export DBUS_SESSION_BUS_ADDRESS

XDG_RUNTIME_DIR=/var/docker/.docker/run
export XDG_RUNTIME_DIR

export DOCKER_HOST=unix:///var/docker/.docker/run/docker.sock
