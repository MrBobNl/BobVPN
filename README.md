# BobVPN
Custom implementation of OpenVPN (usermanagement, server and multi-arch)

Work in proces! It works but stil needs adjustment hardcoded!
If you are using Visual Studio Code, install the extension: Todo Tree. you will get a tree on your left bar with what you need to fill in.

# Introduction
Your looking for an managed OpenVPN with an usermanagement in there that works multi-arch? Stop looking! :D

This project is to build an image for your container registry. Everything is based on ubuntu 22.04 LTS, at the moment it is build for linux/amd64,linux/arm64,linux/riscv64,linux/ppc64le,linux/s390x,linux/arm/v7. In other words, for almost every system like 32-bit (arm/v7) and 64-bit (arm64) on raspberry and windows computers (amd64).

## Getting Started
### prerequiste
docker (Windows wsl, Ubuntu, Debain)
>  Tested on:
>  - Windows 10 wsl(2)
>  - Windows 11 wsl(2)
>  - Ubuntu(18.04,20.04,22.04)

### Installation process
1. Configure docker for the multiarch build
> - export DOCKER_CLI_EXPERIMENTAL=enabled
> - docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
> - docker buildx create --use
2. Some configuration on the device itself
> Allow ip_forward
>> nano /etc/sysctl.conf
>> """
>> allow net.ipv4.ip_forward = 1
>> """