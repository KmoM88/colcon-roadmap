# Migration Status & Next Integration Steps

This document tracks the migration of modern Python packaging capabilities (PEP 517/518/621/660) from the prototype extension [colcon-python-project](file:///home/fede/github/kmom88/colcon-roadmap/submodules/colcon-python-project) into [colcon-core](file:///home/fede/github/kmom88/colcon-roadmap/submodules/colcon-core).

---

## 1. Status of Migration Phases

| Phase / Feature | Upstream Status | Description |
| :--- | :--- | :--- |
| **Hook Invocations** | **Merged** (PR #732) | `AsyncHookCaller` for executing backend hooks in isolated subprocess. |
| **Installed Distribution Discovery** | **Merged** (PR #728) | `InstalledDistribution` for discovering installed files on disk. |
| **Wheel Uninstallation** (`remove_distributions`) | **Merged** (PR #741) | Metadata-driven removal of previous installations and directory pruning. |
| **Wheel Installation Engine** (`install_wheel`) | **Merged** (PR #741) | Layout extraction, `.data/` directory mapping, script wrapping, and `RECORD` signing. |
| **PEP 621 Identification & Augmentation** | **In Progress** (`cottsay/pep621`) | Parsing `pyproject.toml` `[project]` static table and dependencies. |
| **Build Task Integration** (`PythonProjectBuildTask`) | **In Progress** (`cottsay/pep621`) | Hook caller execution + wheel install integration in build lifecycle. |
| **PEP 660 Editable Installation** | **Pending** | `build_editable` invocation and editable data-file handling. |

---

## 2. Next Integration Action: Build Task & Identification

The immediate next priority is validating and finalizing the PEP 621 & Build Task integration:

1. **Package Discovery & Identification**:
   - `colcon_core/package_identification/pep621.py`: Detect packages with `pyproject.toml` and determine package name.
   - `colcon_core/package_augmentation/pep621.py`: Parse dependencies from `project.dependencies` into colcon dependency model.

2. **Build Task Execution**:
   - `colcon_core/task/python_project/build.py`:
     1. Invoke `build_wheel` hook via `AsyncHookCaller`.
     2. Call `install_wheel` to unpack into the install base.
     3. Generate environment hooks and setup scripts.

3. **Validation & Testing**:
   - Unit tests: `test/test_package_identification_pep621.py`, `test/test_package_augmentation_pep621.py`, `test/test_task_python_project_build.py`.
   - Integration tests with real packages using `colcon build`.
