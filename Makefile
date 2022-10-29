
version ?= latest
engine ?= podman
ns ?= quay.io/nitrate
baseimage ?=

sdist = nitrate-tcms=="$(version)"
my_base_image = $(ns)/nitrate:base-$(version)
web_image = $(ns)/nitrate:web-$(version)
worker_image = $(ns)/nitrate:worker-$(version)

base_build_args ::= --build-arg version=$(version)
ifneq ($(strip $(baseimage)),)
base_build_args += --build-arg base_image=$(baseimage)
endif

.PHONY: base-image
base-image:
	@python3 -m pip download --no-deps --no-binary :all: $(sdist)
	@$(engine) build -t $(my_base_image) -f Dockerfile-base $(base_build_args) .

.PHONY: web-image
web-image:
	@$(engine) build -t $(web_image) -f Dockerfile-web \
		--build-arg version=$(version) --build-arg ns=$(ns) .

.PHONY: worker-image
worker-image:
	@$(engine) build -t $(worker_image) -f Dockerfile-worker \
		--build-arg version=$(version) --build-arg ns=$(ns) .

.PHONY: all-images
all-images: base-image web-image worker-image

.PHONY: push-all
push-all: base-image web-image worker-image
	@$(engine) push $(my_base_image)
	@$(engine) push $(web_image)
	@$(engine) push $(worker_image)

.PHONY: clean
clean:
	@$(engine) rmi $(my_base_image) || :
	@$(engine) rmi $(web_image) || :
	@$(engine) rmi $(worker_image) || :

# List nitrate related built images
.PHONY: list
list:
	@$(engine) images $(ns)

.PHONY: images-overview
images-overview:
	@echo $(my_base_image)
	@echo $(web_image)
	@echo $(worker_image)
