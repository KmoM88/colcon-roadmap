# Migration Status & Next Integration Steps

This document tracks the migration of modern Python packaging capabilities (PEP 517/518/621/660) from the prototype extension [colcon-python-project](submodules/colcon-python-project) into [colcon-core](submodules/colcon-core) and [colcon-ros](submodules/colcon-ros).

---

## 1. Status of Migration Phases

| Phase / Feature | Status | Description |
| :--- | :--- | :--- |
| **Hook Invocations** | **Merged Upstream** (PR #732) | `AsyncHookCaller` for executing backend hooks in isolated subprocess. |
| **Installed Distribution Discovery** | **Merged Upstream** (PR #728) | `InstalledDistribution` for discovering installed files on disk. |
| **Wheel Uninstallation** (`remove_distributions`) | **Merged Upstream** (PR #741) | Metadata-driven removal of previous installations and directory pruning. |
| **Wheel Installation Engine** (`install_wheel`) | **Merged Upstream** (PR #741) | Layout extraction, `.data/` directory mapping, script wrapping, and `RECORD` signing. |
| **PEP 621 Identification & Augmentation** | **Completed & Validated** | Parsing `pyproject.toml` `[project]` static table and dependencies (Priority 90). |
| **Build Task Integration** (`PythonProjectBuildTask`) | **Completed & Validated** | Hook caller execution + `install_wheel` integration in build lifecycle. |
| **Integration Test Suite** | **Completed & Validated** | End-to-end tests with real backends (`flit_core`, `hatchling`). 24/24 tests passing. |
| **PEP 660 Editable & Data Files** | **Completed & Validated** | `build_editable` invocation + symlinking data files in `share/` (PR #751, 46/46 CI green). |
| **ROS 2 `ament_python` PEP 621** | **Completed & Validated** | Native routing in `colcon-ros` for packages declaring only `pyproject.toml` (PR #171, 16/16 pytest green). |
| **`SetuptoolsDecorator` Scratch Isolation** | **Completed & Fork-CI Green** | Redirects `--build-base` / `--egg-base` out of source tree + registers decorator group (`bdf5077`). |
| **Wheel `script_dir` & Windows Symlink Fallback** | **Completed & Fork-CI Green** | Cached `ScriptMaker` rebuild `script_dir.mkdir` + Windows `winerror 1314` copy fallback (`85a79ae`). |
| **`PythonProjectTestTask` & PEP 735 Test Options** | **Completed & Fork-CI Green** | Registers `python.project` under `colcon_core.task.test` + static PEP 621 / PEP 735 options (`d4b93bc`). |
| **Dynamic Metadata Hook Wiring** | **Completed & Fork-CI Green** | Connects `PEP621PackageAugmentation` to `load_and_cache_metadata` + PEP 517 `build_wheel` fallback (`49fcded`). |

---

## 2. Upstream Submission Packages

All code changes are tested, formatted to flake8 standards, and ready for upstream contribution via GitHub Web:

1. **`colcon-core` PEP 621 PR ([colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750))**:
   - Branch: `KmoM88/colcon-core:feature/pep621-upstream-pr` (`4a594c8`)
   - Description & Comment: [docs/pr/pr_description_pep621.md](docs/pr/pr_description_pep621.md) & [docs/pr/issue_736_comment.md](docs/pr/issue_736_comment.md)
   - Comparison: [colcon/colcon-core:cottsay/pep621...KmoM88:colcon-core:feature/pep621-upstream-pr](https://github.com/colcon/colcon-core/compare/cottsay/pep621...KmoM88:colcon-core:feature/pep621-upstream-pr)

2. **`colcon-core` PEP 660 Data Files & Script Override PR ([colcon/colcon-core#751](https://github.com/colcon/colcon-core/pull/751))**:
   - Branch: `KmoM88/colcon-core:feature/pep660-editable-data-files` (`463df5f`, 46/46 CI green)
   - Description: [docs/pr/pr_description_pep660_data_files.md](docs/pr/pr_description_pep660_data_files.md)
   - Comparison: [colcon/colcon-core:master...KmoM88:colcon-core:feature/pep660-editable-data-files](https://github.com/colcon/colcon-core/compare/master...KmoM88:colcon-core:feature/pep660-editable-data-files)

3. **`colcon-ros` PEP 621 `ament_python` PR ([colcon/colcon-ros#171](https://github.com/colcon/colcon-ros/pull/171))**:
   - Branch: `KmoM88/colcon-ros:feature/ros-ament-python-project` (`359ab5c`, 16/16 `pytest` green)
   - Description: [docs/pr/pr_description_colcon_ros.md](docs/pr/pr_description_colcon_ros.md)
   - Comparison: [colcon/colcon-ros:master...KmoM88:colcon-ros:feature/ros-ament-python-project](https://github.com/colcon/colcon-ros/compare/master...KmoM88:colcon-ros:feature/ros-ament-python-project)

4. **Stage 4 Follow-Up Branches (`KmoM88/colcon-core` Group A & Group B — Pushed to Fork & CI-Verified)**:
   - Fork-Local Validation PR *(no upstream drafts created)*: [KmoM88/colcon-core#5](https://github.com/KmoM88/colcon-core/pull/5) (`ci/stage4-all-validation` @ `32dd42a`, **44/44 GitHub Actions matrix jobs passing** in run [40802478808](https://github.com/KmoM88/colcon-core/actions/runs/40802478808))
   - Group A (`master` @ `6bfb100`): [`feature/setuptools-decorator`](https://github.com/KmoM88/colcon-core/tree/feature/setuptools-decorator) (`bdf5077`), [`feature/wheel-script-dir-and-windows-symlink`](https://github.com/KmoM88/colcon-core/tree/feature/wheel-script-dir-and-windows-symlink) (`85a79ae`)
   - Group B (`feature/pep621-upstream-pr` @ `4a594c8`): [`feature/python-project-test-task`](https://github.com/KmoM88/colcon-core/tree/feature/python-project-test-task) (`d4b93bc`), [`feature/pep621-dynamic-metadata`](https://github.com/KmoM88/colcon-core/tree/feature/pep621-dynamic-metadata) (`49fcded`)
   - Specification & Verification Blueprint: [docs/plans/stage4_branch_plan.md](docs/plans/stage4_branch_plan.md)
   - ROS 2 Jazzy End-to-End PoC: [poc/README.md](poc/README.md) & [.github/workflows/ros2_pep621_poc.yml](.github/workflows/ros2_pep621_poc.yml) (run [40795039655](https://github.com/KmoM88/colcon-roadmap/actions/runs/40795039655))

---

## 3. Deprecation and Archival of `colcon-python-project`

Upon upstream acceptance and merging of the PRs into `colcon-core` and `colcon-ros`:
- Close PR #1 in [colcon/colcon-python-project](https://github.com/colcon/colcon-python-project/pull/1) pointing to native support in core.
- Archive the prototype repository with a deprecation notice.
