#!/bin/bash

my_dir="$( cd "$( dirname "${0}" )" && pwd )"
cd ${my_dir}

. ./rm_default_start_points.sh

failed=0
for file in ./test_*.sh; do
  ${file}
  if [ $? != 0 ]; then
    failed=1
  fi
done

exit ${failed}
