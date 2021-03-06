#!/bin/bash
set -e

my_dir="$( cd "$( dirname "${0}" )" && pwd )"
docker_compose_version=${1:-1.8.1}

cd ${my_dir}
./build.sh ${docker_compose_version}
./test/sh/run.sh
docker run --rm cyberdojo/commander sh -c 'cd test/rb && ./run.sh'
