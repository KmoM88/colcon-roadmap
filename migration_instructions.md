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
| **PEP 660 Editable & Data Files** | **Completed & Validated** | `build_editable` invocation + symlinking data files in `share/`. |
| **ROS 2 `ament_python` PEP 621** | **Completed & Validated** | Native routing in `colcon-ros` for packages declaring only `pyproject.toml`. |

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

4. **Stage 4 Follow-Up Branch Plan (`colcon-core` Group A & Group B)**:
   - Specification: [docs/plans/stage4_branch_plan.md](docs/plans/stage4_branch_plan.md)
   - ROS 2 Jazzy End-to-End PoC: [poc/README.md](poc/README.md) & [.github/workflows/ros2_pep621_poc.yml](.github/workflows/ros2_pep621_poc.yml)

---

## 3. Deprecation and Archival of `colcon-python-project`

Upon upstream acceptance and merging of the PRs into `colcon-core` and `colcon-ros`:
- Close PR #1 in [colcon/colcon-python-project](https://github.com/colcon/colcon-python-project/pull/1) pointing to native support in core.
- Archive the prototype repository with a deprecation notice.
