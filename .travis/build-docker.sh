#!/bin/bash

TAG="${TRAVIS_BRANCH//\//_}"

ORG=`echo $DOCKER_PROJECT | tr '[:upper:]' '[:lower:]'`
ORG="${ORG:+${ORG}/}"
IMAGE="${ORG}app-container-base"
TIMESTAMP=`date +'%y%m%d%H'`
GITHASH=`git log -1 --pretty=format:"%h"`

BUILD_VERSION="${TIMESTAMP}_${GITHASH}${TRAVIS_BRANCH:+:$TRAVIS_BRANCH}"
echo "BUILD_VERSION $BUILD_VERSION"

GRIDAPPSD_PYTHON_VERSION=`grep version pyproject.toml | awk '{print $NF}' | sed 's/"//g'`

if [ -n "$DOCKER_USERNAME" -a -n "$DOCKER_PASSWORD" ]; then

  echo " "
  echo "Connecting to docker"

  echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
  status=$?
  if [ $status -ne 0 ]; then
    echo "Error: status $status"
    exit 1
  fi
fi

# Pass gridappsd tag to docker-compose
docker build --build-arg TIMESTAMP="${BUILD_VERSION}" --build-arg GRIDAPPSD_PYTHON_VERSION="==${GRIDAPPSD_PYTHON_VERSION}" -t ${IMAGE}:${TIMESTAMP}_${GITHASH} .
status=$?
if [ $status -ne 0 ]; then
  echo "Error: status $status"
  exit 1
fi

# To have `DOCKER_USERNAME` and `DOCKER_PASSWORD`
# filled you need to either use `travis`' cli
# (https://github.com/travis-ci/travis.rb)
# and then `travis set ..` or go to the travis
# page of your repository and then change the
# environment in the settings pannel.

if [ -n "$DOCKER_USERNAME" -a -n "$DOCKER_PASSWORD" ]; then

  echo " "
  echo "Connecting to docker"

  echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
  status=$?
  if [ $status -ne 0 ]; then
    echo "Error: status $status"
    exit 1
  fi

  if [ -n "$TAG" -a -n "$ORG" ]; then
    # Get the built container name
    CONTAINER=`docker images --format "{{.Repository}}:{{.Tag}}" ${IMAGE}`

    echo "docker push ${CONTAINER}"
    docker push "${CONTAINER}"
    status=$?
    if [ $status -ne 0 ]; then
      echo "Error: status $status"
      exit 1
    fi

    echo "docker tag ${CONTAINER} ${IMAGE}:$TAG"
    docker tag ${CONTAINER} ${IMAGE}:$TAG
    status=$?
    if [ $status -ne 0 ]; then
      echo "Error: status $status"
      exit 1
    fi

    echo "docker push ${IMAGE}:$TAG"
    docker push ${IMAGE}:$TAG
    status=$?
    if [ $status -ne 0 ]; then
      echo "Error: status $status"
      exit 1
    fi
  fi

fi
