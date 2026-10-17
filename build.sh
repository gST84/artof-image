#!/bin/bash -e
#
# Builds the ARTOF Raspberry Pi image (Pi 4 and Pi 5, 64-bit) with pi-gen.
# The image ends up in deploy/.
#
# Environment variables:
#   ARTOF_CORE_SRC    artof-core source folder (default: ../artof-core)
#   ARTOF_SYSTEM_SRC  artof-system source folder, only used when Docker Hub has no
#                     ARM64 artof-system image (default: ../artof-system)
#   PI_GEN_REF        pi-gen branch or tag (default: arm64)

DIR="$(cd "$(dirname "$0")" && pwd)"
ARTOF_CORE_SRC="$(cd "${ARTOF_CORE_SRC:-$DIR/../artof-core}" && pwd)"
ARTOF_SYSTEM_SRC="${ARTOF_SYSTEM_SRC:-$DIR/../artof-system}"
PI_GEN_REF="${PI_GEN_REF:-arm64}"
PLATFORM=linux/arm64

WORK="$DIR/work"
PI_GEN="$WORK/pi-gen"
STAGE="$PI_GEN/stage-artof"
IMAGES="$STAGE/02-artof-services/files/images"

# Docker images started by artof-core (redis.init.json addons) and install.sh (Redis)
DOCKER_IMAGES=(
    redis/redis-stack-server:latest
    axelwillekens/artof-system:latest
    nodered/node-red:latest
)

echo "Fetching pi-gen ($PI_GEN_REF)"
rm -rf "$PI_GEN"
mkdir -p "$WORK"
git clone --quiet --depth 1 --branch "$PI_GEN_REF" https://github.com/RPi-Distro/pi-gen.git "$PI_GEN"
# Only export the ARTOF image, not the plain Lite image of stage2
rm -f "$PI_GEN/stage2/EXPORT_IMAGE"

echo "Adding the ARTOF stage"
cp -a "$DIR/stage-artof" "$STAGE"
cp "$DIR/config" "$PI_GEN/config"

echo "Copying artof-core from $ARTOF_CORE_SRC"
mkdir -p "$STAGE/01-artof-core/files/artof-core"
rsync -a --exclude .git --exclude 'build/' --exclude .vscode \
    "$ARTOF_CORE_SRC/" "$STAGE/01-artof-core/files/artof-core/"

echo "Saving the Docker images ($PLATFORM)"
mkdir -p "$IMAGES"
for image in "${DOCKER_IMAGES[@]}"; do
    # Docker may pull an image of another architecture without an error, so check it
    if ! docker pull --platform "$PLATFORM" "$image" ||
        [ "$(docker image inspect --format '{{.Os}}/{{.Architecture}}' "$image")" != "$PLATFORM" ]; then
        if [ "$image" = "axelwillekens/artof-system:latest" ] && [ -d "$ARTOF_SYSTEM_SRC" ]; then
            echo "No $PLATFORM image of $image on Docker Hub, building it from $ARTOF_SYSTEM_SRC"
            docker buildx build --platform "$PLATFORM" -t "$image" --load "$ARTOF_SYSTEM_SRC"
        else
            echo "Error: no $PLATFORM image of $image" >&2
            exit 1
        fi
    fi
    echo "$image: $(docker image inspect --format '{{.Os}}/{{.Architecture}}' "$image")"
    file="$IMAGES/$(echo "$image" | tr '/:' '__').tar"
    # --platform is needed when the host is not ARM64 and Docker uses the containerd image store
    docker save --platform "$PLATFORM" -o "$file" "$image" 2>/dev/null || docker save -o "$file" "$image"
done

echo "Building the image with pi-gen"
cd "$PI_GEN"
PRESERVE_CONTAINER=0 ./build-docker.sh

mkdir -p "$DIR/deploy"
cp -a "$PI_GEN"/deploy/* "$DIR/deploy/"
echo "Done, image in $DIR/deploy"
ls -lh "$DIR/deploy"
