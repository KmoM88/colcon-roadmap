# Current Status of PEP 517/518/621/660 Adoption in colcon-core & colcon-ros

This document records the current implementation and verification state of modern Python packaging standards (PEP 517/518/621/660) across `colcon-core` and `colcon-ros`, along with the remaining single-concern follow-up queue.

---

## 1. Executive Summary

* **Merged Foundations (`colcon-core` `v0.21.2` / `v0.21.3`)**: `InstalledDistribution` (PR #728), `AsyncHookCaller` & `load_and_cache_spec` (PR #732), and in-process `install_wheel` / `remove_distributions` (PR #741) are merged on `colcon/colcon-core:master`.
* **Stage 1 — PR #750 (Submitted & Under Review)**: [colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750) (`KmoM88:feature/pep621-upstream-pr` at `4a594c8` -> `colcon:cottsay/pep621`) aligns async unit tests with `run_until_complete` and adds real multi-backend (`flit_core`, `hatchling`) integration tests.
* **Stage 2 — Draft PR #751 (46/46 CI Checks Green)**: [colcon/colcon-core#751](https://github.com/colcon/colcon-core/pull/751) (`KmoM88:feature/pep660-editable-data-files` at `463df5f` -> `colcon:master`) adds `script_dir_override` (with relative `install_base` `$base` fix), backend-scoped editable data-file symlinking (`setuptools.build_meta*` globs + `hatchling.*` `shared-data`), deduplicated `.dist-info/RECORD` updates, and cache-isolated unit/integration tests (`256 passed, 5 skipped` locally; 46/46 GitHub Actions checks passing).
* **Stage 3 — Draft PR #171 (16/16 `pytest` Checks Green)**: [colcon/colcon-ros#171](https://github.com/colcon/colcon-ros/pull/171) (`KmoM88:feature/ros-ament-python-project` at `359ab5c` -> `colcon:master`) enables ROS 2 `ament_python` packages using `pyproject.toml` without `setup.py`, routing `[project.scripts]` to `lib/<pkg>/` for `ros2 run`, passing flat `additional_hooks`, installing/recording `ament_index` and `package.xml` post-wheel for idempotent rebuilds, and augmenting test metadata in `RosAmentPythonPackageAugmentation` for `colcon test`.
* **Stage 4 — Group A & Group B Follow-Up Branches (Implemented on Fork & 44/44 Fork CI Green)**: All four single-concern Stage 4 branches are implemented, pushed to `KmoM88/colcon-core` (`feature/setuptools-decorator` @ `bdf5077`, `feature/wheel-script-dir-and-windows-symlink` @ `85a79ae`, `feature/python-project-test-task` @ `d4b93bc`, `feature/pep621-dynamic-metadata` @ `49fcded`) without creating upstream draft PRs, and verified together on fork-local PR [KmoM88/colcon-core#5](https://github.com/KmoM88/colcon-core/pull/5) (`ci/stage4-all-validation` @ `32dd42a`; **44/44 GitHub Actions matrix jobs passing** in run [40802478808](https://github.com/KmoM88/colcon-core/actions/runs/40802478808), `272 passed, 5 skipped` locally).
* **Final Phase PoC — Dockerized & GitHub Actions ROS 2 Jazzy Multi-Backend Validation ([`poc/`](poc/README.md))**: Self-contained Docker image (`ros:jazzy-ros-core` + modernized `colcon-core` / `colcon-ros`) executing a 6-stage verification pipeline against active `ros2/*` packages migrated to pure `pyproject.toml` on branch `poc/pep621-ament-python` (`demo_nodes_py` on `hatchling` at [`KmoM88/demos@b249c6c`](https://github.com/KmoM88/demos/tree/poc/pep621-ament-python), `examples_rclpy_minimal_publisher`/`subscriber` on `flit_core` at [`KmoM88/examples@8e0155f`](https://github.com/KmoM88/examples/tree/poc/pep621-ament-python), and `teleop_twist_keyboard` on `setuptools.build_meta` at [`KmoM88/teleop_twist_keyboard@962e0e9`](https://github.com/KmoM88/teleop_twist_keyboard/tree/poc/pep621-ament-python)), verified both locally and on GitHub Actions via [`.github/workflows/ros2_pep621_poc.yml`](.github/workflows/ros2_pep621_poc.yml) in run [40795039655](https://github.com/KmoM88/colcon-roadmap/actions/runs/40795039655).
* **Published Results Summary (Gist)**: Results-only upstream summary synced at [gist.github.com/KmoM88/0357abff37b5a32ab801cac7d399d4ed](https://gist.github.com/KmoM88/0357abff37b5a32ab801cac7d399d4ed) ([docs/proposals/pep621_pep660_upstream_proposal.md](docs/proposals/pep621_pep660_upstream_proposal.md)).

```text
+--------------------------------------------------------------------------+
|                               colcon-core                                |
|                                                                          |
|  [MERGED] PR #732: AsyncHookCaller & pyproject.toml spec loader          |
|  [MERGED] PR #728: InstalledDistribution (installed file discovery)      |
|  [MERGED] PR #741: Wheel Engine (install_wheel & remove_distributions)   |
|  ----------------------------------------------------------------------  |
|  [STAGE 1 - OPEN PR] colcon/colcon-core#750 (Commit 4a594c8)             |
|  +- Target: cottsay/pep621 (Identification, Augmentation, BuildTask)     |
|  +- Async test runner aligned to run_until_complete                      |
|  +- Multi-backend integration suite (flit_core, hatchling)               |
|  ----------------------------------------------------------------------  |
|  [STAGE 2 - DRAFT PR] colcon/colcon-core#751 (Commit 463df5f)            |
|  +- script_dir_override API & relative install_base $base fix            |
|  +- Backend-scoped editable data files (setuptools globs, hatchling)     |
|  +- Deduplicated RECORD updates; 46/46 GitHub Actions CI checks green    |
|  ----------------------------------------------------------------------  |
|  [STAGE 4 - FORK BRANCHES & CI PR] KmoM88/colcon-core#5 (44/44 CI GREEN) |
|  +- 4B feature/setuptools-decorator (bdf5077) off master                 |
|  +- 4D feature/wheel-script-dir-and-windows-symlink (85a79ae) off master |
|  +- 4A feature/python-project-test-task (d4b93bc) off #750               |
|  +- 4C feature/pep621-dynamic-metadata (49fcded) off #750                |
+--------------------------------------------------------------------------+
                                     |
                                     v
+--------------------------------------------------------------------------+
|                                colcon-ros                                |
|                                                                          |
|  [STAGE 3 - DRAFT PR] colcon/colcon-ros#171 (Commit 359ab5c)             |
|  +- AmentPythonBuildTask delegates pyproject.toml-only builds            |
|  +- script_dir_override = Path('lib') / pkg.name (ros2 run layout)       |
|  +- Flat additional_hooks + post-wheel ament_index & package.xml RECORD  |
|  +- RosAmentPythonPackageAugmentation enables pytest in colcon test      |
|  +- 16/16 pytest --cov --cov-branch passing + 4/4 mock scenarios green   |
+--------------------------------------------------------------------------+
```

---

## 2. Merged Foundations Summary (`colcon-core` PRs #728, #732, #741)

* **PR #732 (`AsyncHookCaller`)**: Runs PEP 517 backend hooks in subprocesses via OS pipes and pickle serialization, exposes `HookCallerDecoratorExtensionPoint`, and provides `colcon_core.python_project.spec.load_and_cache_spec`.
* **PR #728 (`InstalledDistribution`)**: Discovers installed `.dist-info` / `.egg-info` distributions, entry points, top-level modules, and `.pyc` files under an `install_base`.
* **PR #741 (`wheel.py`, Commit `845927c`)**:
  - `remove_distributions`: Queries `InstalledDistribution.discover`, unlinks installed files, and removes empty parent directories up to `install_base`.
  - `install_wheel`: Extracts `.whl` archives in-process, maps `.data/` subdirectories (`share/`, etc.), generates console script wrappers via `distlib.scripts.ScriptMaker` (honoring `script_dir_override`), and writes PEP 376 `INSTALLER` and `RECORD`.

---

## 3. Delivered Pull Requests Breakdown (Stages 1–3)

### A. Stage 1 (`colcon/colcon-core#750` — Commit `4a594c8`)
* **Base**: `colcon/colcon-core:cottsay/pep621` (`80acf29` by Scott K Logan)
* **Head**: `KmoM88/colcon-core:feature/pep621-upstream-pr` (`4a594c8`)
* **Delivered**:
  - Harmonized `test/test_task_python_project_build.py` to use `run_until_complete` instead of `@pytest.mark.asyncio`.
  - Added `test/test_integration_pep621.py` covering `flit_core.buildapi` and `hatchling.build` standard builds, `[project.scripts]` wrappers in `bin/`, idempotent rebuilds, and PEP 660 `build_editable` with PEP 610 `direct_url.json`.

### B. Stage 2 (`colcon/colcon-core#751` — Commit `463df5f`, 46/46 CI Green)
* **Base**: `colcon/colcon-core:master`
* **Head**: `KmoM88/colcon-core:feature/pep660-editable-data-files` (`463df5f`)
* **Delivered**:
  - Extended `PythonProjectBuildTask.build(*, additional_hooks=None, script_dir_override=None)` and fixed `$base` expansion when `args.install_base` is relative.
  - Scoped `_get_data_files_mapping(pkg, backend_name)` strictly to `setuptools.build_meta*` (with glob support for `setup.cfg` and `[tool.setuptools.data-files]`) and `hatchling.*` (file and directory `[tool.hatch.build.targets.wheel.shared-data]`).
  - Deduplicated `.dist-info/RECORD` updates via `record_map`.
  - Added `test_get_data_files_mapping_by_backend`, `test_build_task_script_override_and_record_update`, `test_integration_symlink_install_data_files`, and `test_integration_setuptools_data_files_and_script_override` (with `setuptools < 70.1` `wheel` guard and entry-point cache isolation).
  - Verified `256 passed, 5 skipped` locally and **46/46 GitHub Actions CI checks green**.

### C. Stage 3 (`colcon/colcon-ros#171` — Commit `359ab5c`, 16/16 `pytest` Green)
* **Base**: `colcon/colcon-ros:master`
* **Head**: `KmoM88/colcon-ros:feature/ros-ament-python-project` (`359ab5c`)
* **Delivered**:
  - Updated `AmentPythonBuildTask` (`colcon_ros/task/ament_python/build.py`) to pass `script_dir_override=Path('lib') / self.context.pkg.name` (`ros2 run` discovery path) and flat `additional_hooks=additional_hooks` to `PythonProjectBuildTask.build()`.
  - Moved `share/ament_index/resource_index/packages/<pkg>` and `share/<pkg>/package.xml` installation *after* `PythonProjectBuildTask.build()` so `remove_distributions` does not delete freshly written files on rebuilds and wheel-provided files are preserved, recording added paths in `.dist-info/RECORD`.
  - Updated `RosAmentPythonPackageAugmentation` (`colcon_ros/package_augmentation/ros_ament_python.py`) to extract `[project.dependencies]`, `[project.optional-dependencies]`, and PEP 735 `[dependency-groups]` test dependencies when `setup.py` is absent so `AmentPythonTestTask` matches `pytest` during `colcon test`.
  - Verified `16 passed` under `pytest --cov --cov-branch` (unit tests, `flit_core` integration test, `flake8`, `scspell3k`, copyright) and `4/4` end-to-end mock scenarios in `scripts/test_mock_packages.py`.

### D. Final Phase PoC & GitHub Actions Runner (`poc/` & `.github/workflows/ros2_pep621_poc.yml`)
* **Container Stack**: `ros:jazzy-ros-core` (Ubuntu 24.04, Python 3.12) + `submodules/kmom88-colcon-core` (`463df5f`) + `submodules/colcon-ros` (`359ab5c`).
* **Migrated Active `ros2/*` Forks (`poc/pep621-ament-python`)**:
  - [`KmoM88/demos@b249c6c`](https://github.com/KmoM88/demos/tree/poc/pep621-ament-python) (`demo_nodes_py` on `hatchling.build`).
  - [`KmoM88/examples@8e0155f`](https://github.com/KmoM88/examples/tree/poc/pep621-ament-python) (`examples_rclpy_minimal_publisher` & `examples_rclpy_minimal_subscriber` on `flit_core.buildapi`).
  - [`KmoM88/teleop_twist_keyboard@962e0e9`](https://github.com/KmoM88/teleop_twist_keyboard/tree/poc/pep621-ament-python) (`teleop_twist_keyboard` on `setuptools.build_meta`).
* **Manual GitHub Actions Validation**: Verified green across all 3 targets and all 6 stages (`target=all`) via [`.github/workflows/ros2_pep621_poc.yml`](.github/workflows/ros2_pep621_poc.yml) in run [40795039655](https://github.com/KmoM88/colcon-roadmap/actions/runs/40795039655).

---

## 4. Current Adoption Matrix

| Component | Status | Location / Branch / PR | Notes |
| :--- | :--- | :--- | :--- |
| **Backend Hook IPC & Spec Loader** | **Merged** | `colcon-core#732` | `AsyncHookCaller`, `HookCallerDecoratorExtensionPoint`, `load_and_cache_spec` |
| **Installed File Discovery** | **Merged** | `colcon-core#728` | `InstalledDistribution` |
| **Wheel Install & Uninstall Engine** | **Merged** | `colcon-core#741` (`845927c`) | `install_wheel`, `remove_distributions` |
| **PEP 621 Identification, Augmentation & Build** | **Submitted PR #750** | [colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750) (`4a594c8`) | Targets `cottsay/pep621`; `run_until_complete` + multi-backend integration tests |
| **Editable Data Files & `script_dir_override`** | **Draft PR #751 (46/46 CI)** | [colcon/colcon-core#751](https://github.com/colcon/colcon-core/pull/751) (`463df5f`) | Backend-scoped `share/` symlinking, deduplicated `RECORD` & relative `$base` fix |
| **ROS 2 `ament_python` `pyproject.toml` Build & Test** | **Draft PR #171 (16/16 pytest)** | [colcon/colcon-ros#171](https://github.com/colcon/colcon-ros/pull/171) (`359ab5c`) | `lib/<pkg>` script override, flat hooks, `RECORD`-tracked index/manifest & `colcon test` augmentation |
| **ROS 2 Jazzy Multi-Backend PoC & GH Workflow** | **Verified Green** | [`poc/`](poc/README.md) & [run 40795039655](https://github.com/KmoM88/colcon-roadmap/actions/runs/40795039655) | 3 active `ros2/*` repos (`hatchling`, `flit_core`, `setuptools.build_meta`), 6 stages passing |
| **`SetuptoolsDecorator` Scratch Isolation** | **Implemented & Fork-CI Green (Stage 4B)** | [`KmoM88/colcon-core:feature/setuptools-decorator`](https://github.com/KmoM88/colcon-core/tree/feature/setuptools-decorator) (`bdf5077`) | Redirects `--build-base` / `--egg-base` out of source tree + registers decorator group in `setup.cfg`; verified in [KmoM88/colcon-core#5](https://github.com/KmoM88/colcon-core/pull/5) |
| **Wheel `script_dir.mkdir` & Windows Symlink Fallback** | **Implemented & Fork-CI Green (Stage 4D)** | [`KmoM88/colcon-core:feature/wheel-script-dir-and-windows-symlink`](https://github.com/KmoM88/colcon-core/tree/feature/wheel-script-dir-and-windows-symlink) (`85a79ae`) | Fixes cached `ScriptMaker` rebuild error + Windows `winerror 1314` `os.symlink` copy fallback; verified in [KmoM88/colcon-core#5](https://github.com/KmoM88/colcon-core/pull/5) |
| **`python.project` `colcon test` Task** | **Implemented & Fork-CI Green (Stage 4A)** | [`KmoM88/colcon-core:feature/python-project-test-task`](https://github.com/KmoM88/colcon-core/tree/feature/python-project-test-task) (`d4b93bc`) | Registers `python.project` under `colcon_core.task.test` + static PEP 621 / PEP 735 test options; verified in [KmoM88/colcon-core#5](https://github.com/KmoM88/colcon-core/pull/5) |
| **Dynamic Metadata Hook Wiring** | **Implemented & Fork-CI Green (Stage 4C)** | [`KmoM88/colcon-core:feature/pep621-dynamic-metadata`](https://github.com/KmoM88/colcon-core/tree/feature/pep621-dynamic-metadata) (`49fcded`) | Connects `PEP621PackageAugmentation` to `load_and_cache_metadata` with PEP 517 `build_wheel` fallback; verified in [KmoM88/colcon-core#5](https://github.com/KmoM88/colcon-core/pull/5) |

---

## 5. Stage 4 Fork-Verified Branches & Remaining Stage 5 Queue

Detailed branch-by-branch specifications, commit SHAs, file changes, and verification suites for Stage 4 Group A and Group B are documented in **[docs/plans/stage4_branch_plan.md](docs/plans/stage4_branch_plan.md)**. All four branches are pushed to `KmoM88/colcon-core` (with no upstream draft PRs opened on `colcon/colcon-core`) and validated together via fork PR **[KmoM88/colcon-core#5](https://github.com/KmoM88/colcon-core/pull/5)** (`ci/stage4-all-validation` @ `32dd42a`, **44/44 GitHub Actions matrix jobs passing** in run [40802478808](https://github.com/KmoM88/colcon-core/actions/runs/40802478808)):

1. **Stage 4 — Group A (Implemented off `KmoM88/colcon-core:master` @ `6bfb100`)**:
   - **Branch [`feature/setuptools-decorator`](https://github.com/KmoM88/colcon-core/tree/feature/setuptools-decorator) (`bdf5077`, Stage 4B)**: Implements `SetuptoolsHookCallerDecoratorExtension` (`colcon_core/python_project/hook_caller_decorator/setuptools.py`) and registers `colcon_core.python_project.hook_caller_decorator` in `setup.cfg` so `setuptools.build_meta` builds never create untracked `.egg-info/` or `build/` directories in package source trees (`243 passed, 5 skipped` locally).
   - **Branch [`feature/wheel-script-dir-and-windows-symlink`](https://github.com/KmoM88/colcon-core/tree/feature/wheel-script-dir-and-windows-symlink) (`85a79ae`, Stage 4D)**: Ensures `script_dir.mkdir(parents=True, exist_ok=True)` in `colcon_core/python_project/wheel.py` for cached `ScriptMaker` instances after `remove_distributions()`, and adds graceful file-copy fallback in `colcon_core.task.install()` when Windows lacks `SeCreateSymbolicLinkPrivilege` (`winerror 1314`) (`240 passed, 5 skipped` locally).
2. **Stage 4 — Group B (Implemented off `KmoM88/colcon-core:feature/pep621-upstream-pr` @ `4a594c8`)**:
   - **Branch [`feature/python-project-test-task`](https://github.com/KmoM88/colcon-core/tree/feature/python-project-test-task) (`d4b93bc`, Stage 4A)**: Registers `python.project = colcon_core.task.python_project.test:PythonProjectTestTask` under `colcon_core.task.test` (with `add_arguments` no-op to avoid duplicate `--python-testing` registration) and populates static PEP 621 / PEP 735 `get_python_setup_options` in `PEP621PackageAugmentation` (`256 passed, 5 skipped` locally).
   - **Branch [`feature/pep621-dynamic-metadata`](https://github.com/KmoM88/colcon-core/tree/feature/pep621-dynamic-metadata) (`49fcded`, Stage 4C)**: Wires `PEP621PackageAugmentation` to `load_and_cache_metadata` when `project.dynamic` fields are declared, including PEP 517 `build_wheel` fallback when optional `prepare_metadata_for_build_wheel` is absent (`257 passed, 5 skipped` locally).
3. **Stage 5 (`colcon-python-project` — Planned Post-Merge)**: Deprecate `colcon/colcon-python-project` and close prototype PR #1 once Stages 1–4 land upstream.
