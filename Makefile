
version ?= develop
engine ?= podman
ns ?= quay.io/nitrate
baseimage ?=

sdist = nitrate-tcms==$(version)
my_base_image = $(ns)/base:$(version)
web_image = $(ns)/web:$(version)
worker_image = $(ns)/worker:$(version)

gh_tarball_url = https://github.com/Nitrate/Nitrate/tarball/develop
gh_develop_archive = nitrate-tcms-develop.tar.gz

.PHONY: tarball-release
tarball-released:
	python3 -m pip download -vvv --no-deps --no-binary :all: $(sdist)

.PHONY: tarball-develop
tarball-develop:
	@if [ -e "./Nitrate/" ]; then rm -rf Nitrate; fi
	@git clone --depth 1 https://github.com/Nitrate/Nitrate.git
	@cd Nitrate && make tarball
	@mv Nitrate/dist/*.tar.gz .

ifeq ($(strip $(version)),develop)
tarball-generation=tarball-develop
else
tarball-generation=tarball-released
endif

.PHONY: base-image
base-image: $(tarball-generation)
ifeq ($(strip $(version)), develop)
	@$(engine) build -t $(my_base_image) -f Dockerfile-base \
		$(if $(strip $(baseimage)),--build-arg base_image=$(baseimage),) \
		--build-arg version=$(shell cat "Nitrate/VERSION.txt") \
		--build-arg released=no \
		.
else
	@$(engine) build -t $(my_base_image) -f Dockerfile-base \
		$(if $(strip $(baseimage)),--build-arg base_image=$(baseimage),) \
		--build-arg version=$(version) \
		.
endif

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

.PHONY: clean-images
clean-images:
	@$(engine) rmi $(my_base_image) || :
	@$(engine) rmi $(web_image) || :
	@$(engine) rmi $(worker_image) || :

.PHONY: clean-artifacts
clean-artifacts:
	@[ -e "Nitrate/" ] && rm -rf Nitrate/
	@rm -f nitrate-tcms-*.tar.gz

.PHONY: clean
clean: clean-images clean-artifacts

# List nitrate related built images
.PHONY: list
list:
	@$(engine) images $(ns)

.PHONY: images-overview
images-overview:
	@echo $(my_base_image)
	@echo $(web_image)
	@echo $(worker_image)


.PHONY: lint-markdown
lint-markdown:
	@markdownlint-cli2 README.md

.PHONY: lint-dockerfile
# Pin to hadolint 2.10.0
lint-dockerfile:
	@hadolint --ignore DL3041 Dockerfile-base Dockerfile-web Dockerfile-worker

.PHONY: lint-all
lint-all: lint-markdown lint-dockerfile
