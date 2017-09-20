

build: docker-init ## build chainspace in the docker build environment
	# creating dummy container which will hold a volume with the src
	docker create -v /app --name chainspace-build-vol chainspace/java-build /bash/true
	# copying the src files into this volume
	docker cp $(PWD) chainspace-build-vol:/app
	# starting application container using this volume
	# The command line is a bit hairy but contains the following steps:
	# - install the dependencies via mvn
	# - build with mvn
	docker run --volumes-from chainspace-build-vol chainspace/java-build /bin/bash -c "cd /app/chainspace/chainspacecore; mvn package "
	# once the build has finished we can copy artifacts directly from it
	docker cp chainspace-build-vol:/app/chainspace/chainspacecore/target $(PWD)/target
	# clean up
	docker rm /chainspace-build-vol

.PHONY: build

docker-init: ## build docker container for building chainspace
	docker build -t chainspace/java-build -f docker/Dockerfile.build .

.PHONY: docker-init 

# 'help' parses the Makefile and displays the help text
help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
