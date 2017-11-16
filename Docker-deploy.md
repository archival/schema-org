# Deploying a local test environment with Docker

This guide describes deploying a local Docker container which can run the
build.sh validation script, compile the Jekyll templates to HTML, and serve the
rendered HTML pages with Jekyll's simple web server.

**N.B. This Docker image is not intended for deployment in a public network and
has not been audited for security.**

The Docker image is based on the official
[Jekyll Docker image](https://hub.docker.com/r/jekyll/jekyll/) and runs
[Alpine Linux](https://alpinelinux.org/).

## Step 1: Download Docker CE

Follow the [installation instructions](https://docs.docker.com/engine/installation/)
on the Docker website.

**Note:** [Docker for Windows](https://docs.docker.com/docker-for-windows/) is
the recommended Docker environment for Windows, but it requires Windows 10 Pro,
Enterprise, or Education versions.  If you have Windows 10 Home, or an earlier
version of Windows, try
[Docker Toolbox](https://www.docker.com/products/docker-toolbox) instead.

## Step 2: Clone the Github repository

Clone a local working copy of the ```dev/alt-docker``` branch of
[artefactual-labs/schema-org](https://github.com/artefactual-labs/schema-org/tree/dev/alt-docker)
(forked from [archival/schema-org](https://github.com/archival/schema-org)).

```
git clone -b dev/alt-docker git@github.com:artefactual-labs/schema-org.git
cd schema-org
```

The ```dev/alt-docker``` branch is based on the ```alternative-proposal```
branch.

## Step 3: Build the Docker image

**Note**: You will need to perform an additional step in Linux to
[run docker as a non-root user](https://docs.docker.com/engine/installation/linux/linux-postinstall/#manage-docker-as-a-non-root-user).
Otherwise, use ```sudo docker``` to run docker commands.

To build the docker image using the local ```Dockerfile```:

```
docker build -t schema-arc .
```

## Step 4: Docker commands

A sampling of Docker commands to help you get started. See the
[Docker CLI reference](https://docs.docker.com/engine/reference/commandline/cli/)
for a comprehensive list of docker commands and options.

### Build Jekyll HTML and serve at http://127.0.0.1:4000/schema-org/

```
docker run -p 127.0.0.1:4000:4000 --rm --name jekyll-serve schema-arc
```

| Option                 | Description
| -----------------------|------------
| -p 127.0.0.1:4000:4000 | Bind container port 4000 (Jekyll server) to host address 127.0.0.1:4000
| --rm                   | Destroy the container after it exits
| --name jekyll-serve    | Name the running container "jekyll-serve"
| schema-arc             | Use docker image "schema-arc"

Press ```CTRL-C``` to stop the Jekyll server and destroy the Docker container.

### Run build validation script

```
docker run --rm schema-arc bash build.sh
```

The container will automatically stop after ```./build.sh``` exits.

### Open a bash terminal on a running container

```
docker exec -it jekyll-serve bash
```

## Notes

* Your local git working directory (this directory) is copied into the docker
  image when it is built.  To update the Jekyll template files in the image,
  make the changes locally, then rebuild the Docker image.  This workflow
  doesn't require opening a shell into the container to make changes.  It also
  doesn't require copying ssh keys into the image, or using ssh-agent, to push
  commits to a private git repository.
