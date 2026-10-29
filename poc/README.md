# Dockerized ROS 2 Jazzy Proof of Concept (PEP 517 / 518 / 621 / 660)

This directory contains a self-contained Dockerized Proof of Concept (PoC) validating end-to-end builds, PEP 660 editable `--symlink-install` workflows, live ROS 2 DDS node execution, and `colcon test` discovery on official **`ros2/*`** packages migrated to pure standard `pyproject.toml` packaging (`setup.py` and `setup.cfg` deleted).

---

## 1. Modernized colcon Stack Inside the Image

[`Dockerfile`](Dockerfile) builds on `ros:jazzy-ros-core` (Ubuntu 24.04 Noble, Python 3.12) and installs our modernized `colcon` submodules into `/opt/colcon-venv` (`--system-site-packages`):

* **`colcon-core`** (`submodules/kmom88-colcon-core`, commit `463df5f` — [colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750) + [colcon/colcon-core#751](https://github.com/colcon/colcon-core/pull/751)):
  * Native `PEP621PackageIdentification`, `PEP621PackageAugmentation`, and `PythonProjectBuildTask`.
  * `script_dir_override` API routing entry-point wrappers without legacy `setup.cfg`.
  * Backend-scoped PEP 660 editable `share/` data-file symlinking and deduplicated `.dist-info/RECORD` tracking.
* **`colcon-ros`** (`submodules/colcon-ros`, commit `359ab5c` — [colcon/colcon-ros#171](https://github.com/colcon/colcon-ros/pull/171)):
  * Native `<build_type>ament_python</build_type>` builds driven purely by `pyproject.toml`.
  * Routes `[project.scripts]` executables to `install/<pkg>/lib/<pkg>/` for `ros2 run` and `ros2 pkg executables`.
  * Installs `ament_index` package markers, `share/<pkg>/package.xml`, and `ament_prefix_path` hooks, recording all installed paths in `.dist-info/RECORD`.
  * Augments `get_python_setup_options` from `pyproject.toml` so `colcon test` discovers `pytest`.

---

## 2. Active ROS 2 Targets (`ros2/*` Repositories Only)

Each target clones a migrated branch (`poc/pep621-ament-python`) of an active official `ros2/*` repository where `setup.py` and `setup.cfg` have been removed in favor of standard PEP 621 `pyproject.toml`, exercising all three major Python build backends:

| # | CLI `--target` | Upstream Repository & PoC Fork (`poc/pep621-ament-python`) | Migrated Package(s) | PEP 517/660 Backend | Highlighted Features |
| :- | :--- | :--- | :--- | :--- | :--- |
| **1 (Default)** | `demo_nodes_py` | [`ros2/demos`](https://github.com/ros2/demos) (`jazzy`)<br/>[`KmoM88/demos@b249c6c`](https://github.com/KmoM88/demos/tree/poc/pep621-ament-python) | `demo_nodes_py` | `hatchling.build` | 13 `[project.scripts]` ROS 2 nodes, `share/demo_nodes_py/params.yaml` wheel `.data/` & `--symlink-install` live symlink, live `talker`/`listener` DDS pub/sub, `colcon test` |
| **2 (Optional)** | `examples_rclpy` | [`ros2/examples`](https://github.com/ros2/examples) (`jazzy`)<br/>[`KmoM88/examples@8e0155f`](https://github.com/KmoM88/examples/tree/poc/pep621-ament-python) | `examples_rclpy_minimal_publisher`, `examples_rclpy_minimal_subscriber` | `flit_core.buildapi` | Multi-package pure PEP 621 build, 7 executables, PEP 660 `.pth` editable build, live minimal pub/sub DDS communication, `colcon test` |
| **3 (Optional)** | `teleop_twist_keyboard` | [`ros2/teleop_twist_keyboard`](https://github.com/ros2/teleop_twist_keyboard) (`jazzy`)<br/>[`KmoM88/teleop_twist_keyboard@962e0e9`](https://github.com/KmoM88/teleop_twist_keyboard/tree/poc/pep621-ament-python) | `teleop_twist_keyboard` | `setuptools.build_meta` | Single-file `py-modules` node without `setup.py`/`setup.cfg`, live PTY keystroke -> `/cmd_vel` `Twist` DDS verification via `ros2 run`, PEP 660 editable build, `colcon test` (incl. `ament_xmllint` on `package.xml` `<build_depend>`) |

---

## 3. Quick Start

Run the primary PoC target (`demo_nodes_py`):

```bash
./poc/run_poc.sh
```

Run an optional target or the full 3-backend ROS 2 matrix:

```bash
# Optional target 2: ros2/examples (flit_core)
./poc/run_poc.sh --target examples_rclpy

# Optional target 3: ros2/teleop_twist_keyboard (setuptools.build_meta)
./poc/run_poc.sh --target teleop_twist_keyboard

# Full matrix (all 3 active ros2/* targets sequentially)
./poc/run_poc.sh --target all
```

Reuse an already-built Docker image without rebuilding:

```bash
./poc/run_poc.sh --skip-image-build --target all
```

### Run Manually on GitHub Actions

You can also run the PoC on demand in GitHub Actions without a local Docker installation via [`.github/workflows/ros2_pep621_poc.yml`](../.github/workflows/ros2_pep621_poc.yml):

1. Open the repository **Actions** tab on GitHub and select **ROS 2 Jazzy PEP 621 / PEP 660 Proof of Concept**, then click **Run workflow** and choose `all`, `demo_nodes_py`, `examples_rclpy`, or `teleop_twist_keyboard` (or run `gh workflow run ros2_pep621_poc.yml -f target=all` from the CLI).
2. View the live stage-by-stage logs directly on the workflow **Summary** page and download the `ros2-jazzy-pep621-poc-<target>` log artifact (verified passing across `target=all` in run [40795039655](https://github.com/KmoM88/colcon-roadmap/actions/runs/40795039655)).

---

## 4. Six-Stage Verification Pipeline

For every selected target, [`container_poc.sh`](container_poc.sh) prints human-readable stage logs across six deterministic checks:

1. **`[STAGE 1/6]` Source Clone & Pure PEP 621 Manifest Audit**: Clones the target repository, asserts `package.xml` (`<build_type>ament_python</build_type>`) and `pyproject.toml` exist, asserts `setup.py` and `setup.cfg` are absent, and runs `colcon list`.
2. **`[STAGE 2/6]` Standard PEP 517 Wheel Build & ROS 2 FHS Layout Check**: Runs `colcon build`, verifies executables land in `install/<pkg>/lib/<pkg>/` (not `bin/`), verifies `ament_index`, `package.xml`, and `ament_prefix_path.sh`, and audits `.dist-info/RECORD` for zero duplicate entries.
3. **`[STAGE 3/6]` Live ROS 2 CLI Discovery & Runtime Node Execution**: Verifies `ros2 pkg prefix` and `ros2 pkg executables`, then executes live ROS 2 nodes via `ros2 run` (including live DDS `Hello World` message exchange between publisher and subscriber processes).
4. **`[STAGE 4/6]` PEP 660 Editable Rebuild (`--symlink-install`) & Live Data-File Symlink**: Rebuilds in place with `--symlink-install`, validates PEP 610 `direct_url.json` (`"editable": true`), verifies idempotent repeated rebuilds, and (for `demo_nodes_py`) modifies `params.yaml` in `src/` and asserts the change appears immediately in `install/demo_nodes_py/share/demo_nodes_py/params.yaml` without rebuilding.
5. **`[STAGE 5/6]` Automated Testing via `colcon test`**: Runs `colcon test` and `colcon test-result --all`, confirming `pytest` discovery from `pyproject.toml` and passing upstream linters (`ament_copyright`, `ament_flake8`, `ament_pep257`, `ament_xmllint`).
6. **`[STAGE 6/6]` Target Summary Report**: Prints a structured pass/fail capability table.
