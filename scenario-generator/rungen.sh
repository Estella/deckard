#!/usr/bin/env bash
VERSION=${VERSION:-3.0.1-germanium}

echo Building test container image
docker build -t deckard/lookup:local ./test

echo 'Starting Selenium Hub Container...'
HUB=$(docker run -d selenium/hub:3.0.1-germanium)
HUB_NAME=$(docker inspect -f '{{ .Name  }}' $HUB | sed s:/::)
echo 'Waiting for Hub to come online...'
#docker logs -f $HUB &
sleep 2

echo 'Starting Selenium Chrome node...'
NODE_CHROME=$(docker run -d --link $HUB_NAME:hub  selenium/node-chrome:${VERSION})
echo 'Starting Selenium Firefox node...'
NODE_FIREFOX=$(docker run -d --link $HUB_NAME:hub selenium/node-firefox:${VERSION})

#docker logs -f $NODE_CHROME &
#docker logs -f $NODE_FIREFOX &
echo 'Waiting for nodes to register and come online...'
sleep 2

function test_node {
  BROWSER=$1
  echo Running $BROWSER test...
  # Start monitoring here
  docker run -v $DIR/test:/test -it --link $HUB_NAME:hub -e browser="$BROWSER" deckard/lookup:local
  STATUS=$?
  TEST_CONTAINER=$(docker ps -aq | head -1)

  if [ ! $STATUS == 0 ]; then
    echo Failed
    exit 1
  fi
}

test_node chrome
test_node firefox

  echo Removing the test container
    docker rm $TEST_CONTAINER
  echo Tearing down Selenium Chrome Node container
  docker stop $NODE_CHROME
  docker rm $NODE_CHROME

  echo Tearing down Selenium Firefox Node container
  docker stop $NODE_FIREFOX
  docker rm $NODE_FIREFOX

  echo Tearing down Selenium Hub container
  docker stop $HUB
  docker rm $HUB

echo Done