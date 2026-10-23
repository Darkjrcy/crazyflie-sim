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

ln -sfnT "$project_root" "$path_alias"

if [[ -f "$project_root/.venv/bin/activate" ]]; then
    # shellcheck disable=SC1091
    source "$project_root/.venv/bin/activate"
fi
export PYTHONNOUSERSITE=1

if pgrep -u "$UID" -x cf2 >/dev/null 2>&1 || \
        pgrep -u "$UID" -f '(^|/)gz[[:space:]]+sim([[:space:]]|$)' >/dev/null 2>&1; then
    echo "Error: a Gazebo simulation or cf2 firmware instance is already running." >&2
    echo "Keep that simulation and use a second terminal for the Python example," >&2
    echo "or stop it with Ctrl+C before starting a new simulation." >&2
    exit 1
fi

firmware_root="$path_alias/vendor/CrazySim/crazyflie-firmware"
firmware_binary="$firmware_root/sitl_make/build/cf2"
launch_script="tools/crazyflie-simulation/simulator_files/gazebo/launch/sitl_singleagent.sh"

if [[ ! -x "$firmware_binary" ]]; then
    echo "Error: CrazySim has not been built successfully." >&2
    echo "Run ./scripts/build-crazysim-native.sh first." >&2
    exit 1
fi

cd "$firmware_root"
exec bash "$launch_script" "$@"
