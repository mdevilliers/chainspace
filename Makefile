CHAINSPACE_VERSION := 1.0.0
CHAINSPACE_JAR :=chainspace-$(CHAINSPACE_VERSION)-jar-with-dependencies.jar

BUILD_FOLDER := $(PWD)/build

clean: # resets the build folder
	rm -rf $(BUILD_FOLDER)
	mkdir -p $(BUILD_FOLDER)

.PHONY: clean

build: clean docker-build-init ## build chainspace in the docker build environment
	# creating dummy container which will hold a volume with the src
	docker create -v /app --name chainspace-build-vol chainspace/java-build /bash/true
	# copy the src files into this volume
	docker cp $(PWD) chainspace-build-vol:/app
	# start build container using this volume
	# The command line is a bit hairy but contains the following steps:
	# - cd to the correct folder
	# - build the uber-jar with mvn
	docker run --volumes-from chainspace-build-vol chainspace/java-build /bin/bash -c "cd /app/chainspace/chainspacecore; mvn -Dversion=$(CHAINSPACE_VERSION) package assembly:single"
	# once the build has finished we can copy artifacts directly from it
	docker cp chainspace-build-vol:/app/chainspace/chainspacecore/target/$(CHAINSPACE_JAR) $(BUILD_FOLDER)
	# clean up
	docker rm /chainspace-build-vol

.PHONY: build

docker-build: ## build docker container for running chainspace
	docker build -t chainspace/node -f docker/Dockerfile.chainspace-node .

.PHONY: docker-build

docker-build-init: ## build docker container for building chainspace
	docker build -t chainspace/java-build -f docker/Dockerfile.build .

.PHONY: docker-build-init

# 'help' parses the Makefile and displays the help text
help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
