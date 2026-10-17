#!/bin/bash -e
# Runs once on the first boot: loads the Docker images shipped in the image
# (Redis, artof-system, node-red) so ARTOF works without internet, and starts Redis
# like artof-core's install.sh does.
images=/opt/artof/images

for image in "$images"/*.tar; do
    echo "Loading $image"
    docker load -i "$image"
done

if ! docker ps -a --format '{{.Names}}' | grep -q '^redis-stack-server$'; then
    docker run -d --restart always --name redis-stack-server -p 6379:6379 redis/redis-stack-server:latest
fi

# Free the space of the tar files, this also marks the first boot as done
rm -rf "$images"
