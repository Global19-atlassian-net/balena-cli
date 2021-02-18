# Docker Images for balena CLI

Docker images with balena CLI and docker-in-docker.

## Building (required)

Follow these steps to build your own Docker image with
the CLI and dependencies pre-installed. These steps have been tested
on x86_64 workstations, building images for other platforms like ARM.

```bash
# provide the architecture where you will be running the image
# (see Available Architectures below)
export BALENA_ARCH="amd64"

# optionally enable QEMU binfmt if building for other architectures (eg. armv7hf)
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# the recommended distro is debian, but alpine Dockerfiles are also available
export BALENA_DISTRO="debian"

# provde a CLI version from https://github.com/balena-io/balena-cli/releases
export BALENA_CLI_VERSION="12.40.0"

# build and tag an image with docker
docker build ${BALENA_DISTRO} \
    --build-arg BALENA_ARCH \
    --build-arg BALENA_CLI_VERSION \
    --tag "balenacli-${BALENA_DISTRO}-${BALENA_ARCH}:${BALENA_CLI_VERSION}" \
    --tag "balenacli-${BALENA_DISTRO}-${BALENA_ARCH}:latest" \
    --pull
```

## Available Architectures

- `rpi`
- `armv7hf`
- `aarch64` (debian only)
- `amd64`
- `i386`

## Basic Usage

Here's a small example of running a single, detached container
in the background and using `docker exec` to run balena CLI commands.

```
$ docker run --detach --privileged --network host --name cli --rm -it balenacli-debian-amd64 /bin/bash

$ docker exec -it cli balena version -a
balena-cli version "12.38.1"
Node.js version "12.19.1"

$ docker exec -it cli balena login --token abc...

$ docker exec -it cli balena whoami
== ACCOUNT INFORMATION
USERNAME: ...
EMAIL:    ...
URL:      balena-cloud.com

$ docker exec -it cli balena apps
ID      APP NAME         SLUG                            DEVICE TYPE     ONLINE DEVICES DEVICE COUNT
1491721 test-nuc         gh_paulo_castro/test-nuc        intel-nuc       0              1
...

$ docker exec -it cli balena app test-nuc
== test-nuc
ID:          149...
DEVICE TYPE: intel-nuc
SLUG:        gh_.../test-nuc
COMMIT:      ce9...
```

## Advanced Usage

The following are examples of running the docker image in various
modes in order to allow only the required functionality, and not
elevate permissions unless required.

### scan

- <https://www.balena.io/docs/reference/balena-cli/#scan>

```bash
# balena scan requires the host network and NET_ADMIN
docker run --rm -it --cap-add NET_ADMIN --network host \
    balenacli-debian-amd64 scan
```

### ssh

- <https://www.balena.io/docs/reference/balena-cli/#login>
- <https://www.balena.io/docs/reference/balena-cli/#key-add-name-path>
- <https://www.balena.io/docs/reference/balena-cli/#ssh-applicationordevice-service>

```bash
# balena ssh requires a private ssh key
docker run --rm -it -e SSH_PRIVATE_KEY="$(</path/to/priv/key)" \
    balenacli-debian-amd64 /bin/bash

> balena login --credentials --email johndoe@gmail.com --password secret
> balena ssh f49cefd my-service
> exit

# OR use your host ssh agent socket with a key already loaded
docker run --rm -it -e SSH_AUTH_SOCK -v "$(dirname "${SSH_AUTH_SOCK}")" \
    balenacli-debian-amd64 /bin/bash

> balena login --credentials --email johndoe@gmail.com --password secret
> balena ssh f49cefd my-service
> exit
```

### build | deploy

- <https://www.balena.io/docs/reference/balena-cli/#build-source>
- <https://www.balena.io/docs/reference/balena-cli/#deploy-appname-image>

```bash
# docker-in-docker requires SYS_ADMIN
# note that we are mounting your app source into the container
# with -v $PWD:$PWD -w $PWD for convenience
docker run --rm -it --cap-add SYS_ADMIN \
    -v $PWD:$PWD -w $PWD \
    balenacli-debian-amd64 /bin/bash

> balena login --credentials --email johndoe@gmail.com --password secret
> balena build --application myApp
> balena deploy myApp
> exit

# OR use your host docker socket
# note that we are mounting your app source into the container
# with -v $PWD:$PWD -w $PWD for convenience
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock \
    -v $PWD:$PWD -w $PWD \
    balenacli-debian-amd64 /bin/bash

> balena login --credentials --email johndoe@gmail.com --password secret
> balena build --application myApp
> balena deploy myApp
> exit
```

### preload

- <https://www.balena.io/docs/reference/balena-cli/#os-download-type>
- <https://www.balena.io/docs/reference/balena-cli/#os-configure-image>
- <https://www.balena.io/docs/reference/balena-cli/#preload-image>

```bash
# docker-in-docker requires SYS_ADMIN
docker run --rm -it --cap-add SYS_ADMIN \
    balenacli-debian-amd64 /bin/bash

> balena login --credentials --email johndoe@gmail.com --password secret
> balena os download raspberrypi3 -o raspberry-pi.img
> balena os configure raspberry-pi.img --app MyApp
> balena preload raspberry-pi.img --app MyApp --commit current
> exit

# OR use your host docker socket
# note the .img path must be the same on the host as in the container
# therefore we are using -v $PWD:$PWD -w $PWD so the paths align
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock \
    -v $PWD:$PWD -w $PWD \
    balenacli-debian-amd64 /bin/bash

> balena login --credentials --email johndoe@gmail.com --password secret
> balena os download raspberrypi3 -o raspberry-pi.img
> balena os configure raspberry-pi.img --app MyApp
> balena preload raspberry-pi.img --app MyApp --commit current
> exit
```
