IMAGE=deweysasser/tools

all: build

build:
	docker build -t $(IMAGE) .
