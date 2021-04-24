IMAGE=deweysasser/tools
PROXY=http://172.17.0.4:3128
CACHE=

all: build

build:
	DOCKER_BUILDKIT=1 docker build $(CACHE) -t $(IMAGE) .
