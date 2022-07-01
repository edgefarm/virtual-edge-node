#vars
VERSION?=latest
IMAGENAME=edgefarm/virtual-edge-node
REPO=ghcr.io
IMAGEFULLNAME=${REPO}/${IMAGENAME}:${VERSION}

.PHONY: help build push all

help:
	    @echo "Makefile arguments:"
	    @echo ""
	    @echo "Makefile commands:"
	    @echo "build"
	    @echo "push"
	    @echo "all"

.DEFAULT_GOAL := all

build:
	    @docker build --pull -t ${IMAGEFULLNAME} .

push:
	    @docker push ${IMAGEFULLNAME}

all: build push
