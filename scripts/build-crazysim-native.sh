#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd -- "$script_dir/.." && pwd)"
path_alias="/tmp/crazyflie-sim-native-${UID}"

if [[ -e "$path_alias" && ! -L "$path_alias" ]]; then
    echo "Error: $path_alias exists and is not a symbolic link." >&2
    echo "Move it out of the way, then run this script again." >&2
    exit 1
fi

# CrazySim's upstream CMake and shell files do not quote every path. Building
# through this stable alias prevents spaces in project_root from being split.
ln -sfnT "$project_root" "$path_alias"

if [[ -f "$project_root/.venv/bin/activate" ]]; then
    # shellcheck disable=SC1091
    source "$project_root/.venv/bin/activate"
fi
export PYTHONNOUSERSITE=1

firmware_root="$path_alias/vendor/CrazySim/crazyflie-firmware"
build_dir="$firmware_root/sitl_make/build"
parallel_jobs="${CMAKE_BUILD_PARALLEL_LEVEL:-$(nproc)}"

cmake -S "$firmware_root/sitl_make" -B "$build_dir"
cmake --build "$build_dir" --parallel "$parallel_jobs"

if [[ ! -x "$build_dir/cf2" ]]; then
    echo "Error: the Crazyflie firmware executable was not produced." >&2
    exit 1
fi

echo "CrazySim native build completed: $build_dir/cf2"
