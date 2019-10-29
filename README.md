# guppy

## Installing nvidia-docker2

Note: nvidia docker 2 MUST be installed first in order to perform the guppy basecalling.
https://github.com/nvidia/nvidia-docker/wiki/Installation-(version-2.0)

## Building Docker image

Builds docker image with the version of 1.0
```
cd guppy
docker build -t guppy_nvidia_docker:1.0 -f Dockerfile .
```

## Saving Docker Image

Once you built the container and you want to transport the image to a `.tar.gz` use this command. Saves all the images with the name guppy_nvidia_docker
```
docker save guppy_nvidia_docker | gzip > guppy_nvidia_docker.tar.gz
```

## Loading Docker Image

If you want to load an image to your local images from your `.tar.gz` file use this command
```
docker load < guppy_nvidia_docker.tar.gz
```