
.PHONY: generate build push all clean

IMAGE_NAME := sphere-gen:latest

generate:
	@echo "Building Docker image..."
	docker build -f Dockerfile.gen -t $(IMAGE_NAME) . > /dev/null
	@echo "Linting proto files..."
	docker run --rm -v "$$PWD:/go/src/github.com/aunum/sphere" $(IMAGE_NAME) prototool lint api
	@echo "Generating Go bindings..."
	sudo rm -rf api/gen/go/*
	docker run --rm -v "$$PWD:/go/src/github.com/aunum/sphere" $(IMAGE_NAME) prototool generate api
	@echo "Moving generated files to correct location..."
	if [ -d api/gen/go/v1alpha/v1alpha ]; then \
		mv api/gen/go/v1alpha/v1alpha/* api/gen/go/v1alpha/ && \
		rmdir api/gen/go/v1alpha/v1alpha; \
	fi
	@echo "Creating ext.go..."
	echo "package spherev1alpha\n\n// Package spherev1alpha contains the generated protobuf code for the Sphere API v1alpha." > api/gen/go/v1alpha/ext.go
	@echo "Generating Python bindings..."
	docker run --rm -v "$$PWD:/go/src/github.com/aunum/sphere" $(IMAGE_NAME) python3 -m grpc.tools.protoc --python_out=./api/gen/python/v1alpha --grpc_python_out=./api/gen/python/v1alpha --proto_path ./api/v1alpha --proto_path /googleapis env.proto
	@echo "Fixing permissions..."
	sudo chown -R $$USER:$$USER api/gen/go/
	@echo "Generation complete!"

build:
	docker build -t sphereproject/gym:latest -f Dockerfile.gym .

push:
	docker push sphereproject/gym:latest

clean:
	sudo rm -rf api/gen/go/* api/gen/python/v1alpha/*.py

all: generate build push
