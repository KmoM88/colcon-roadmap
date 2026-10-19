# Roadmap: Native PEP 517/518/621/660 Support in colcon-core

This roadmap outlines the plan to bring modern Python packaging standards (PEP 517/518/621/660) to `colcon`, replacing legacy `setup.py` invocations while maintaining backward compatibility with existing ROS and Python workspaces.

---

## 1. Context & Motivation

* **Standards Modernization**: The Python packaging ecosystem has deprecated direct invocations of `setup.py install` and `setup.py develop` in favor of standard build backends (Flit, Hatchling, Setuptools build_meta) declared in `pyproject.toml`.
* **Standardized Metadata**: Dependencies and package definitions are standardized in `pyproject.toml` (`[build-system]` and `[project]`).
* **Goal**: Provide native support in `colcon-core` so Python packages with standard `pyproject.toml` can be discovered, built, installed, and uninstalled cleanly without external shims.

---

## 2. Completed Milestones

- [x] **PR #732: Hook Caller Infrastructure (`AsyncHookCaller`)**
  - Subprocess execution channel for backend hooks (`build_wheel`, `get_requires_for_build_wheel`) via OS pipes and pickle serialization.
  - Extension point `HookCallerDecoratorExtensionPoint`.
  - TOML parser loader (`toml_loads`) with standard `tomllib` (Python 3.11+) and fallbacks.

- [x] **PR #728: Distribution Metadata Discovery (`InstalledDistribution`)**
  - Live query and discovery of installed Python files, packages, namespaces, entry points, and bytecode caching (`.pyc`).

- [x] **PR #741: In-Process Wheel Installation & Uninstallation Engine (`wheel.py`)**
  - `remove_distributions`: Cleanly uninstalls previous package installations using disk metadata.
  - `install_wheel`: Unpacks `.whl` archives, maps `.data/` directories (e.g. `share/`), generates executable entry-point script wrappers via `distlib.scripts.ScriptMaker`, and writes valid `INSTALLER` and `RECORD` files.
  - Unit tests covering wheel extraction, removal, and script generation.

---

## 3. Implemented Features & PR Status (Feature Branches Architecture)

The technical implementation is completed across dedicated feature branches in `colcon-core` and `colcon-ros`, with test suites passed and PR submission packages generated:

| Feature Branch | Repository | Status | Focus & Deliverable |
| :--- | :--- | :--- | :--- |
| `cottsay/pep621` (`816a0d3`) | `KmoM88/colcon-core` | **Completed** | Fixed async test runner (`run_until_complete`), PEP 621 identification, augmentation & build task. |
| `feature/pep621-integration-tests` (`c40901a`) | `KmoM88/colcon-core` | **Completed** | Real multi-backend fixtures (`flit_core`, `hatchling`), CLI scripts, clean rebuilds. |
| `feature/pep621-upstream-pr` (`c40901a`) | `KmoM88/colcon-core` | **Ready for Submission** | Clean rebase on `upstream/master`, PR package prepared ([docs/pr/pr_description_pep621.md](file:///home/fede/github/kmom88/colcon-roadmap/docs/pr/pr_description_pep621.md)). |
| `feature/pep660-editable-data-files` (`de2050f`) | `KmoM88/colcon-core` | **Completed** | Symlink data files in `share/` during `--symlink-install` ([docs/pr/pr_description_pep660_data_files.md](file:///home/fede/github/kmom88/colcon-roadmap/docs/pr/pr_description_pep660_data_files.md)). |
| `feature/ros-ament-python-project` (`fc03806`) | `KmoM88/colcon-ros` | **Completed** | `ament_python` with PEP 621 / `pyproject.toml` ([docs/pr/pr_description_colcon_ros.md](file:///home/fede/github/kmom88/colcon-roadmap/docs/pr/pr_description_colcon_ros.md)). |

### Feature 1: PEP 621 Package Identification & Augmentation [COMPLETED]
* **Status**: Implemented & Validated in fork (commit `816a0d3`).
* **Scope**:
  - `colcon_core/package_identification/pep621.py`: Detect directories containing `pyproject.toml` with `[project]` table and identify package name/type.
  - `colcon_core/package_augmentation/pep621.py`: Parse `project.dependencies` into build/run/test dependencies.
* **Validation**: `test_package_identification_pep621.py` & `test_package_augmentation_pep621.py` passing cleanly (6/6 tests).

### Feature 2: PEP 517/621 Build Task Integration [COMPLETED]
* **Status**: Implemented & Validated in fork (commit `816a0d3` and `c40901a`).
* **Scope**:
  - `colcon_core/task/python_project/build.py`: Task handler for standard PEP 517 projects.
  - Invokes `build_wheel` using `AsyncHookCaller`.
  - Calls `install_wheel` to unpack into `install_base`.
  - Generates environment scripts and hooks into `.dist-info/RECORD`.
* **Validation**: Fixed async test runner via `run_until_complete`. End-to-end integration tests with real backends passing (100% test pass rate).
* **Feature Flag Guard (`COLCON_FEATURE_FLAGS`)**: Gating available via `is_feature_flag_set('pep621_builds')` to facilitate upstream merge without risk of breaking existing workspaces.

### Feature 3: PEP 660 Editable Installation (`--symlink-install`) & Data Files [COMPLETED]
* **Status**: Implemented & Validated in fork (commit `de2050f`).
* **Scope**:
  - Dispatches `build_editable` hook when `--symlink-install` is specified.
  - Added `_get_data_files_mapping()`: discovers `setup.cfg` (`[options.data_files]`) and `pyproject.toml` (`[tool.setuptools.data-files]`, `[tool.hatch.build.targets.wheel.shared-data]`).
  - Creates true filesystem symlinks for `share/` assets (launch files, parameter files) to keep them live-editable without rebuilds.
* **Validation**: `test_integration_symlink_install_data_files` passing in `test/test_integration_pep621.py`.

### Feature 4: ROS 2 `ament_python` with Standard Python Builds [COMPLETED]
* **Status**: Implemented & Validated in fork (`feature/ros-ament-python-project`, commit `fc03806` in `colcon-ros`).
* **Scope**:
  - Detect `package.xml` (`<build_type>ament_python</build_type>`) packages using `pyproject.toml` without `setup.py`.
  - Bridge `colcon-ros` with `PythonProjectBuildTask` while preserving ROS-specific index registration (`share/ament_index/...`), `package.xml` placement, and `AMENT_PREFIX_PATH` hooks.
* **Validation**: Verified end-to-end with `test_task_ament_python_build.py` (passes 100%, 0 flake8 errors). Ready for upstream submission.

---

## 4. Testing & Validation Plan

### 4.1 Unit Testing
* Execute test suites inside `submodules/colcon-core`:
  ```bash
  pytest test/test_install_wheel.py test/test_remove_wheel.py test/test_package_identification_pep621.py test/test_package_augmentation_pep621.py test/test_task_python_project_build.py
  ```

### 4.2 Local Integration Testing
* **Test Package Types**:
  1. **Pure PEP 621 package**: Minimal Python package using `flit_core` or `hatchling` (only `pyproject.toml`, no `setup.py`).
  2. **Package with console scripts**: Testing that executables generated in `<install_base>/bin` work properly.
  3. **Package with data files**: Testing mapping to `<install_base>/share/<pkg_name>`.
  4. **Self-hosted Colcon extensions**: Testing building submodules present in the workspace.
* **Testing Steps**:
  ```bash
  # 1. Clean build
  colcon build --packages-select <test_package>
  
  # 2. Verify files in install directory
  ls -la install/<test_package>
  
  # 3. Rebuild (verify removal of old files and re-installation)
  colcon build --packages-select <test_package>
  ```