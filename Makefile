
version ?= develop
engine ?= podman
ns ?= quay.io/nitrate
baseimage ?=

package_name = nitrate-tcms

# NOTE: newer versions of setuptools (invoked via build) adhere to PEP 625
# It replaces - with _
normalised_sdist_name = nitrate_tcms

sdist = $(package_name)==$(version)
my_base_image = $(ns)/base:$(version)
web_image = $(ns)/web:$(version)
worker_image = $(ns)/worker:$(version)

gh_tarball_url = https://github.com/Nitrate/Nitrate/tarball/develop
gh_develop_archive = nitrate-tcms-develop.tar.gz


.PHONY: remove-app-tarball
remove-app-tarball:
	@rm -f app.tar.gz

.PHONY: tarball-release
tarball-released: remove-app-tarball
	python3 -m pip download --no-deps --no-binary :all: $(sdist)
	for sdist_name in $(package_name) $(normalised_sdist_name); do \
		if mv $${sdist_name}-$(version).tar.gz app.tar.gz 2>&1; then \
			break; \
		fi; \
		done

GIT_REPO ?= https://github.com/Nitrate/Nitrate.git

.PHONY: tarball-develop
tarball-develop: remove-app-tarball
	@if [ -e "./Nitrate/" ]; then rm -rf Nitrate; fi
	@git clone $(GIT_REPO)
	cd Nitrate && \
	make sdist && \
	for sdist_name in $(package_name) $(normalised_sdist_name); do \
		if mv dist/$${sdist_name}-$$(cat VERSION.txt).tar.gz ../app.tar.gz >/dev/null 2>&1; then \
			break; \
		fi; \
		done

ifeq ($(strip $(version)),develop)
tarball-generation=tarball-develop
# e.g. v4.12-2-g
label_version_regex = "^v[0-9]\+\.[0-9]\+\(\.[0-9]\+\)\?-[0-9]\+-g[0-9a-f]\+$"
else
tarball-generation=tarball-released
label_version_regex = "^[0-9]\+\.[0-9]\+\(\.[0-9]\+\)\?$"
endif

.PHONY: base-image
base-image: $(tarball-generation)
ifeq ($(strip $(version)), develop)
	$(engine) build -t $(my_base_image) -f Dockerfile-base \
		$(if $(strip $(baseimage)),--build-arg base_image=$(baseimage),) \
		--build-arg version=$$(git --git-dir Nitrate/.git describe) \
		--label org.opencontainers.image.created=$(shell date --utc --iso-8601=seconds) \
		--label org.opencontainers.image.revision=$(shell git --git-dir Nitrate/.git rev-parse HEAD) \
		.
else
	$(engine) build -t $(my_base_image) -f Dockerfile-base \
		$(if $(strip $(baseimage)),--build-arg base_image=$(baseimage),) \
		--build-arg version=$(version) \
		--label org.opencontainers.image.created=$(shell date --utc --iso-8601=seconds) \
		--label org.opencontainers.image.revision=$(shell sh -c "git ls-remote --tags --refs $(GIT_REPO) refs/tags/v$(version) | cut -f1") \
		.
endif

.PHONY: web-image
web-image:
	@$(engine) build -t $(web_image) -f Dockerfile-web \
		--build-arg version=$(version) \
		--build-arg ns=$(ns) \
		--label org.opencontainers.image.created=$(shell date --utc --iso-8601=seconds) \
		.

.PHONY: worker-image
worker-image:
	@$(engine) build -t $(worker_image) -f Dockerfile-worker \
		--build-arg version=$(version) \
		--build-arg ns=$(ns) \
		--label org.opencontainers.image.created=$(shell date --utc --iso-8601=seconds) \
		.

.PHONY: all-images
all-images: base-image web-image worker-image

.PHONY: push-all
push-all: base-image web-image worker-image
	@$(engine) push $(my_base_image)
	@$(engine) push $(web_image)
	@$(engine) push $(worker_image)

.PHONY: clean-images
clean-images:
	@$(engine) rmi -f $(my_base_image)
	@$(engine) rmi -f $(web_image)
	@$(engine) rmi -f $(worker_image)

.PHONY: clean-artifacts
clean-artifacts:
	rm -rf Nitrate/
	rm -f $(package_name)-*.tar.gz
	rm -f $(normalised_sdist_name)-*.tar.gz

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
