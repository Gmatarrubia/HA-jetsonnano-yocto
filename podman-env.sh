#!/bin/bash

repoPath="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# Check if podman's image has previously been built
image_exits=$(podman images | grep -c yocto-env)
if [ "${image_exits}" -lt 1 ]
then
    echo "Not image yocto-env found. Let's building it!"
    podman build -t yocto-env https://github.com/Gmatarrubia/podman-yocto-build.git#scarthgap
fi

podman run \
    -it --rm \
    --privileged \
    --ipc=host \
    --network=host \
    --publish-all \
    --userns=keep-id \
    --name yocto-env \
    --hostname yocto-builder \
    --mount type=bind,source="${repoPath}",target=/yocto \
    --env SHELL="/bin/bash" \
    yocto-env:latest \
    "${@}"

