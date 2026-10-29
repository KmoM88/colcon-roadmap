# Action Plan & Execution Record: PEP 621 / Standard Python Builds

This document tracks all completed implementation phases (Phases 1–5, corresponding to Stages 1–3) and defines the actionable plan for the remaining follow-up phases (Phases 6–7, corresponding to Stages 4–5).

---

## Phase 1: Harmonize & Validate `cottsay/pep621` [COMPLETED]

1. **Branch Tracking & Sync**: Checked out `cottsay/pep621` from `colcon/colcon-core` in `submodules/kmom88-colcon-core`.
2. **Align Async Tests with `colcon-core` Conventions**: Replaced `@pytest.mark.asyncio` in `test/test_task_python_project_build.py` with `from .run_until_complete import run_until_complete` and formatted imports per `flake8` (`816a0d3`).
3. **Unit Tests & Linters**: Verified all 19 core unit tests (`test_install_wheel.py`, `test_remove_wheel.py`, `test_package_identification_pep621.py`, `test_package_augmentation_pep621.py`, `test_task_python_project_build.py`) and `flake8` with 0 errors.

---

## Phase 2: Multi-Backend Integration Testing [COMPLETED]

* **Feature Branch**: `feature/pep621-integration-tests` in `submodules/kmom88-colcon-core` (Commit `c40901a`).
* **Test Suite Added**: `test/test_integration_pep621.py`.

| Test Case | Build Backend | Features Tested | Result |
| :--- | :--- | :--- | :--- |
| **`test_integration_flit_core_minimal`** | `flit_core.buildapi` | Pure PEP 621 identification, wheel build, extraction, runtime import | **PASSED** |
| **`test_integration_hatchling_cli_scripts`** | `hatchling.build` | `[project.scripts]` entry points, executable wrapper in `bin/` (`0o755`) | **PASSED** |
| **`test_integration_clean_rebuild`** | `flit_core.buildapi` | Idempotent rebuilds & `remove_distributions` purging removed source files | **PASSED** |
| **`test_integration_symlink_install_editable`** | `hatchling.build` | `--symlink-install` calling `build_editable`, PEP 610 `direct_url.json`, live edits | **PASSED** |

---

## Phase 3 (Stage 1): Upstream PR Submission for Core PEP 621 [SUBMITTED — PR #750]

* **Pull Request**: [colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750)
* **Target Branch**: `colcon/colcon-core:cottsay/pep621`
* **Head Branch**: `KmoM88/colcon-core:feature/pep621-upstream-pr` (Commit `4a594c8`)
* **PR Materials**:
  - PR Description: [docs/pr/pr_description_pep621.md](docs/pr/pr_description_pep621.md)
  - Issue #736 Comment: [docs/pr/issue_736_comment.md](docs/pr/issue_736_comment.md)
  - Deferred `PRIORITY = 80` Follow-Up Note: [docs/pr/pr_750_priority_comment.md](docs/pr/pr_750_priority_comment.md)
* **Outcome**: Preserved Scott Logan (`cottsay`) base commit (`80acf29`), aligned async runner and integration tests (`4a594c8`), and kept scope tight for upstream review.

---

## Phase 4 (Stage 2): Backend-Scoped Editable Data Files & Script Override [VERIFIED — DRAFT PR #751, 46/46 CI GREEN]

* **Pull Request**: [colcon/colcon-core#751](https://github.com/colcon/colcon-core/pull/751) (Draft)
* **Target Branch**: `colcon/colcon-core:master`
* **Head Branch**: `KmoM88/colcon-core:feature/pep660-editable-data-files` (Commit `463df5f`)
* **PR Description**: [docs/pr/pr_description_pep660_data_files.md](docs/pr/pr_description_pep660_data_files.md)
* **Completed Deliverables**:
  - Extended `PythonProjectBuildTask.build(*, additional_hooks=None, script_dir_override=None)` and fixed relative `install_base` `$base` resolution so downstream tasks (`colcon-ros`) can route scripts to `lib/<package>` without `setup.cfg`.
  - Scoped `_get_data_files_mapping(pkg, backend_name)` strictly to the active PEP 517 backend (`setuptools.build_meta*` with glob expansion for `setup.cfg` and `[tool.setuptools.data-files]`, `hatchling.*` for file and directory `[tool.hatch.build.targets.wheel.shared-data]`).
  - Deduplicated `.dist-info/RECORD` updates in place when replacing wheel `.data/` copies with symbolic links.
  - Added backend-independent unit tests (`test_get_data_files_mapping_by_backend`, `test_build_task_script_override_and_record_update`) and real-backend integration tests (`test_integration_symlink_install_data_files`, `test_integration_setuptools_data_files_and_script_override`) with entry-point cache isolation and `setuptools < 70.1` `wheel` guard.
* **Verification**: `256 passed, 5 skipped` locally; **46/46 GitHub Actions CI checks green** across Ubuntu, macOS, and Windows (Python 3.8–3.14, `stdeb`, `codecov`).

---

## Phase 5 (Stage 3): ROS 2 `ament_python` Modernization in `colcon-ros` [VERIFIED — DRAFT PR #171, 16/16 PYTEST GREEN]

* **Pull Request**: [colcon/colcon-ros#171](https://github.com/colcon/colcon-ros/pull/171) (Draft)
* **Target Branch**: `colcon/colcon-ros:master`
* **Head Branch**: `KmoM88/colcon-ros:feature/ros-ament-python-project` (Commit `359ab5c`)
* **PR Description**: [docs/pr/pr_description_colcon_ros.md](docs/pr/pr_description_colcon_ros.md)
* **Completed Deliverables**:
  - Updated `AmentPythonBuildTask` (`colcon_ros/task/ament_python/build.py`) to detect `<build_type>ament_python</build_type>` packages with `pyproject.toml` and no `setup.py`, delegate to `PythonProjectBuildTask`, pass `script_dir_override=Path('lib') / pkg.name` (`ros2 run` path), and pass flat `additional_hooks` so both `.dsv` and shell `ament_prefix_path` hooks register in `package.dsv` / `package.sh`.
  - Moved `share/ament_index/resource_index/packages/<pkg>` and `share/<pkg>/package.xml` installation *after* `PythonProjectBuildTask.build()` so `remove_distributions` does not delete freshly written files on rebuilds and wheel-provided files are preserved, recording added paths in `.dist-info/RECORD`.
  - Updated `RosAmentPythonPackageAugmentation` (`colcon_ros/package_augmentation/ros_ament_python.py`) to extract `[project.dependencies]`, `[project.optional-dependencies]`, and PEP 735 `[dependency-groups]` test dependencies so `colcon test` (`AmentPythonTestTask`) matches `pytest`.
  - Updated base-repo mock packages (`03_modern_editable_data_files` migrated to `hatchling` `shared-data`; `04_ros2_ament_pyproject` and `scripts/test_mock_packages.py` verifying `lib/ros_pyproject_pkg/sample-node`, repeated rebuilds, and `pytest` augmentation).
* **Verification**: `16 passed` under `pytest --cov --cov-branch` in `submodules/colcon-ros` (`flake8`, `scspell3k`, copyright, unit tests, and `flit_core` integration test) and `4/4` mock scenarios passing in `scripts/test_mock_packages.py`.

---

## Final Validation Phase: Dockerized & GitHub Actions ROS 2 Jazzy Proof of Concept (`poc/`) [COMPLETED]

* **Location**: [`poc/Dockerfile`](poc/Dockerfile), [`poc/container_poc.sh`](poc/container_poc.sh), [`poc/run_poc.sh`](poc/run_poc.sh), [`poc/README.md`](poc/README.md), and [`.github/workflows/ros2_pep621_poc.yml`](.github/workflows/ros2_pep621_poc.yml).
* **Migrated Active `ros2/*` Targets** (branch `poc/pep621-ament-python`, zero `setup.py` / `setup.cfg`):
  1. **`ros2/demos` (`demo_nodes_py`)** — Primary target ([`KmoM88/demos@b249c6c`](https://github.com/KmoM88/demos/tree/poc/pep621-ament-python), `hatchling.build`): 13 `[project.scripts]` nodes routed to `lib/demo_nodes_py/`, `share/demo_nodes_py/params.yaml` wheel `.data/` unpacking and `--symlink-install` live OS symlink, live `talker`/`listener` DDS message exchange via `ros2 run`, and `colcon test` (`ament_copyright`, `ament_flake8`, `ament_pep257`).
  2. **`ros2/examples` (`examples_rclpy_minimal_publisher` & `examples_rclpy_minimal_subscriber`)** — Optional target 2 ([`KmoM88/examples@8e0155f`](https://github.com/KmoM88/examples/tree/poc/pep621-ament-python), `flit_core.buildapi`): Multi-package pure PEP 621 build, 7 executables, PEP 660 `.pth` editable build, live DDS pub/sub communication, and `colcon test`.
  3. **`ros2/teleop_twist_keyboard` (`teleop_twist_keyboard`)** — Optional target 3 ([`KmoM88/teleop_twist_keyboard@962e0e9`](https://github.com/KmoM88/teleop_twist_keyboard/tree/poc/pep621-ament-python), `setuptools.build_meta`): Single-file `py-modules` node, live PTY keystroke -> `/cmd_vel` `Twist` DDS verification via `ros2 run`, PEP 660 editable build, and `colcon test` (including `ament_xmllint` on `package.xml` `<build_depend>`).
* **Local & GitHub Actions Verification**:
  - Local Docker execution (`./poc/run_poc.sh --target all`): All 3 active `ros2/*` targets passed all 6 deterministic verification stages.
  - Manual GitHub Actions `workflow_dispatch` execution ([`.github/workflows/ros2_pep621_poc.yml`](.github/workflows/ros2_pep621_poc.yml)): Verified green across `target=all` in run [40795039655](https://github.com/KmoM88/colcon-roadmap/actions/runs/40795039655) with full stage logs published to `$GITHUB_STEP_SUMMARY` and uploaded as workflow artifact `ros2-jazzy-pep621-poc-all`.
  - Upstream Results Gist: Synced implemented results summary (zero planning) to [gist.github.com/KmoM88/0357abff37b5a32ab801cac7d399d4ed](https://gist.github.com/KmoM88/0357abff37b5a32ab801cac7d399d4ed).

---

## Phase 6 (Stage 4): Follow-Up Single-Concern Branches in `colcon-core` [PLANNED]

To keep pull requests small and aligned with upstream review preferences, remaining `colcon-core` enhancements are planned across four single-concern branches in `submodules/kmom88-colcon-core` (`KmoM88/colcon-core`). Full branch blueprints, file changes, edge cases, and test plans are documented in **[docs/plans/stage4_branch_plan.md](docs/plans/stage4_branch_plan.md)**:

### Group A — New Branches off `colcon/colcon-core:master` (`6bfb100`, Independent of `#750` / `#751`)
1. **Stage 4B — Branch `feature/setuptools-decorator` (`origin/master` -> `colcon:master`)**:
   - **Files**: `colcon_core/python_project/hook_caller_decorator/setuptools.py` [new], `setup.cfg` [modify], `test/test_hook_caller_decorator_setuptools.py` [new].
   - **Scope**: Port `SetuptoolsHookCallerDecoratorExtension` (`HookCallerDecoratorExtensionPoint`, merged in PR #732) to redirect `--build-base` and `--egg-base` into temporary directories so `setuptools.build_meta` / `setuptools.build_meta:__legacy__` builds never write `.egg-info/` or `build/` into the package source directory; register `colcon_core.python_project.hook_caller_decorator` under `colcon_core.extension_point` in `setup.cfg`.
2. **Stage 4D — Branch `feature/wheel-script-dir-and-windows-symlink` (`origin/master` -> `colcon:master`)**:
   - **Files**: `colcon_core/python_project/wheel.py` [modify], `colcon_core/task/__init__.py` [modify], `test/test_install_wheel.py` [modify], `test/test_task.py` [modify].
   - **Scope**:
     - Ensure `script_dir.mkdir(parents=True, exist_ok=True)` in `colcon_core/python_project/wheel.py` before calling cached `ScriptMaker.make_multiple()` so repeated in-process builds after `remove_distributions()` removes an empty `script_dir` never fail with `FileNotFoundError`.
     - Catch `OSError` (`winerror == 1314`) when `os.symlink()` lacks `SeCreateSymbolicLinkPrivilege` on Windows in `colcon_core.task.install()`, emit a warning, and fall back to copying the file.

### Group B — New Branches Stacked on `feature/pep621-upstream-pr` (`4a594c8` / `cottsay/pep621` `#750`)
3. **Stage 4A — Branch `feature/python-project-test-task` (`origin/feature/pep621-upstream-pr` -> `colcon:cottsay/pep621`, then `master`)**:
   - **Files**: `colcon_core/task/python_project/test.py` [new], `colcon_core/package_augmentation/pep621.py` [modify], `setup.cfg` [modify], `test/test_task_python_project_test.py` [new], `test/test_package_augmentation_pep621.py` [modify], `test/test_integration_pep621.py` [modify].
   - **Scope**: Add `PythonProjectTestTask(PythonTestTask)` (overriding `add_arguments` to avoid duplicate `--python-testing` registration), register `python.project` under `colcon_core.task.test`, and populate static `get_python_setup_options` in `PEP621PackageAugmentation` across `[project.optional-dependencies]` (`test`/`tests`/`testing`) and PEP 735 `[dependency-groups]` so pure non-ROS `python.project` packages execute `pytest` via `colcon test`.
4. **Stage 4C — Branch `feature/pep621-dynamic-metadata` (`origin/feature/pep621-upstream-pr` -> `colcon:cottsay/pep621`, then `master`)**:
   - **Files**: `colcon_core/python_project/metadata.py` [modify], `colcon_core/package_augmentation/pep621.py` [modify], `test/test_python_project_metadata.py` [new], `test/test_package_augmentation_pep621.py` [modify].
   - **Scope**: Connect `PEP621PackageAugmentation` to `colcon_core.python_project.metadata.load_and_cache_metadata()` when `project.dynamic` declares `version`, `dependencies`, `optional-dependencies`, `maintainers`, or `authors`, add PEP 517 `build_wheel` fallback when optional `prepare_metadata_for_build_wheel` is absent, and degrade gracefully with a warning if build backends are missing during discovery.

---

## Phase 7 (Stage 5): Deprecation and Archival of `colcon-python-project` [PLANNED POST-MERGE]

Once native support is merged in `colcon-core` and `colcon-ros`:
1. Publish a deprecation notice in `colcon/colcon-python-project` pointing users to native `colcon-core` and `colcon-ros` support.
2. Close PR #1 in `colcon-python-project` referencing the merged upstream pull requests.
