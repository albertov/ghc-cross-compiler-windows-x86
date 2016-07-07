#!/bin/sh
set -e

repo=${1}
patch_dir=$(pwd)/patches

if [ ! -d ${repo}/.git ]; then
  echo Repository not found: ${repo}
  exit 1
fi
cd ${repo}
mkdir -p ${patch_dir}/ghc ${patch_dir}/hsc2hs
git format-patch -o${patch_dir}/ghc    ghc-8.0.1-release...cross-external-interpreter
cd utils/hsc2hs
git format-patch -o${patch_dir}/hsc2hs 5119ae...cross-mingw-hacks
