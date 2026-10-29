#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
IMAGE_TAG="${POC_IMAGE_TAG:-colcon-roadmap-ros2-poc:jazzy}"
SKIP_BUILD=0
FORWARD_ARGS=()

usage() {
  cat <<'EOF'
Usage: ./poc/run_poc.sh [options]

Builds (if needed) the ROS 2 Jazzy PoC Docker image containing the modernized
colcon-core (#750 + #751) and colcon-ros (#171) stack, then executes the
human-readable 6-stage verification pipeline against real ROS 2 packages
migrated to pure PEP 621 pyproject.toml (no setup.py, no setup.cfg).

Options:
  --target, -t <name>   Target ROS 2 package set to build and test:
                          demo_nodes_py          (Default) ros2/demos [hatchling]
                          examples_rclpy         (Optional 2) ros2/examples [flit_core]
                          teleop_twist_keyboard  (Optional 3) ros2/teleop_twist_keyboard [setuptools]
                          all                    Run all three targets sequentially
  --skip-image-build    Reuse existing Docker image without running docker build
  --help, -h            Show this help message

Environment Overrides:
  POC_REPOS_BASE        Git base URL or mounted directory (default: https://github.com/KmoM88)
  POC_BRANCH            Git branch in target repos (default: poc/pep621-ament-python)
  POC_IMAGE_TAG         Docker image tag (default: colcon-roadmap-ros2-poc:jazzy)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-image-build)
      SKIP_BUILD=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      FORWARD_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ "${SKIP_BUILD}" -eq 0 ]]; then
  echo "================================================================================"
  echo "  Building Docker Image: ${IMAGE_TAG}"
  echo "================================================================================"
  docker build -t "${IMAGE_TAG}" -f "${SCRIPT_DIR}/Dockerfile" "${REPO_ROOT}"
fi

DOCKER_ARGS=(--rm)
if [[ -n "${POC_REPOS_BASE:-}" ]]; then
  if [[ -d "${POC_REPOS_BASE}" ]]; then
    ABS_REPOS_BASE="$(cd "${POC_REPOS_BASE}" && pwd)"
    DOCKER_ARGS+=(-v "${ABS_REPOS_BASE}:/poc_local_repos:ro" -e "POC_REPOS_BASE=/poc_local_repos")
  else
    DOCKER_ARGS+=(-e "POC_REPOS_BASE=${POC_REPOS_BASE}")
  fi
fi
if [[ -n "${POC_BRANCH:-}" ]]; then
  DOCKER_ARGS+=(-e "POC_BRANCH=${POC_BRANCH}")
fi

docker run "${DOCKER_ARGS[@]}" "${IMAGE_TAG}" "${FORWARD_ARGS[@]}"
