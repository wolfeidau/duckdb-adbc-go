SHELL := /bin/bash

DUCKDB_VERSION_TAG := v0.9.2
DUCKDB_RELEASE_URL := https://github.com/duckdb/duckdb/releases/download/${DUCKDB_VERSION_TAG}/
DUCKDB_EXTENSION_URL := http://extensions.duckdb.org/${DUCKDB_VERSION_TAG}/
DUCKDB_EXTENSION_PATH := extensions/${DUCKDB_VERSION_TAG}
DUCKDB_LIB_PATH := lib/${DUCKDB_VERSION_TAG}

.PHONY: default
default: download-linux-aarch64 download-extensions-linux-arm64 docker-build

.PHONY: download-linux-aarch64
download-linux-aarch64:
	mkdir -p ${DUCKDB_LIB_PATH}/linux-aarch64
	set -ex && source scripts/download.sh && \
		cd ${DUCKDB_LIB_PATH}/linux-aarch64 && \
		unzip-from-link ${DUCKDB_RELEASE_URL}libduckdb-linux-aarch64.zip .

.PHONY: download-extensions-linux-arm64
download-extensions-linux-arm64:
	mkdir -p ${DUCKDB_EXTENSION_PATH}/linux_arm64
	cd ${DUCKDB_EXTENSION_PATH}/linux_arm64 && \
		curl -OL ${DUCKDB_EXTENSION_URL}linux_arm64/iceberg.duckdb_extension.gz && \
		curl -OL ${DUCKDB_EXTENSION_URL}linux_arm64/httpfs.duckdb_extension.gz

.PHONY: download-osx-universal
download-osx-universal:
	mkdir -p ${DUCKDB_LIB_PATH}/osx-universal
	set -ex && source scripts/download.sh && \
		cd ${DUCKDB_LIB_PATH}/osx-universal && \
		unzip-from-link ${DUCKDB_RELEASE_URL}libduckdb-osx-universal.zip .

.PHONY: download-extensions-osx-arm64
download-extensions-osx-arm64:
	mkdir -p ${DUCKDB_EXTENSION_PATH}/osx_arm64
	cd ${DUCKDB_EXTENSION_PATH}/osx_arm64 && \
		curl -OL ${DUCKDB_EXTENSION_URL}osx_arm64/iceberg.duckdb_extension.gz && \
		curl -OL ${DUCKDB_EXTENSION_URL}osx_arm64/httpfs.duckdb_extension.gz && \
		gunzip *.gz

.PHONY: docker-build
docker-build:
	docker build -t duckdb-adbc-go:dev --build-arg DUCKDB_VERSION=${DUCKDB_VERSION_TAG} .

.PHONY: clean
clean:
	rm -rf lib
	rm -rf extensions