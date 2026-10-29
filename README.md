# colcon-roadmap: Native Standard Python Builds (PEP 517/518/621/660)

This repository orchestrates the engineering, verification, and upstream integration roadmap for bringing modern Python packaging standards (PEP 517, PEP 518, PEP 621, PEP 660) natively into [`colcon-core`](https://github.com/colcon/colcon-core) and [`colcon-ros`](https://github.com/colcon/colcon-ros).

---

## Project Overview & Status

Direct invocation of `setup.py install` / `develop` has been deprecated across the Python ecosystem. This initiative replaces legacy shims and prototype extensions (`colcon-python-project`) by establishing native, in-process wheel handling and metadata-driven packaging across `colcon-core` and `colcon-ros`.

### Completed & Active Milestones (Stages 1–3)

* **Foundations Merged Upstream (`colcon-core` `v0.21.2` / `v0.21.3`)** -> **MERGED** ([colcon/colcon-core#728](https://github.com/colcon/colcon-core/pull/728) `InstalledDistribution`, [colcon/colcon-core#732](https://github.com/colcon/colcon-core/pull/732) `AsyncHookCaller`, [colcon/colcon-core#741](https://github.com/colcon/colcon-core/pull/741) `install_wheel` & `remove_distributions`).
* **Stage 1: Core PEP 621 Support & Multi-Backend Integration Tests (`colcon-core`)** -> **SUBMITTED ([colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750))** (Commit `4a594c8` targeting `cottsay/pep621`; `run_until_complete` async test alignment + `flit_core` / `hatchling` integration suite).
* **Stage 2: Backend-Scoped Editable Data Files & Script Override (`colcon-core`)** -> **DRAFT PR VERIFIED ([colcon/colcon-core#751](https://github.com/colcon/colcon-core/pull/751))** (Commit `463df5f`; **46/46 GitHub Actions CI checks passing**, `256 passed, 5 skipped` locally).
* **Stage 3: ROS 2 `ament_python` Native `pyproject.toml` Support (`colcon-ros`)** -> **DRAFT PR VERIFIED ([colcon/colcon-ros#171](https://github.com/colcon/colcon-ros/pull/171))** (Commit `359ab5c`; `ros2 run` `lib/<pkg>` script override, flat `additional_hooks`, `RECORD`-tracked `ament_index` & `package.xml`, and `colcon test` augmentation; **16/16 `pytest --cov --cov-branch` checks passing** + **4/4 mock scenarios verified**).
* **Final Phase PoC: Dockerized ROS 2 Jazzy Multi-Backend Showcase ([`poc/`](poc/README.md))** -> **IMPLEMENTED & VERIFIED** (Builds, runs via `ros2 run` with live DDS pub/sub, tests `--symlink-install` PEP 660 editable symlinks, and executes `colcon test` across official `ros2/*` packages migrated to pure `pyproject.toml` using `hatchling`, `flit_core`, and `setuptools.build_meta`).

### Planned Follow-Up Stages (Stages 4–5)

* **Stage 4 (Group A — Targets `colcon-core:master` Directly)**:
  - **4B (`SetuptoolsDecorator`)**: Scratch `--build-base` / `--egg-base` isolation so `setuptools.build_meta` builds do not write `.egg-info/` into the source tree.
  - **4D (Wheel `script_dir` & Windows Symlink Resilience)**: Ensure `script_dir.mkdir(parents=True, exist_ok=True)` in `install_wheel` for cached `ScriptMaker` instances after `remove_distributions`, plus graceful copy fallback on unprivileged Windows symlink installs.
* **Stage 4 (Group B — Stacked on `cottsay/pep621` / `#750`)**:
  - **4A (`PythonProjectTestTask`)**: Register `python.project` under `colcon_core.task.test` for `colcon test`.
  - **4C (Dynamic Metadata Hook)**: Connect `PEP621PackageAugmentation` to `load_and_cache_metadata` (`prepare_metadata_for_build_wheel`) when `project.dynamic` fields are declared.
* **Stage 5: Prototype Deprecation (`colcon-python-project`)** -> **PLANNED POST-MERGE**.

---

## Documentation Index

| Document | Purpose |
| :--- | :--- |
| **[Current Status](current_status.md)** | Technical analysis of merged PRs (#728, #732, #741), open/draft PRs (#750, #751, #171), verification metrics, and remaining roadmap. |
| **[Action Plan & Next Steps](action_plan_next_steps.md)** | Step-by-step execution record for Phases 1–5 and implementation plan for Stages 4–5 (Phases 6–7). |
| **[Roadmap](roadmap.md)** | Architectural evolution, feature flags, delivered feature branches, and Stage 4/5 queue. |
| **[Pitfalls & Remediation Plan](docs/plans/pitfalls_and_remediation_plan.md)** | Audit of 10 architectural pitfalls (`ros2 run`, `colcon test`, data-files parity, `ScriptMaker` cache, etc.) and staged PR remediation matrix. |
| **[Implemented Results Summary (Gist)](https://gist.github.com/KmoM88/0357abff37b5a32ab801cac7d399d4ed)** | Published results summary of merged foundations, delivered PRs, and ROS 2 Jazzy PoC validation ([docs/proposals/pep621_pep660_upstream_proposal.md](docs/proposals/pep621_pep660_upstream_proposal.md)). |
| **[Dockerized ROS 2 Jazzy PoC](poc/README.md)** | Reproducible 6-stage Docker PoC building and running official `ros2/*` packages (`demo_nodes_py`, `examples_rclpy_minimal_*`, `teleop_twist_keyboard`) with pure `pyproject.toml`. |
| **[Migration Instructions](migration_instructions.md)** | Transition strategy from `colcon-python-project` to native `colcon-core`. |

---

## Pull Request Submissions & Materials

### 1. `colcon-core` Core PEP 621 Support (Stage 1)
* **PR**: [colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750)
* **Target**: `colcon/colcon-core:cottsay/pep621` <- `KmoM88:feature/pep621-upstream-pr` (`4a594c8`)
* **Artifacts**: [docs/pr/pr_description_pep621.md](docs/pr/pr_description_pep621.md), [docs/pr/issue_736_comment.md](docs/pr/issue_736_comment.md), [docs/pr/pr_750_priority_comment.md](docs/pr/pr_750_priority_comment.md)
* **Compare URL**: [colcon/colcon-core:cottsay/pep621...KmoM88:colcon-core:feature/pep621-upstream-pr](https://github.com/colcon/colcon-core/compare/cottsay/pep621...KmoM88:colcon-core:feature/pep621-upstream-pr)

### 2. `colcon-core` Backend-Scoped Editable Data Files & Script Override (Stage 2)
* **PR**: [colcon/colcon-core#751](https://github.com/colcon/colcon-core/pull/751) (Draft — **46/46 CI checks green**)
* **Target**: `colcon/colcon-core:master` <- `KmoM88:feature/pep660-editable-data-files` (`463df5f`)
* **Artifact**: [docs/pr/pr_description_pep660_data_files.md](docs/pr/pr_description_pep660_data_files.md)
* **Compare URL**: [colcon/colcon-core:master...KmoM88:colcon-core:feature/pep660-editable-data-files](https://github.com/colcon/colcon-core/compare/master...KmoM88:colcon-core:feature/pep660-editable-data-files)

### 3. `colcon-ros` PEP 621 `ament_python` Support (Stage 3)
* **PR**: [colcon/colcon-ros#171](https://github.com/colcon/colcon-ros/pull/171) (Draft — **16/16 `pytest` checks green**)
* **Target**: `colcon/colcon-ros:master` <- `KmoM88:feature/ros-ament-python-project` (`359ab5c`)
* **Artifact**: [docs/pr/pr_description_colcon_ros.md](docs/pr/pr_description_colcon_ros.md)
* **Compare URL**: [colcon/colcon-ros:master...KmoM88:colcon-ros:feature/ros-ament-python-project](https://github.com/colcon/colcon-ros/compare/master...KmoM88:colcon-ros:feature/ros-ament-python-project)

---

## Verification & Linters

* **`colcon-core`**: Full suite passing (`256 passed, 5 skipped`, including unit, multi-backend integration, `flake8`, `scspell3k`, and copyright checks); **46/46 GitHub Actions checks green** on PR #751.
* **`colcon-ros`**: Full suite passing (`16 passed` under `pytest --cov --cov-branch`, including unit, `flit_core` integration, `flake8`, `scspell3k`, and copyright checks) on PR #171.
* **End-to-End Mock Workspace**: All 4 scenarios passing in `scripts/test_mock_packages.py`.

---

## Hands-On Mock Packages & Walkthrough Guide

A suite of mock packages and an automated verification runner exercise all four packaging modes end-to-end:

* **Comprehensive Guide**: [docs/guide/mock_packages_walkthrough.md](docs/guide/mock_packages_walkthrough.md)
* **Mock Packages**: [examples/mock_packages/](examples/mock_packages/)
  - `01_classic_setup_py`: Legacy `setup.py` / `setup.cfg` build lifecycle and egg-info generation.
  - `02_modern_pep621_flit`: Pure PEP 621 with `flit_core`, in-process wheel extraction, and CLI wrappers in `bin/`.
  - `03_modern_editable_data_files`: Backend-scoped PEP 660 `--symlink-install` with `hatchling` `shared-data` (copied in standard builds, live OS symlinks in `--symlink-install`).
  - `04_ros2_ament_pyproject`: Modern ROS 2 `ament_python` package without `setup.py`, installing executables into `lib/ros_pyproject_pkg/` (`ros2 run` path), tracking `ament_index` and `package.xml` in `.dist-info/RECORD`, and exposing `pytest` dependencies for `colcon test`.
* **Run Demonstration Script**:
  ```bash
  submodules/colcon-ros/.venv/bin/python3 scripts/test_mock_packages.py
  ```

---

## Dockerized ROS 2 Jazzy Proof of Concept (`poc/`)

A self-contained Dockerized PoC under [`poc/`](poc/README.md) validates real, active **`ros2/*`** packages migrated to pure PEP 621 `pyproject.toml` (`setup.py` and `setup.cfg` deleted) across six human-readable verification stages (manifest audit, standard PEP 517 build & `RECORD` check, live `ros2 run` DDS node execution, PEP 660 `--symlink-install` live `share/` data-file edit check, `colcon test`, and stage summary):

* **Primary Target (`demo_nodes_py`)**: [`ros2/demos`](https://github.com/ros2/demos) (`hatchling.build` — 13 nodes, `share/demo_nodes_py/params.yaml` live symlink, live `talker`/`listener` DDS pub/sub, `colcon test`).
* **Optional Target 2 (`examples_rclpy`)**: [`ros2/examples`](https://github.com/ros2/examples) (`flit_core.buildapi` — `examples_rclpy_minimal_publisher` & `examples_rclpy_minimal_subscriber` live DDS pub/sub, `colcon test`).
* **Optional Target 3 (`teleop_twist_keyboard`)**: [`ros2/teleop_twist_keyboard`](https://github.com/ros2/teleop_twist_keyboard) (`setuptools.build_meta` — single-file `py-modules` node, live PTY keystroke -> `/cmd_vel` `Twist` DDS verification via `ros2 run`, `colcon test`).

```bash
# Run primary target (demo_nodes_py)
./poc/run_poc.sh

# Run full 3-backend ROS 2 PoC matrix
./poc/run_poc.sh --target all
```
