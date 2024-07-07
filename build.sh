#!/usr/bin/env bash

LATEST=false
VERSIONS=('8.1' '8.2' '8.3' '8.4')

while [ ! $# -eq 0 ]; do
    case "$1" in
    -l | --latest)
        LATEST=true
        ;;
    -v | --version)
        if [ "$2" ]; then
            VERSIONS=("$2")
            shift
        else
            echo "${1} requires a value"
            exit 1
        fi
        ;;
    esac

    shift
done

for VERSION in "${VERSIONS[@]}"
do
  docker build . --no-cache --build-arg PHP_VERSION="$VERSION" -t raazpuspa/larasail:"$VERSION" --target=default
  docker push raazpuspa/larasail:"$VERSION"

  docker build . --build-arg PHP_VERSION="$VERSION" -t raazpuspa/larasail:"$VERSION"-mssql --target=mssql
  docker push raazpuspa/larasail:"$VERSION"-mssql
done

if [ "$LATEST" = true ]; then
  docker tag raazpuspa/larasail:"$VERSION" raazpuspa/larasail:latest
  docker push raazpuspa/larasail:latest

  docker tag raazpuspa/larasail:"$VERSION"-mssql raazpuspa/larasail:latest-mssql
  docker push raazpuspa/larasail:latest-mssql
fi
