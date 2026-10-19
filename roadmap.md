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

## 3. Active & Next Features (Feature Branches Architecture)

The ongoing work is organized into dedicated feature branches across `colcon-core` and `colcon-ros`:

| Feature Branch | Repository | Status | Focus |
| :--- | :--- | :--- | :--- |
| `cottsay/pep621` (`816a0d3`) | `KmoM88/colcon-core` | **Validated in Fork** | PEP 621 identification, augmentation, build task & runner fix |
| `feature/pep621-integration-tests` | `KmoM88/colcon-core` | **Active / Next** | Real multi-backend fixtures (`flit`, `hatchling`, `setuptools`) |
| `feature/pep621-upstream-pr` | `KmoM88/colcon-core` | **Pending Phase 2** | Upstream PR to `colcon/colcon-core:master` / Scott Logan |
| `feature/pep660-editable-data-files` | `KmoM88/colcon-core` | **Planned** | Editable installs & symlinked data files |
| `feature/ros-ament-python-project` | `KmoM88/colcon-ros` | **Planned** | Modernization of `ament_python` to accept PEP 621 |

### Feature 1: PEP 621 Package Identification & Augmentation
* **Status**: Implemented & Validated in fork (branch `cottsay/pep621`, commit `816a0d3`).
* **Scope**:
  - `colcon_core/package_identification/pep621.py`: Detect directories containing `pyproject.toml` with `[project]` table and identify package name/type.
  - `colcon_core/package_augmentation/pep621.py`: Parse `project.dependencies` into build/run/test dependencies.
* **Validation**: `test_package_identification_pep621.py` & `test_package_augmentation_pep621.py` passing cleanly (6/6 tests).

### Feature 2: PEP 517/621 Build Task Integration
* **Status**: Implemented & Validated in fork (branch `cottsay/pep621`, commit `816a0d3`).
* **Scope**:
  - `colcon_core/task/python_project/build.py`: Implement task handler for PEP 517 projects.
  - Invoke `build_wheel` using `AsyncHookCaller`.
  - Call `install_wheel` to install the generated `.whl` into the target `install_base`.
  - Ensure CLI flags (`--install-base`, `--symlink-install` fallbacks) are respected.
* **Validation**: Fixed async test runner via `run_until_complete`. All build task tests pass cleanly (3/3 tests). Ready for integration tests with real packages.
* **Feature Flag Guard (`COLCON_FEATURE_FLAGS`)**: Available as an optional transition safeguard via `is_feature_flag_set('pep621_builds')` to facilitate upstream merge without risk of breaking existing workspaces.

### Feature 3: PEP 660 Editable Installation (`--symlink-install`) & Data Files
* **Status**: In progress / Planned (`feature/pep660-editable-data-files`).
* **Scope**:
  - Invoke `build_editable` hook when `--symlink-install` is specified.
  - Graceful fallback to standard wheel install if the backend does not support `build_editable`.
  - Resolve the ROS data file linking gap: ensure non-Python assets (`launch/`, `urdf/`, `config/`) in `share/` remain symlinked or live-editable.

### Feature 4: ROS 2 `ament_python` with Standard Python Builds
* **Status**: Implemented & Validated in fork (branch `feature/ros-ament-python-project`, commit `fc03806` in `colcon-ros`).
* **Scope**:
  - Detect `package.xml` (`<build_type>ament_python</build_type>`) packages using `pyproject.toml` without `setup.py`.
  - Bridge `colcon-ros` with `PythonProjectBuildTask` while preserving ROS-specific index registration and environment hooks.
* **Validation**: Verified end-to-end with `test_task_ament_python_build.py` (passes 100%, 0 flake8 errors). Ready for upstream collaboration.

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