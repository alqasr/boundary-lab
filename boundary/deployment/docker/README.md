# Docker Deployment

This directory contains an example deployment of Boundary using docker-compose. In this example, Boundary is deployed using a locally build arm64 Docker image.

## Getting Started 

There is a helper script called `run` in this directory. You can use this script to deploy, login, and cleanup.

Start the docker-compose deployment:

```bash
./run all
```

To stop all containers and start from scratch:

```bash
./run cleanup
```
