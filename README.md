# docker-ssh-agent
This project provides a way to forward the local SSH Agent into any docker container.
It is mainly meant to be used for local development when you need to run all your
development tools (e.g. git) inside the docker container.

## Installation

### Installation on Windows

Clone this repo and then build the necessary image with:

```console
build.bat
```

Once it is built the docker container may be started and the agent forwarded,
do this by runnning:

```console
ssh-forward-local.bat
```

This will setup required containers and volume and ssh into the container.
The script will halt while the ssh connection is kept.
It will also display some instructions on how enable it in other projects.

### Installation on Mac/Linux

Not yet ready.

## Installation in docker containers

To enable the ssh agent in another container the volume that was used must
be mounted into a specified container, and an environment variable must be set.

This can either be done by appending the following to the `docker run` command:

```console
-v ssh-agent-forwarder-data:/docker-ssh -e "SSH_AUTH_SOCK=/docker-ssh/ssh-agent_socket"
```

or if you are using docker-compose, create a `docker-compose.override.yml` file and add:

```yml
version: "3.7"
services:
  <name-of-service>:
    environment:
      - "SSH_AUTH_SOCK=/docker-ssh/ssh-agent_socket"
    volumes:
      - ssh-agent:/docker-ssh

volumes:
  ssh-agent:
    external: true
    name: "ssh-agent-forwarder-data"
```

Then start `docker-compose` as normal, this extra file will be automatically loaded.

Note: The version at the top must match the version of the original docker-compose file.

## How this works

The tool creates a shared volume where the SSH socket file is created in a fixed location.
This volume is then reused in other container, mounted at the exact same location.
With the addition of the environment variable `SSH_AUTH_SOCK` the ssh command will then
use this socket file as long as the ssh connection that was started earlier is still alive.

If the ssh connection is broken a simple restart of the script will recreate the socket file,
the other containers does not have to be restarted.

## TODO

Linux/Mac support and better executables for starting everything.
