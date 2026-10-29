# Roadmap: Native PEP 517/518/621/660 Support in colcon-core and colcon-ros

This roadmap tracks the delivery of modern Python packaging standards (PEP 517/518/621/660) across `colcon-core` and `colcon-ros`, replacing legacy `setup.py` invocations while maintaining backward compatibility with existing ROS and Python workspaces.

---

## 1. Context & Motivation

* **Standards Modernization**: The Python packaging ecosystem has deprecated direct invocations of `setup.py install` and `setup.py develop` in favor of standard build backends (Flit, Hatchling, Setuptools `build_meta`) declared in `pyproject.toml`.
* **Standardized Metadata**: Dependencies and package definitions are standardized in `pyproject.toml` (`[build-system]` and `[project]`).
* **Goal**: Provide native support in `colcon-core` and `colcon-ros` so Python and ROS 2 `ament_python` packages with standard `pyproject.toml` can be discovered, built, tested, installed, and uninstalled cleanly without external shims.

---

## 2. Merged Upstream Foundations (`colcon-core` `v0.21.2` / `v0.21.3`)

- [x] **PR #732: Hook Caller Infrastructure (`AsyncHookCaller`)**
  - Subprocess execution channel for backend hooks (`build_wheel`, `get_requires_for_build_wheel`) via OS pipes and pickle serialization.
  - Extension point `HookCallerDecoratorExtensionPoint`.
  - TOML parser loader (`load_and_cache_spec`) with standard `tomllib` (Python 3.11+) and fallbacks.

- [x] **PR #728: Distribution Metadata Discovery (`InstalledDistribution`)**
  - Live query and discovery of installed Python files, packages, namespaces, entry points, and bytecode caching (`.pyc`).

- [x] **PR #741: In-Process Wheel Installation & Uninstallation Engine (`wheel.py`)**
  - `remove_distributions`: Cleanly uninstalls previous package installations and prunes empty parent directories using disk metadata.
  - `install_wheel`: Unpacks `.whl` archives, maps `.data/` directories (e.g. `share/`), generates executable entry-point script wrappers via `distlib.scripts.ScriptMaker`, and writes PEP 376 `INSTALLER` and `RECORD` files.

---

## 3. Delivered Features & Active Pull Requests (Stages 1–4)

| Stage & Branch | Repository | Status | Focus & Deliverable |
| :--- | :--- | :--- | :--- |
| `cottsay/pep621` (`816a0d3`) | `KmoM88/colcon-core` | **Completed** | Aligned async test runner (`run_until_complete`), PEP 621 identification, augmentation & build task. |
| `feature/pep621-integration-tests` (`c40901a`) | `KmoM88/colcon-core` | **Completed** | Real multi-backend fixtures (`flit_core`, `hatchling`), CLI scripts, clean rebuilds. |
| **Stage 1**: `feature/pep621-upstream-pr` (`4a594c8`) | `KmoM88/colcon-core` | **PR #750 Submitted** | [colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750) targeting `cottsay/pep621`. |
| **Stage 2**: `feature/pep660-editable-data-files` (`463df5f`) | `KmoM88/colcon-core` | **PR #751 (Draft, 46/46 CI Green)** | [colcon/colcon-core#751](https://github.com/colcon/colcon-core/pull/751): Backend-scoped editable data files, `script_dir_override` + `$base` fix, deduplicated `RECORD` updates (`256 passed, 5 skipped`). |
| **Stage 3**: `feature/ros-ament-python-project` (`359ab5c`) | `KmoM88/colcon-ros` | **PR #171 (Draft, 16/16 pytest Green)** | [colcon/colcon-ros#171](https://github.com/colcon/colcon-ros/pull/171): `ament_python` `pyproject.toml` builds, `lib/<pkg>` script override for `ros2 run`, flat hooks, post-wheel `RECORD` tracking, and `colcon test` augmentation. |
| **Stage 4B (Group A)**: [`feature/setuptools-decorator`](https://github.com/KmoM88/colcon-core/tree/feature/setuptools-decorator) (`bdf5077`) | `KmoM88/colcon-core` | **Pushed & Fork-CI Green ([PR #5](https://github.com/KmoM88/colcon-core/pull/5))** | `SetuptoolsHookCallerDecoratorExtension` isolating `--build-base` / `--egg-base` + `hook_caller_decorator` registration in `setup.cfg`. |
| **Stage 4D (Group A)**: [`feature/wheel-script-dir-and-windows-symlink`](https://github.com/KmoM88/colcon-core/tree/feature/wheel-script-dir-and-windows-symlink) (`85a79ae`) | `KmoM88/colcon-core` | **Pushed & Fork-CI Green ([PR #5](https://github.com/KmoM88/colcon-core/pull/5))** | `script_dir.mkdir(parents=True, exist_ok=True)` in `wheel.py` for cached `ScriptMaker` rebuilds + Windows `winerror 1314` symlink copy fallback. |
| **Stage 4A (Group B)**: [`feature/python-project-test-task`](https://github.com/KmoM88/colcon-core/tree/feature/python-project-test-task) (`d4b93bc`) | `KmoM88/colcon-core` | **Pushed & Fork-CI Green ([PR #5](https://github.com/KmoM88/colcon-core/pull/5))** | `PythonProjectTestTask` registered under `colcon_core.task.test` + static PEP 621 / PEP 735 `get_python_setup_options`. |
| **Stage 4C (Group B)**: [`feature/pep621-dynamic-metadata`](https://github.com/KmoM88/colcon-core/tree/feature/pep621-dynamic-metadata) (`49fcded`) | `KmoM88/colcon-core` | **Pushed & Fork-CI Green ([PR #5](https://github.com/KmoM88/colcon-core/pull/5))** | `PEP621PackageAugmentation` dynamic metadata resolution via `load_and_cache_metadata` + PEP 517 `build_wheel` fallback. |
| **Final Phase PoC**: [`poc/`](poc/README.md) & [`.github/workflows/ros2_pep621_poc.yml`](.github/workflows/ros2_pep621_poc.yml) | `KmoM88/colcon-roadmap` + `KmoM88/{demos,examples,teleop_twist_keyboard}` | **Implemented & Verified ([Run 40795039655](https://github.com/KmoM88/colcon-roadmap/actions/runs/40795039655))** | Dockerized & GitHub Actions ROS 2 Jazzy 6-stage showcase across active `ros2/*` packages migrated to pure `pyproject.toml` (`hatchling`, `flit_core`, `setuptools.build_meta`). |

> [!IMPORTANT]
> * The master **PR, Branch, Feature & Release Plan** (with per-stage leaf specifications and historic PR reference) is maintained in **[docs/release_plan/README.md](docs/release_plan/README.md)** and **[docs/release_plan/historic_prs_reference.md](docs/release_plan/historic_prs_reference.md)**.
> * The full technical audit of 10 architectural pitfalls and their staged PR remediation matrix is maintained in **[docs/plans/pitfalls_and_remediation_plan.md](docs/plans/pitfalls_and_remediation_plan.md)**.

### Feature 1: PEP 621 Package Identification & Augmentation [COMPLETED — STAGE 1]
* **Status**: Submitted in [colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750) (`4a594c8`).
* **Scope**:
  - `colcon_core/package_identification/pep621.py`: Detects directories containing `pyproject.toml` with `[project].name` and assigns `python.project`.
  - `colcon_core/package_augmentation/pep621.py`: Maps `[build-system].requires`, `[project].dependencies`, and `[project.optional-dependencies].test`.

### Feature 2: PEP 517/621 Build Task Integration [COMPLETED — STAGE 1]
* **Status**: Submitted in [colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750) (`4a594c8`).
* **Scope**:
  - `colcon_core/task/python_project/build.py`: Invokes `build_wheel` / `build_editable` via `AsyncHookCaller`, unpacks via `install_wheel`, writes PEP 610 `direct_url.json`, and registers colcon environment hooks in `.dist-info/RECORD`.
  - Optional rollout gating supported via `COLCON_FEATURE_FLAGS=pep621_builds`.

### Feature 3: PEP 660 Editable Data Files & Script Directory Override [COMPLETED — STAGE 2]
* **Status**: Verified in Draft PR [colcon/colcon-core#751](https://github.com/colcon/colcon-core/pull/751) (`463df5f`, **46/46 GitHub Actions CI checks green**).
* **Scope**:
  - Exposes `script_dir_override=None` on `PythonProjectBuildTask.build()` and fixes relative `install_base` `$base` resolution.
  - Scopes `_get_data_files_mapping(pkg, backend_name)` to `setuptools.build_meta*` (with glob expansion across `setup.cfg` and `[tool.setuptools.data-files]`) and `hatchling.*` (file and directory `[tool.hatch.build.targets.wheel.shared-data]`).
  - Deduplicates `.dist-info/RECORD` entries in place when replacing wheel `.data/` copies with symbolic links.

### Feature 4: ROS 2 `ament_python` with Standard Python Builds [COMPLETED — STAGE 3]
* **Status**: Verified in Draft PR [colcon/colcon-ros#171](https://github.com/colcon/colcon-ros/pull/171) (`359ab5c`, **16/16 `pytest --cov --cov-branch` checks green** + **4/4 mock scenarios passing**).
* **Scope**:
  - `AmentPythonBuildTask`: Detects `package.xml` (`<build_type>ament_python</build_type>`) packages with `pyproject.toml` and no `setup.py`, delegates to `PythonProjectBuildTask` with `script_dir_override=Path('lib') / pkg.name` (`ros2 run` path) and flat `additional_hooks`, and installs/records `ament_index` and `package.xml` after wheel installation.
  - `RosAmentPythonPackageAugmentation`: Populates `get_python_setup_options` from `pyproject.toml` (`[project.dependencies]`, `[project.optional-dependencies]`, PEP 735 `[dependency-groups]`) so `AmentPythonTestTask` matches `pytest` during `colcon test`.

### Feature 5: Dockerized & GitHub Actions ROS 2 Jazzy Proof of Concept [COMPLETED — FINAL PHASE POC]
* **Status**: Verified locally and on GitHub Actions in run [40795039655](https://github.com/KmoM88/colcon-roadmap/actions/runs/40795039655) (`target=all`, conclusion `success`).
* **Scope**:
  - Builds a clean `ros:jazzy-ros-core` image containing `colcon-core` (`463df5f`) and `colcon-ros` (`359ab5c`) and executes 6 human-readable verification stages across three migrated active `ros2/*` forks on branch `poc/pep621-ament-python`: [`KmoM88/demos@b249c6c`](https://github.com/KmoM88/demos/tree/poc/pep621-ament-python) (`hatchling.build`), [`KmoM88/examples@8e0155f`](https://github.com/KmoM88/examples/tree/poc/pep621-ament-python) (`flit_core.buildapi`), and [`KmoM88/teleop_twist_keyboard@962e0e9`](https://github.com/KmoM88/teleop_twist_keyboard/tree/poc/pep621-ament-python) (`setuptools.build_meta`).
  - Manual `workflow_dispatch` runner ([`.github/workflows/ros2_pep621_poc.yml`](.github/workflows/ros2_pep621_poc.yml)) publishes full stage logs to the GitHub Actions job summary and uploads downloadable log artifacts.

---

## 4. Stage 4 Follow-Up Branches (Implemented & Fork-CI Verified) & Stage 5 Transition

> [!NOTE]
> Complete branch-by-branch specifications, commit SHAs, file lists, edge-case analyses, and verification logs for Stage 4 Group A and Group B are maintained in **[docs/plans/stage4_branch_plan.md](docs/plans/stage4_branch_plan.md)**. Per review strategy, all four branches are pushed to `KmoM88/colcon-core` without creating draft PRs on `colcon/colcon-core`, and validated together via fork PR **[KmoM88/colcon-core#5](https://github.com/KmoM88/colcon-core/pull/5)** (`ci/stage4-all-validation` @ `32dd42a`, **44/44 GitHub Actions matrix jobs passing** in run [40802478808](https://github.com/KmoM88/colcon-core/actions/runs/40802478808)).

### Stage 4 — Group A: Implemented Branches off `KmoM88/colcon-core:master` (`6bfb100`)
| Stage | Pushed Branch & Commit (`KmoM88/colcon-core`) | Base & Fork Compare | Delivered & Verified Capabilities |
| :--- | :--- | :--- | :--- |
| **Stage 4B** | [`feature/setuptools-decorator`](https://github.com/KmoM88/colcon-core/tree/feature/setuptools-decorator) (`bdf5077`) | `origin/master` (`6bfb100`) — [Compare](https://github.com/KmoM88/colcon-core/compare/master...feature/setuptools-decorator) | `SetuptoolsHookCallerDecoratorExtension` (`colcon_core/python_project/hook_caller_decorator/setuptools.py`) isolating `--build-base` and `--egg-base` in temporary directories (zero `.egg-info/` or `build/` in source tree), plus `colcon_core.python_project.hook_caller_decorator` registration in `setup.cfg` (`243 passed, 5 skipped` locally; 44/44 fork CI green). |
| **Stage 4D** | [`feature/wheel-script-dir-and-windows-symlink`](https://github.com/KmoM88/colcon-core/tree/feature/wheel-script-dir-and-windows-symlink) (`85a79ae`) | `origin/master` (`6bfb100`) — [Compare](https://github.com/KmoM88/colcon-core/compare/master...feature/wheel-script-dir-and-windows-symlink) | `script_dir.mkdir(parents=True, exist_ok=True)` in `colcon_core/python_project/wheel.py` before calling cached `ScriptMaker.make_multiple()` after `remove_distributions()`, plus Windows `winerror 1314` warning and copy fallback in `colcon_core.task.install()` (`240 passed, 5 skipped` locally; 44/44 fork CI green). |

### Stage 4 — Group B: Implemented Branches Stacked on `feature/pep621-upstream-pr` (`4a594c8`)
| Stage | Pushed Branch & Commit (`KmoM88/colcon-core`) | Base & Fork Compare | Delivered & Verified Capabilities |
| :--- | :--- | :--- | :--- |
| **Stage 4A** | [`feature/python-project-test-task`](https://github.com/KmoM88/colcon-core/tree/feature/python-project-test-task) (`d4b93bc`) | `origin/feature/pep621-upstream-pr` (`4a594c8`) — [Compare](https://github.com/KmoM88/colcon-core/compare/feature/pep621-upstream-pr...feature/python-project-test-task) | `PythonProjectTestTask(PythonTestTask)` (`add_arguments` no-op to avoid duplicate `--python-testing` CLI option), `python.project` registration under `colcon_core.task.test`, and static PEP 621 / PEP 735 `get_python_setup_options` in `PEP621PackageAugmentation` (`256 passed, 5 skipped` locally; 44/44 fork CI green). |
| **Stage 4C** | [`feature/pep621-dynamic-metadata`](https://github.com/KmoM88/colcon-core/tree/feature/pep621-dynamic-metadata) (`49fcded`) | `origin/feature/pep621-upstream-pr` (`4a594c8`) — [Compare](https://github.com/KmoM88/colcon-core/compare/feature/pep621-upstream-pr...feature/pep621-dynamic-metadata) | `PEP621PackageAugmentation` wired to `colcon_core.python_project.metadata.load_and_cache_metadata()` when `project.dynamic` declares `version`, `dependencies`, `optional-dependencies`, `maintainers`, or `authors`, with PEP 517 `build_wheel` fallback when optional `prepare_metadata_for_build_wheel` is absent (`257 passed, 5 skipped` locally; 44/44 fork CI green). |

### Stage 5: Ecosystem Transition & Deprecation (Planned Post-Merge)
- [ ] **Deprecate `colcon/colcon-python-project`**: Once Stages 1–4 merge upstream, publish a deprecation notice pointing to native `colcon-core` / `colcon-ros` support and close prototype PR #1.

---

## 5. Verification Commands

* **`colcon-core` unit & integration suite**:
  ```bash
  cd submodules/kmom88-colcon-core && .venv/bin/pytest
  ```
* **`colcon-ros` unit, integration & linter suite**:
  ```bash
  cd submodules/colcon-ros && .venv/bin/pytest --cov --cov-branch
  ```
* **End-to-end mock workspace scenarios (Scenarios 1–4)**:
  ```bash
  submodules/colcon-ros/.venv/bin/python3 scripts/test_mock_packages.py
  ```
* **Dockerized ROS 2 Jazzy Proof of Concept (Primary target or full 3-backend matrix)**:
  ```bash
  ./poc/run_poc.sh
  ./poc/run_poc.sh --target all
  ```
