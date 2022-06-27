#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

echo "Building Envoy for CentOS 7"

mkdir -p "$(dirname "${BINARY_PATH}")"

SOURCE_DIR="${SOURCE_DIR}" "${WORK_DIR:-.}/tools/envoy/fetch_sources.sh"
CONTRIB_ENABLED_MATRIX_SCRIPT=$(realpath "${WORK_DIR:-.}/tools/envoy/contrib_enabled_matrix.py")

BAZEL_BUILD_EXTRA_OPTIONS=${BAZEL_BUILD_EXTRA_OPTIONS:-""}
read -ra BAZEL_BUILD_EXTRA_OPTIONS <<< "${BAZEL_BUILD_EXTRA_OPTIONS}"
BAZEL_BUILD_OPTIONS=(
    "--config=libc++"
    "--verbose_failures"
    "--remote_cache=http://${REMOTE_CACHE_SEVER}:8080"
    "${BAZEL_BUILD_EXTRA_OPTIONS[@]+"${BAZEL_BUILD_EXTRA_OPTIONS[@]}"}")
BUILD_TARGET=${BUILD_TARGET:-"//contrib/exe:envoy-static"}

pushd "${SOURCE_DIR}"
CONTRIB_ENABLED_ARGS=$(python "${CONTRIB_ENABLED_MATRIX_SCRIPT}")
popd

BUILD_CMD=${BUILD_CMD:-"bazel build ${BAZEL_BUILD_OPTIONS[@]} -c opt ${BUILD_TARGET} ${CONTRIB_ENABLED_ARGS} --//source/extensions/transport_sockets/tcp_stats:enabled=false"}

ENVOY_BUILD_SHA=$(curl --fail --location --silent https://raw.githubusercontent.com/envoyproxy/envoy/"${ENVOY_TAG}"/.bazelrc | grep envoyproxy/envoy-build-ubuntu | sed -e 's#.*envoyproxy/envoy-build-ubuntu:\(.*\)#\1#'| uniq)
ENVOY_BUILD_IMAGE="envoyproxy/envoy-build-centos:${ENVOY_BUILD_SHA}"
LOCAL_BUILD_IMAGE="envoy-builder:${ENVOY_TAG}"

docker build --add-host="${REMOTE_CACHE_SEVER_HOSTNAME}:${REMOTE_CACHE_SEVER_IP}" -t "${LOCAL_BUILD_IMAGE}" --progress=plain \
  --build-arg REMOTE_CACHE_SEVER="${REMOTE_CACHE_SEVER_HOSTNAME}" \
  --build-arg ENVOY_BUILD_IMAGE="${ENVOY_BUILD_IMAGE}" \
  --build-arg BUILD_CMD="${BUILD_CMD}" \
  -f tools/envoy/Dockerfile.build-centos "${SOURCE_DIR}"

# copy out the binary
id=$(docker create "${LOCAL_BUILD_IMAGE}")
docker cp "$id":/envoy-sources/bazel-bin/contrib/exe/envoy "${BINARY_PATH}"
docker rm -v "$id"
