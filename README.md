# colcon-roadmap: Native Standard Python Builds (PEP 517/518/621/660)

This repository orchestrates the engineering, verification, and upstream integration roadmap for bringing modern Python packaging standards (PEP 517, PEP 518, PEP 621, PEP 660) natively into [`colcon-core`](https://github.com/colcon/colcon-core) and [`colcon-ros`](https://github.com/colcon/colcon-ros).

---

## Project Overview & Status

Direct invocation of `setup.py install` / `develop` has been deprecated across the Python ecosystem. This initiative replaces legacy shims and prototype extensions (`colcon-python-project`) by establishing native, in-process wheel handling and metadata-driven packaging across `colcon-core` and `colcon-ros`.

### Completed & Active Milestones (Stages 1–4)

* **Foundations Merged Upstream (`colcon-core` `v0.21.2` / `v0.21.3`)** -> **MERGED** ([colcon/colcon-core#728](https://github.com/colcon/colcon-core/pull/728) `InstalledDistribution`, [colcon/colcon-core#732](https://github.com/colcon/colcon-core/pull/732) `AsyncHookCaller`, [colcon/colcon-core#741](https://github.com/colcon/colcon-core/pull/741) `install_wheel` & `remove_distributions`).
* **Stage 1: Core PEP 621 Support & Multi-Backend Integration Tests (`colcon-core`)** -> **SUBMITTED ([colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750))** (Commit `4a594c8` targeting `cottsay/pep621`; `run_until_complete` async test alignment + `flit_core` / `hatchling` integration suite).
* **Stage 2: Backend-Scoped Editable Data Files & Script Override (`colcon-core`)** -> **DRAFT PR VERIFIED ([colcon/colcon-core#751](https://github.com/colcon/colcon-core/pull/751))** (Commit `463df5f`; **46/46 GitHub Actions CI checks passing**, `256 passed, 5 skipped` locally).
* **Stage 3: ROS 2 `ament_python` Native `pyproject.toml` Support (`colcon-ros`)** -> **DRAFT PR VERIFIED ([colcon/colcon-ros#171](https://github.com/colcon/colcon-ros/pull/171))** (Commit `359ab5c`; `ros2 run` `lib/<pkg>` script override, flat `additional_hooks`, `RECORD`-tracked `ament_index` & `package.xml`, and `colcon test` augmentation; **16/16 `pytest --cov --cov-branch` checks passing** + **4/4 mock scenarios verified**).
* **Stage 4 — Group A & Group B Single-Concern Follow-Up Branches (`KmoM88/colcon-core`)** -> **IMPLEMENTED, PUSHED TO FORK & CI-VERIFIED ([KmoM88/colcon-core#5](https://github.com/KmoM88/colcon-core/pull/5))** (Pushed to `KmoM88/colcon-core` without opening upstream PRs on `colcon/colcon-core`; validated end-to-end across **44/44 GitHub Actions matrix jobs** in run [40802478808](https://github.com/KmoM88/colcon-core/actions/runs/40802478808) and `272 passed, 5 skipped` locally; branch specifications in [docs/plans/stage4_branch_plan.md](docs/plans/stage4_branch_plan.md)):
  - **Group A — 4B ([`feature/setuptools-decorator`](https://github.com/KmoM88/colcon-core/tree/feature/setuptools-decorator) @ `bdf5077`, off `master` `6bfb100`)**: Scratch `--build-base` / `--egg-base` isolation for `setuptools.build_meta` + `colcon_core.python_project.hook_caller_decorator` registration in `setup.cfg`.
  - **Group A — 4D ([`feature/wheel-script-dir-and-windows-symlink`](https://github.com/KmoM88/colcon-core/tree/feature/wheel-script-dir-and-windows-symlink) @ `85a79ae`, off `master` `6bfb100`)**: `script_dir.mkdir(parents=True, exist_ok=True)` in `install_wheel` for cached `ScriptMaker` rebuilds after `remove_distributions()`, plus Windows symlink privilege fallback (`winerror 1314`).
  - **Group B — 4A ([`feature/python-project-test-task`](https://github.com/KmoM88/colcon-core/tree/feature/python-project-test-task) @ `d4b93bc`, off `feature/pep621-upstream-pr` `4a594c8`)**: `PythonProjectTestTask` registered under `colcon_core.task.test` + static PEP 621 / PEP 735 `get_python_setup_options` augmentation for `colcon test`.
  - **Group B — 4C ([`feature/pep621-dynamic-metadata`](https://github.com/KmoM88/colcon-core/tree/feature/pep621-dynamic-metadata) @ `49fcded`, off `feature/pep621-upstream-pr` `4a594c8`)**: Dynamic PEP 621 metadata resolution via `load_and_cache_metadata` with PEP 517 `build_wheel` fallback when optional `prepare_metadata_for_build_wheel` is absent.
* **Final Phase PoC: Dockerized & GitHub Actions ROS 2 Jazzy Multi-Backend Showcase ([`poc/`](poc/README.md))** -> **IMPLEMENTED & VERIFIED** (Builds, runs via `ros2 run` with live DDS pub/sub, tests `--symlink-install` PEP 660 editable symlinks, and executes `colcon test` across official `ros2/*` packages migrated to pure `pyproject.toml` on branch `poc/pep621-ament-python` using `hatchling`, `flit_core`, and `setuptools.build_meta`; verified locally and on GitHub Actions via [`.github/workflows/ros2_pep621_poc.yml`](.github/workflows/ros2_pep621_poc.yml) in run [40795039655](https://github.com/KmoM88/colcon-roadmap/actions/runs/40795039655)).

### Planned Post-Merge Stage (Stage 5 — Planned Only, No Implementation)

* **Stage 5: Prototype Deprecation (`colcon-python-project`)** -> **PLANNED ONLY — NO IMPLEMENTATION** (Post-release plan in [docs/release_plan/stages/stage5_colcon_python_project_deprecation.md](docs/release_plan/stages/stage5_colcon_python_project_deprecation.md) to archive `colcon/colcon-python-project` and close prototype PR #1 only after Stages 1–4 merge and ship upstream).

---

## Documentation Index

| Document | Purpose |
| :--- | :--- |
| **[PR, Branch, Feature & Release Plan](docs/release_plan/README.md)** | **Master Hub**: End-to-end PR & release wave plan linking every feature branch (decisions, solution, validation) and per-stage leaf specifications under [`docs/release_plan/stages/`](docs/release_plan/README.md). |
| **[Historic PRs & Prototype Reference](docs/release_plan/historic_prs_reference.md)** | Reference summary of `colcon-python-project#1`, issue `#736`, merged foundations (`#728`, `#732`, `#741`), and upstream `cottsay/pep621` (`80acf29`). |
| **[Current Status](current_status.md)** | Technical analysis of merged PRs (#728, #732, #741), open/draft PRs (#750, #751, #171), Stage 4 fork CI metrics, PoC verification, and remaining roadmap. |
| **[Action Plan & Next Steps](action_plan_next_steps.md)** | Step-by-step execution record for Phases 1–6 + ROS 2 Jazzy PoC, and planned-only Stage 5 deprecation gate (Phase 7). |
| **[Roadmap](roadmap.md)** | Architectural evolution, feature flags, delivered feature branches, and Stage 4 Group A / Group B summary. |
| **[Stage 4 Branch Implementation Record](docs/plans/stage4_branch_plan.md)** | Branch-by-branch design, commit SHAs, file changes, edge cases, and fork CI results for Stage 4 Group A (`master`) and Stage 4 Group B (`#750`). |
| **[Pitfalls & Remediation Plan](docs/plans/pitfalls_and_remediation_plan.md)** | Audit of 10 architectural pitfalls (`ros2 run`, `colcon test`, data-files parity, `ScriptMaker` cache, etc.) and staged PR remediation matrix. |
| **[Implemented Results Summary (Gist)](https://gist.github.com/KmoM88/0357abff37b5a32ab801cac7d399d4ed)** | Published results-only summary of merged foundations, delivered PRs, Stage 4 fork CI validation, and ROS 2 Jazzy PoC ([docs/proposals/pep621_pep660_upstream_proposal.md](docs/proposals/pep621_pep660_upstream_proposal.md)). |
| **[Dockerized ROS 2 Jazzy PoC](poc/README.md)** | Reproducible 6-stage Docker & GitHub Actions PoC building and running official `ros2/*` packages (`demo_nodes_py`, `examples_rclpy_minimal_*`, `teleop_twist_keyboard`) with pure `pyproject.toml`. |
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

### 4. `colcon-core` Follow-Up Branches & Fork-Local GitHub Actions Validation (Stage 4 — Group A & Group B)
* **Fork-Local CI Validation PR** *(no upstream draft PRs opened)*: [KmoM88/colcon-core#5](https://github.com/KmoM88/colcon-core/pull/5) (`KmoM88:master` <- `KmoM88:ci/stage4-all-validation` @ `32dd42a`) — **44/44 GitHub Actions matrix jobs green** in run [40802478808](https://github.com/KmoM88/colcon-core/actions/runs/40802478808)
* **Group A Branches (off `KmoM88/colcon-core:master` @ `6bfb100`)**:
  - [`feature/setuptools-decorator`](https://github.com/KmoM88/colcon-core/tree/feature/setuptools-decorator) (`bdf5077`) — [Fork Compare](https://github.com/KmoM88/colcon-core/compare/master...feature/setuptools-decorator)
  - [`feature/wheel-script-dir-and-windows-symlink`](https://github.com/KmoM88/colcon-core/tree/feature/wheel-script-dir-and-windows-symlink) (`85a79ae`) — [Fork Compare](https://github.com/KmoM88/colcon-core/compare/master...feature/wheel-script-dir-and-windows-symlink)
* **Group B Branches (off `KmoM88/colcon-core:feature/pep621-upstream-pr` @ `4a594c8`)**:
  - [`feature/python-project-test-task`](https://github.com/KmoM88/colcon-core/tree/feature/python-project-test-task) (`d4b93bc`) — [Fork Compare](https://github.com/KmoM88/colcon-core/compare/feature/pep621-upstream-pr...feature/python-project-test-task)
  - [`feature/pep621-dynamic-metadata`](https://github.com/KmoM88/colcon-core/tree/feature/pep621-dynamic-metadata) (`49fcded`) — [Fork Compare](https://github.com/KmoM88/colcon-core/compare/feature/pep621-upstream-pr...feature/pep621-dynamic-metadata)
* **Design & Verification Blueprint**: [docs/plans/stage4_branch_plan.md](docs/plans/stage4_branch_plan.md)

---

## Verification & Linters

* **`colcon-core`**: Full suite passing (`256 passed, 5 skipped` on Stage 2 PR #751; `272 passed, 5 skipped` across all combined Stage 1 + Stage 2 + Stage 4 branches, including unit, multi-backend integration, `flake8`, `scspell3k`, and copyright checks); **46/46 GitHub Actions checks green** on upstream Draft PR #751 and **44/44 GitHub Actions matrix jobs green** on fork validation PR [KmoM88/colcon-core#5](https://github.com/KmoM88/colcon-core/pull/5) (run [40802478808](https://github.com/KmoM88/colcon-core/actions/runs/40802478808)).
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

* **Primary Target (`demo_nodes_py`)**: [`ros2/demos`](https://github.com/ros2/demos) -> [`KmoM88/demos:poc/pep621-ament-python`](https://github.com/KmoM88/demos/tree/poc/pep621-ament-python) (`b249c6c`, `hatchling.build` — 13 nodes, `share/demo_nodes_py/params.yaml` live symlink, live `talker`/`listener` DDS pub/sub, `colcon test`).
* **Optional Target 2 (`examples_rclpy`)**: [`ros2/examples`](https://github.com/ros2/examples) -> [`KmoM88/examples:poc/pep621-ament-python`](https://github.com/KmoM88/examples/tree/poc/pep621-ament-python) (`8e0155f`, `flit_core.buildapi` — `examples_rclpy_minimal_publisher` & `examples_rclpy_minimal_subscriber` live DDS pub/sub, `colcon test`).
* **Optional Target 3 (`teleop_twist_keyboard`)**: [`ros2/teleop_twist_keyboard`](https://github.com/ros2/teleop_twist_keyboard) -> [`KmoM88/teleop_twist_keyboard:poc/pep621-ament-python`](https://github.com/KmoM88/teleop_twist_keyboard/tree/poc/pep621-ament-python) (`962e0e9`, `setuptools.build_meta` — single-file `py-modules` node, live PTY keystroke -> `/cmd_vel` `Twist` DDS verification via `ros2 run`, `colcon test`).
* **Manual GitHub Actions Workflow**: [`.github/workflows/ros2_pep621_poc.yml`](.github/workflows/ros2_pep621_poc.yml) — verified passing across `target=all` in run [40795039655](https://github.com/KmoM88/colcon-roadmap/actions/runs/40795039655).

```bash
# Run primary target locally (demo_nodes_py)
./poc/run_poc.sh

# Run full 3-backend ROS 2 PoC matrix locally
./poc/run_poc.sh --target all

# Trigger manual GitHub Actions workflow run
gh workflow run ros2_pep621_poc.yml -f target=all
```
