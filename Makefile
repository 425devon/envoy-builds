WORK_DIR ?= .

GOOS ?= linux
GOARCH ?= amd64

BUILD_ENVOY_FROM_SOURCES ?= false

ENVOY_TAG ?= v1.22.0 # commit hash or git tag
# Remember to update pkg/version/compatibility.go
ENVOY_VERSION = $(shell ${WORK_DIR}/tools/envoy/version.sh ${ENVOY_TAG})

REMOTE_CACHE_SEVER_HOSTNAME ?= $(REMOTE_CACHE_SEVER_HOSTNAME)
REMOTE_CACHE_SEVER_IP ?= $(REMOTE_CACHE_SEVER_IP)

ifeq ($(GOOS),linux)
	ENVOY_DISTRO ?= alpine
endif
ENVOY_DISTRO ?= $(GOOS)

ifeq ($(ENVOY_DISTRO),centos)
	BUILD_ENVOY_SCRIPT = $(WORK_DIR)/tools/envoy/build_centos.sh
endif
BUILD_ENVOY_SCRIPT ?= $(WORK_DIR)/tools/envoy/build_$(GOOS).sh

SOURCE_DIR ?= ${TMPDIR}envoy-sources
ifndef TMPDIR
	SOURCE_DIR ?= /tmp/envoy-sources
endif

# Target 'build/envoy' allows to put Envoy binary under the build/artifacts-$GOOS-$GOARCH/envoy directory.
# Depending on the flag BUILD_ENVOY_FROM_SOURCES this target either fetches Envoy from binary registry or
# builds from sources. It's possible to build binaries for darwin, linux and centos by specifying GOOS
# and ENVOY_DISTRO variables. Envoy version could be specified by ENVOY_TAG that accepts git tag or commit
# hash values.
.PHONY: build/envoy
build/envoy:
	GOOS=${GOOS} \
	GOARCH=${GOARCH} \
	ENVOY_DISTRO=${ENVOY_DISTRO} \
	ENVOY_VERSION=${ENVOY_VERSION} \
	$(MAKE) build/artifacts-${GOOS}-${GOARCH}/envoy/envoy-${ENVOY_DISTRO}

# .PHONY: build/artifacts-linux-amd64/envoy/envoy
# build/artifacts-linux-amd64/envoy/envoy:
# 	GOOS=linux GOARCH=amd64 $(MAKE) build/envoy

# .PHONY: build/artifacts-linux-arm64/envoy/envoy
# build/artifacts-linux-arm64/envoy/envoy:
# 	GOOS=linux GOARCH=arm64 $(MAKE) build/envoy

build/artifacts-${GOOS}-${GOARCH}/envoy/envoy-${ENVOY_DISTRO}:
ifeq ($(BUILD_ENVOY_FROM_SOURCES),true)
	ENVOY_TAG=${ENVOY_TAG} \
	SOURCE_DIR=${SOURCE_DIR} \
	WORK_DIR=${WORK_DIR} \
	BINARY_PATH=$@ $(BUILD_ENVOY_SCRIPT)
else
	ENVOY_VERSION=${ENVOY_VERSION} \
	ENVOY_DISTRO=${ENVOY_DISTRO} \
	BINARY_PATH=$@ ${WORK_DIR}/tools/envoy/fetch.sh
endif

.PHONY: clean/envoy
clean/envoy:
	rm -rf ${SOURCE_DIR}
	rm -rf build/artifacts-${GOOS}-${GOARCH}/envoy/