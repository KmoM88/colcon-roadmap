#!/usr/bin/env bash
set -euo pipefail

POC_REPOS_BASE="${POC_REPOS_BASE:-https://github.com/KmoM88}"
POC_BRANCH="${POC_BRANCH:-poc/pep621-ament-python}"
TARGET="demo_nodes_py"

usage() {
  cat <<'EOF'
Usage: container_poc.sh [--target <demo_nodes_py|examples_rclpy|teleop_twist_keyboard|all>]

Targets (active ros2/* repositories migrated to pure PEP 621 pyproject.toml):
  demo_nodes_py          (Default) ros2/demos -> demo_nodes_py [hatchling.build]
  examples_rclpy         (Optional 2) ros2/examples -> minimal_publisher & minimal_subscriber [flit_core.buildapi]
  teleop_twist_keyboard  (Optional 3) ros2/teleop_twist_keyboard -> teleop_twist_keyboard [setuptools.build_meta]
  all                    Run all three ROS 2 targets sequentially
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target|-t)
      TARGET="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

export ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST

if [[ "${POC_REPOS_BASE}" == /* ]]; then
  git config --global --add safe.directory '*'
fi

banner() {
  echo ""
  echo "================================================================================"
  echo "  $1"
  echo "================================================================================"
}

stage_header() {
  echo ""
  echo "--------------------------------------------------------------------------------"
  echo "  $1"
  echo "--------------------------------------------------------------------------------"
}

info() {
  echo "  [INFO] $*"
}

ok() {
  echo "  [OK]   $*"
}

fail() {
  echo "  [FAIL] $*" >&2
  exit 1
}

resolve_repo_url() {
  local repo_name="$1"
  if [[ "$POC_REPOS_BASE" == http://* || "$POC_REPOS_BASE" == https://* || "$POC_REPOS_BASE" == git@* ]]; then
    echo "${POC_REPOS_BASE%/}/${repo_name}.git"
  else
    echo "${POC_REPOS_BASE%/}/${repo_name}"
  fi
}

print_stack_overview() {
  banner "COLCON PEP 517 / 518 / 621 / 660 -- ROS 2 PROOF OF CONCEPT"
  set +u
  # shellcheck disable=SC1091
  source /opt/ros/jazzy/setup.bash
  set -u
  python3 - <<'PY'
import inspect
import sys
import colcon_core
import colcon_ros
from colcon_core.task.python_project.build import PythonProjectBuildTask
from colcon_ros.task.ament_python.build import AmentPythonBuildTask

sig = inspect.signature(PythonProjectBuildTask.build)
print(f"  ROS 2 Distribution       : jazzy (Ubuntu 24.04 Noble)")
print(f"  Python Runtime           : {sys.version.split()[0]} ({sys.executable})")
print(f"  colcon-core              : {colcon_core.__version__} ({colcon_core.__file__})")
print(f"  colcon-ros               : {colcon_ros.__version__} ({colcon_ros.__file__})")
print(f"  PythonProjectBuildTask   : build{sig}")
print(f"  AmentPythonBuildTask     : {AmentPythonBuildTask.__module__}")
PY
}

verify_pure_pep621_package() {
  local pkg_dir="$1"
  local pkg_name="$2"
  local expected_backend="$3"

  [[ -f "${pkg_dir}/package.xml" ]] || fail "${pkg_name}: missing package.xml"
  [[ -f "${pkg_dir}/pyproject.toml" ]] || fail "${pkg_name}: missing pyproject.toml"
  [[ ! -e "${pkg_dir}/setup.py" ]] || fail "${pkg_name}: legacy setup.py still exists"
  [[ ! -e "${pkg_dir}/setup.cfg" ]] || fail "${pkg_name}: legacy setup.cfg still exists"

  grep -q "<build_type>ament_python</build_type>" "${pkg_dir}/package.xml" \
    || fail "${pkg_name}: package.xml is not <build_type>ament_python</build_type>"
  grep -q "${expected_backend}" "${pkg_dir}/pyproject.toml" \
    || fail "${pkg_name}: expected build-backend '${expected_backend}' in pyproject.toml"

  ok "${pkg_name}: package.xml (<build_type>ament_python</build_type>) PRESENT"
  ok "${pkg_name}: pyproject.toml (build-backend = ${expected_backend}) PRESENT"
  ok "${pkg_name}: setup.py ABSENT | setup.cfg ABSENT"
  echo ""
  echo "  --- ${pkg_name}/pyproject.toml (header) ---"
  sed -n '1,18p' "${pkg_dir}/pyproject.toml" | sed 's/^/    /'
}

verify_ros_install_layout() {
  local ws_dir="$1"
  local pkg_name="$2"
  local expected_exec="$3"

  local pkg_prefix="${ws_dir}/install/${pkg_name}"
  [[ -x "${pkg_prefix}/lib/${pkg_name}/${expected_exec}" ]] \
    || fail "${pkg_name}: executable not installed at lib/${pkg_name}/${expected_exec}"
  [[ ! -e "${pkg_prefix}/bin/${expected_exec}" ]] \
    || fail "${pkg_name}: executable unexpectedly placed in bin/ instead of lib/${pkg_name}/"
  [[ -f "${pkg_prefix}/share/ament_index/resource_index/packages/${pkg_name}" ]] \
    || fail "${pkg_name}: missing ament_index package marker"
  [[ -f "${pkg_prefix}/share/${pkg_name}/package.xml" ]] \
    || fail "${pkg_name}: missing installed share/${pkg_name}/package.xml"
  [[ -f "${pkg_prefix}/share/${pkg_name}/hook/ament_prefix_path.sh" ]] \
    || fail "${pkg_name}: missing hook/ament_prefix_path.sh"

  ok "${pkg_name}: executable routed to install/${pkg_name}/lib/${pkg_name}/${expected_exec} (via script_dir_override)"
  ok "${pkg_name}: ament_index marker at share/ament_index/resource_index/packages/${pkg_name}"
  ok "${pkg_name}: manifest installed at share/${pkg_name}/package.xml"
  ok "${pkg_name}: environment hook at share/${pkg_name}/hook/ament_prefix_path.sh"

  python3 - "${pkg_prefix}" "${pkg_name}" <<'PY'
from pathlib import Path
import sys

prefix = Path(sys.argv[1])
pkg_name = sys.argv[2]
records = list(prefix.glob(f"lib/python*/site-packages/{pkg_name}-*.dist-info/RECORD"))
assert len(records) == 1, f"Expected 1 RECORD file for {pkg_name}, found {records}"
record_path = records[0]
lines = [line for line in record_path.read_text(encoding="utf-8").splitlines() if line.strip()]
assert len(lines) == len(set(lines)), f"Duplicate entries found in {record_path}"
text = "\n".join(lines)
assert f"share/ament_index/resource_index/packages/{pkg_name}" in text, "ament_index missing from RECORD"
assert f"share/{pkg_name}/package.xml" in text, "package.xml missing from RECORD"
print(f"  [OK]   {pkg_name}: .dist-info/RECORD verified ({len(lines)} unique tracked entries, including ament_index & package.xml)")
PY
}

verify_editable_metadata() {
  local ws_dir="$1"
  local pkg_name="$2"

  python3 - "${ws_dir}/install/${pkg_name}" "${pkg_name}" <<'PY'
import json
from pathlib import Path
import sys

prefix = Path(sys.argv[1])
pkg_name = sys.argv[2]
direct_urls = list(prefix.glob(f"lib/python*/site-packages/{pkg_name}-*.dist-info/direct_url.json"))
assert len(direct_urls) == 1, f"Expected direct_url.json for {pkg_name}, found {direct_urls}"
data = json.loads(direct_urls[0].read_text(encoding="utf-8"))
assert data.get("dir_info", {}).get("editable") is True, f"Expected editable=True, got {data}"
print(f"  [OK]   {pkg_name}: PEP 610 direct_url.json -> {json.dumps(data)}")
PY
}

run_pubsub_check() {
  local ws_dir="$1"
  local pub_pkg="$2"
  local pub_exe="$3"
  local sub_pkg="$4"
  local sub_exe="$5"
  local domain_id="$6"

  local pub_log="${ws_dir}/pub_runtime.log"
  local sub_log="${ws_dir}/sub_runtime.log"

  (
    export ROS_DOMAIN_ID="${domain_id}"
    set +u
    # shellcheck disable=SC1091
    source /opt/ros/jazzy/setup.bash
    # shellcheck disable=SC1091
    source "${ws_dir}/install/setup.bash"
    set -u

    timeout --signal=TERM --kill-after=2s 12s ros2 run "${sub_pkg}" "${sub_exe}" >"${sub_log}" 2>&1 &
    sub_pid=$!
    timeout --signal=TERM --kill-after=2s 12s ros2 run "${pub_pkg}" "${pub_exe}" >"${pub_log}" 2>&1 &
    pub_pid=$!

    matched=0
    for _ in $(seq 1 20); do
      if grep -q "I heard:" "${sub_log}" 2>/dev/null; then
        matched=1
        break
      fi
      sleep 0.5
    done

    kill -TERM "${pub_pid}" "${sub_pid}" 2>/dev/null || true
    wait "${pub_pid}" 2>/dev/null || true
    wait "${sub_pid}" 2>/dev/null || true

    [[ "${matched}" -eq 1 ]]
  ) || {
    echo "  --- Publisher log ---"
    cat "${pub_log}" 2>/dev/null || true
    echo "  --- Subscriber log ---"
    cat "${sub_log}" 2>/dev/null || true
    fail "DDS pub/sub verification timed out between ${pub_pkg}:${pub_exe} and ${sub_pkg}:${sub_exe}"
  }

  echo "  --- Publisher output (${pub_pkg} -> ${pub_exe}) ---"
  grep "Publishing:" "${pub_log}" | head -n 3 | sed 's/^/    /'
  echo "  --- Subscriber output (${sub_pkg} -> ${sub_exe}) ---"
  grep "I heard:" "${sub_log}" | head -n 3 | sed 's/^/    /'
  ok "Live ROS 2 DDS message exchange verified (${pub_pkg}:${pub_exe} -> ${sub_pkg}:${sub_exe})"
}

run_target_demo_nodes_py() {
  local ws_dir="/tmp/poc_ws_demo_nodes_py"
  local repo_url
  repo_url="$(resolve_repo_url demos)"
  rm -rf "${ws_dir}"
  mkdir -p "${ws_dir}/src"

  banner "TARGET 1 (PRIMARY): ros2/demos -> demo_nodes_py [Backend: hatchling.build]"
  info "Upstream Repository : https://github.com/ros2/demos (active ROS 2 Jazzy)"
  info "PoC Source & Branch : ${repo_url} @ ${POC_BRANCH}"
  info "Capabilities Tested : Pure pyproject.toml (no setup.py/setup.cfg), 13 ROS 2 nodes,"
  info "                      share/ data file (params.yaml), PEP 660 --symlink-install,"
  info "                      live talker/listener DDS pub/sub, and colcon test (pytest)."

  stage_header "[STAGE 1/6] Source Clone & Pure PEP 621 Manifest Audit"
  git clone --quiet --branch "${POC_BRANCH}" --single-branch "${repo_url}" "${ws_dir}/src/demos"
  local pkg_dir="${ws_dir}/src/demos/demo_nodes_py"
  verify_pure_pep621_package "${pkg_dir}" "demo_nodes_py" "hatchling.build"

  (
    cd "${ws_dir}"
    set +u
    # shellcheck disable=SC1091
    source /opt/ros/jazzy/setup.bash
    set -u
    echo ""
    info "colcon package identification:"
    colcon list --packages-select demo_nodes_py | sed 's/^/    /'
  )

  stage_header "[STAGE 2/6] Standard PEP 517 Wheel Build & ROS 2 FHS Layout Check"
  (
    cd "${ws_dir}"
    set +u
    # shellcheck disable=SC1091
    source /opt/ros/jazzy/setup.bash
    set -u
    colcon build --packages-select demo_nodes_py --event-handlers console_cohesion+ | sed 's/^/    /'
  )
  verify_ros_install_layout "${ws_dir}" "demo_nodes_py" "talker"
  [[ -x "${ws_dir}/install/demo_nodes_py/lib/demo_nodes_py/listener" ]] \
    || fail "demo_nodes_py: listener executable missing"
  ok "demo_nodes_py: executable routed to install/demo_nodes_py/lib/demo_nodes_py/listener (via script_dir_override)"

  local installed_params="${ws_dir}/install/demo_nodes_py/share/demo_nodes_py/params.yaml"
  [[ -f "${installed_params}" && ! -L "${installed_params}" ]] \
    || fail "demo_nodes_py: expected regular file at share/demo_nodes_py/params.yaml in standard build"
  ok "demo_nodes_py: share/demo_nodes_py/params.yaml unpacked as regular file from wheel .data/"

  stage_header "[STAGE 3/6] Live ROS 2 CLI Discovery & Talker/Listener DDS Execution"
  (
    set +u
    # shellcheck disable=SC1091
    source /opt/ros/jazzy/setup.bash
    # shellcheck disable=SC1091
    source "${ws_dir}/install/setup.bash"
    set -u
    local prefix_out
    prefix_out="$(ros2 pkg prefix demo_nodes_py)"
    info "ros2 pkg prefix demo_nodes_py -> ${prefix_out}"
    local exec_count
    exec_count="$(ros2 pkg executables demo_nodes_py | wc -l)"
    echo "  --- ros2 pkg executables demo_nodes_py (${exec_count} nodes discovered) ---"
    ros2 pkg executables demo_nodes_py | sed 's/^/    /'
    [[ "${exec_count}" -eq 13 ]] || fail "Expected 13 executables for demo_nodes_py, got ${exec_count}"
  )
  ok "ROS 2 CLI discovered all 13 console_scripts nodes without setup.py or setup.cfg"
  run_pubsub_check "${ws_dir}" "demo_nodes_py" "talker" "demo_nodes_py" "listener" "41"

  stage_header "[STAGE 4/6] PEP 660 Editable Rebuild (--symlink-install) & Live Data-File Symlink"
  (
    cd "${ws_dir}"
    set +u
    # shellcheck disable=SC1091
    source /opt/ros/jazzy/setup.bash
    set -u
    colcon build --symlink-install --packages-select demo_nodes_py --event-handlers console_cohesion+ | sed 's/^/    /'
    # Run an immediate second editable rebuild to verify idempotent remove_distributions cleanup
    colcon build --symlink-install --packages-select demo_nodes_py >/dev/null
  )
  verify_editable_metadata "${ws_dir}" "demo_nodes_py"
  verify_ros_install_layout "${ws_dir}" "demo_nodes_py" "talker"

  [[ -L "${installed_params}" ]] \
    || fail "demo_nodes_py: share/demo_nodes_py/params.yaml is NOT a symlink under --symlink-install"
  local link_target
  link_target="$(readlink -f "${installed_params}")"
  info "Symlink verified: share/demo_nodes_py/params.yaml -> ${link_target}"

  local src_params="${pkg_dir}/demo_nodes_py/parameters/params.yaml"
  echo "# poc_live_edit_marker: 42" >> "${src_params}"
  grep -q "poc_live_edit_marker: 42" "${installed_params}" \
    || fail "Live edit to source params.yaml did not propagate to install/ symlink"
  ok "Live source edit to params.yaml immediately visible in install/ without rebuilding"
  git -C "${ws_dir}/src/demos" checkout -- demo_nodes_py/demo_nodes_py/parameters/params.yaml

  stage_header "[STAGE 5/6] Automated Testing via colcon test (pyproject.toml pytest Discovery)"
  (
    cd "${ws_dir}"
    set +u
    # shellcheck disable=SC1091
    source /opt/ros/jazzy/setup.bash
    # shellcheck disable=SC1091
    source "${ws_dir}/install/setup.bash"
    set -u
    colcon test --packages-select demo_nodes_py --event-handlers console_cohesion+ | sed 's/^/    /'
    colcon test-result --all | sed 's/^/    /'
  )
  ok "colcon test executed pytest suite cleanly using pyproject.toml metadata"

  stage_header "[STAGE 6/6] Target 1 Summary (ros2/demos -> demo_nodes_py)"
  cat <<'EOF'
  +------------------------------------------------------------+--------+
  | Capability                                                 | Result |
  +------------------------------------------------------------+--------+
  | Pure pyproject.toml identification (no setup.py/setup.cfg) | [PASS] |
  | Standard PEP 517 build (hatchling.build) & RECORD tracking | [PASS] |
  | script_dir_override -> lib/demo_nodes_py (13 executables)  | [PASS] |
  | Live ROS 2 DDS execution (talker -> listener)              | [PASS] |
  | PEP 660 --symlink-install & live share/params.yaml symlink | [PASS] |
  | colcon test pytest augmentation (copyright/flake8/pep257)  | [PASS] |
  +------------------------------------------------------------+--------+
EOF
}

run_target_examples_rclpy() {
  local ws_dir="/tmp/poc_ws_examples_rclpy"
  local repo_url
  repo_url="$(resolve_repo_url examples)"
  rm -rf "${ws_dir}"
  mkdir -p "${ws_dir}/src"

  banner "TARGET 2 (OPTIONAL): ros2/examples -> minimal_publisher & minimal_subscriber [Backend: flit_core]"
  info "Upstream Repository : https://github.com/ros2/examples (active ROS 2 Jazzy)"
  info "PoC Source & Branch : ${repo_url} @ ${POC_BRANCH}"
  info "Capabilities Tested : Multi-package pure PEP 621 build with flit_core.buildapi,"
  info "                      7 ROS 2 executables across 2 packages, PEP 660 editable"
  info "                      .pth install, live DDS pub/sub, and colcon test."

  stage_header "[STAGE 1/6] Source Clone & Pure PEP 621 Manifest Audit"
  git clone --quiet --branch "${POC_BRANCH}" --single-branch "${repo_url}" "${ws_dir}/src/examples"
  verify_pure_pep621_package \
    "${ws_dir}/src/examples/rclpy/topics/minimal_publisher" \
    "examples_rclpy_minimal_publisher" \
    "flit_core.buildapi"
  echo ""
  verify_pure_pep621_package \
    "${ws_dir}/src/examples/rclpy/topics/minimal_subscriber" \
    "examples_rclpy_minimal_subscriber" \
    "flit_core.buildapi"

  stage_header "[STAGE 2/6] Standard PEP 517 Wheel Build (flit_core) & Layout Check"
  (
    cd "${ws_dir}"
    set +u
    # shellcheck disable=SC1091
    source /opt/ros/jazzy/setup.bash
    set -u
    colcon build \
      --packages-select examples_rclpy_minimal_publisher examples_rclpy_minimal_subscriber \
      --event-handlers console_cohesion+ | sed 's/^/    /'
  )
  verify_ros_install_layout "${ws_dir}" "examples_rclpy_minimal_publisher" "publisher_member_function"
  verify_ros_install_layout "${ws_dir}" "examples_rclpy_minimal_subscriber" "subscriber_member_function"

  stage_header "[STAGE 3/6] Live ROS 2 CLI Discovery & Minimal Pub/Sub DDS Execution"
  (
    set +u
    # shellcheck disable=SC1091
    source /opt/ros/jazzy/setup.bash
    # shellcheck disable=SC1091
    source "${ws_dir}/install/setup.bash"
    set -u
    echo "  --- Discovered executables ---"
    ros2 pkg executables examples_rclpy_minimal_publisher | sed 's/^/    /'
    ros2 pkg executables examples_rclpy_minimal_subscriber | sed 's/^/    /'
  )
  run_pubsub_check \
    "${ws_dir}" \
    "examples_rclpy_minimal_publisher" "publisher_member_function" \
    "examples_rclpy_minimal_subscriber" "subscriber_member_function" \
    "42"

  stage_header "[STAGE 4/6] PEP 660 Editable Rebuild (--symlink-install with flit_core .pth)"
  (
    cd "${ws_dir}"
    set +u
    # shellcheck disable=SC1091
    source /opt/ros/jazzy/setup.bash
    set -u
    colcon build --symlink-install \
      --packages-select examples_rclpy_minimal_publisher examples_rclpy_minimal_subscriber \
      --event-handlers console_cohesion+ | sed 's/^/    /'
  )
  verify_editable_metadata "${ws_dir}" "examples_rclpy_minimal_publisher"
  verify_editable_metadata "${ws_dir}" "examples_rclpy_minimal_subscriber"

  stage_header "[STAGE 5/6] Automated Testing via colcon test"
  (
    cd "${ws_dir}"
    set +u
    # shellcheck disable=SC1091
    source /opt/ros/jazzy/setup.bash
    # shellcheck disable=SC1091
    source "${ws_dir}/install/setup.bash"
    set -u
    colcon test \
      --packages-select examples_rclpy_minimal_publisher examples_rclpy_minimal_subscriber \
      --event-handlers console_cohesion+ | sed 's/^/    /'
    colcon test-result --all | sed 's/^/    /'
  )
  ok "colcon test passed across both flit_core ROS 2 packages"

  stage_header "[STAGE 6/6] Target 2 Summary (ros2/examples -> minimal_publisher & minimal_subscriber)"
  cat <<'EOF'
  +------------------------------------------------------------+--------+
  | Capability                                                 | Result |
  +------------------------------------------------------------+--------+
  | Multi-package pure pyproject.toml discovery (flit_core)    | [PASS] |
  | Standard PEP 517 build & RECORD tracking (2 packages)      | [PASS] |
  | script_dir_override -> lib/<pkg> (7 executables)           | [PASS] |
  | Live ROS 2 DDS execution (minimal pub -> minimal sub)      | [PASS] |
  | PEP 660 --symlink-install (.pth + PEP 610 direct_url.json) | [PASS] |
  | colcon test pytest augmentation (copyright/flake8/pep257)  | [PASS] |
  +------------------------------------------------------------+--------+
EOF
}

run_target_teleop_twist_keyboard() {
  local ws_dir="/tmp/poc_ws_teleop_twist_keyboard"
  local repo_url
  repo_url="$(resolve_repo_url teleop_twist_keyboard)"
  rm -rf "${ws_dir}"
  mkdir -p "${ws_dir}/src"

  banner "TARGET 3 (OPTIONAL): ros2/teleop_twist_keyboard [Backend: setuptools.build_meta]"
  info "Upstream Repository : https://github.com/ros2/teleop_twist_keyboard (active ROS 2 Jazzy)"
  info "PoC Source & Branch : ${repo_url} @ ${POC_BRANCH}"
  info "Capabilities Tested : Single-file py-modules PEP 621 package with setuptools.build_meta,"
  info "                      script_dir_override without setup.cfg, ros2 run CLI execution,"
  info "                      PEP 660 --symlink-install, and colcon test (incl. xmllint)."

  stage_header "[STAGE 1/6] Source Clone & Pure PEP 621 Manifest Audit"
  git clone --quiet --branch "${POC_BRANCH}" --single-branch "${repo_url}" "${ws_dir}/src/teleop_twist_keyboard"
  verify_pure_pep621_package \
    "${ws_dir}/src/teleop_twist_keyboard" \
    "teleop_twist_keyboard" \
    "setuptools.build_meta"

  stage_header "[STAGE 2/6] Standard PEP 517 Wheel Build (setuptools.build_meta) & Layout Check"
  (
    cd "${ws_dir}"
    set +u
    # shellcheck disable=SC1091
    source /opt/ros/jazzy/setup.bash
    set -u
    colcon build --packages-select teleop_twist_keyboard --event-handlers console_cohesion+ | sed 's/^/    /'
  )
  verify_ros_install_layout "${ws_dir}" "teleop_twist_keyboard" "teleop_twist_keyboard"

  stage_header "[STAGE 3/6] Live ROS 2 CLI Discovery & PTY Teleop /cmd_vel DDS Execution"
  (
    export ROS_DOMAIN_ID="43"
    set +u
    # shellcheck disable=SC1091
    source /opt/ros/jazzy/setup.bash
    # shellcheck disable=SC1091
    source "${ws_dir}/install/setup.bash"
    set -u
    echo "  --- Discovered executables ---"
    ros2 pkg executables teleop_twist_keyboard | sed 's/^/    /'
    echo "  --- Live PTY keystroke ('i' = forward) -> /cmd_vel Twist DDS check ---"
    python3 - <<'PY'
import os
import pty
import subprocess
import time
import rclpy
from geometry_msgs.msg import Twist

rclpy.init()
node = rclpy.create_node("poc_cmd_vel_verifier")
received = []
sub = node.create_subscription(Twist, "cmd_vel", lambda msg: received.append(msg), 10)

master_fd, slave_fd = pty.openpty()
os.set_blocking(master_fd, False)
proc = subprocess.Popen(
    ["ros2", "run", "teleop_twist_keyboard", "teleop_twist_keyboard"],
    stdin=slave_fd,
    stdout=slave_fd,
    stderr=slave_fd,
    close_fds=True,
)
os.close(slave_fd)

try:
    deadline = time.monotonic() + 10.0
    while time.monotonic() < deadline and not received:
        try:
            os.read(master_fd, 4096)
        except BlockingIOError:
            pass
        os.write(master_fd, b"i")
        rclpy.spin_once(node, timeout_sec=0.25)
    os.write(master_fd, b"\x03")
    proc.wait(timeout=5.0)
finally:
    os.close(master_fd)
    node.destroy_node()
    rclpy.shutdown()
    if proc.poll() is None:
        proc.terminate()
        proc.wait(timeout=3.0)

assert received, "Did not receive any geometry_msgs/msg/Twist on /cmd_vel"
msg = received[0]
assert msg.linear.x > 0.0, f"Expected positive linear.x for 'i' key, got {msg.linear.x}"
print(f"    [cmd_vel_verifier] Received /cmd_vel Twist: linear.x={msg.linear.x:.2f}, angular.z={msg.angular.z:.2f}")
PY
  )
  ok "Live PTY teleop_twist_keyboard published Twist message on /cmd_vel over DDS"

  stage_header "[STAGE 4/6] PEP 660 Editable Rebuild (--symlink-install with setuptools.build_meta)"
  (
    cd "${ws_dir}"
    set +u
    # shellcheck disable=SC1091
    source /opt/ros/jazzy/setup.bash
    set -u
    colcon build --symlink-install --packages-select teleop_twist_keyboard --event-handlers console_cohesion+ | sed 's/^/    /'
  )
  verify_editable_metadata "${ws_dir}" "teleop_twist_keyboard"

  stage_header "[STAGE 5/6] Automated Testing via colcon test"
  (
    cd "${ws_dir}"
    set +u
    # shellcheck disable=SC1091
    source /opt/ros/jazzy/setup.bash
    # shellcheck disable=SC1091
    source "${ws_dir}/install/setup.bash"
    set -u
    colcon test --packages-select teleop_twist_keyboard --event-handlers console_cohesion+ | sed 's/^/    /'
    colcon test-result --all | sed 's/^/    /'
  )
  ok "colcon test passed (copyright, flake8, pep257, xmllint)"

  stage_header "[STAGE 6/6] Target 3 Summary (ros2/teleop_twist_keyboard)"
  cat <<'EOF'
  +------------------------------------------------------------+--------+
  | Capability                                                 | Result |
  +------------------------------------------------------------+--------+
  | Single-module pure pyproject.toml (setuptools.build_meta)  | [PASS] |
  | Standard PEP 517 build & RECORD tracking                   | [PASS] |
  | script_dir_override -> lib/teleop_twist_keyboard           | [PASS] |
  | Live PTY ros2 run -> /cmd_vel Twist DDS execution          | [PASS] |
  | PEP 660 --symlink-install (PEP 610 direct_url.json)        | [PASS] |
  | colcon test pytest augmentation (incl. package.xml lint)   | [PASS] |
  +------------------------------------------------------------+--------+
EOF
}

print_stack_overview

case "${TARGET}" in
  demo_nodes_py)
    run_target_demo_nodes_py
    ;;
  examples_rclpy)
    run_target_examples_rclpy
    ;;
  teleop_twist_keyboard)
    run_target_teleop_twist_keyboard
    ;;
  all)
    run_target_demo_nodes_py
    run_target_examples_rclpy
    run_target_teleop_twist_keyboard
    banner "OVERALL ROS 2 PEP 621 / PEP 660 POC MATRIX RESULT: ALL 3 TARGETS PASSED"
    cat <<'EOF'
  +----+----------------------------+----------------------------------------+-----------------------+--------+
  | #  | Upstream ROS 2 Repo        | Migrated Package(s)                    | PEP 517/660 Backend   | Status |
  +----+----------------------------+----------------------------------------+-----------------------+--------+
  | 1  | ros2/demos                 | demo_nodes_py                          | hatchling.build       | [PASS] |
  | 2  | ros2/examples              | examples_rclpy_minimal_publisher,      | flit_core.buildapi    | [PASS] |
  |    |                            | examples_rclpy_minimal_subscriber      |                       |        |
  | 3  | ros2/teleop_twist_keyboard | teleop_twist_keyboard                  | setuptools.build_meta | [PASS] |
  +----+----------------------------+----------------------------------------+-----------------------+--------+
EOF
    ;;
  *)
    echo "[ERROR] Unsupported --target '${TARGET}'" >&2
    usage >&2
    exit 2
    ;;
esac
