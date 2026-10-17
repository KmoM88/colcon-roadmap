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

## 3. Active & Next Features

### Feature 1: PEP 621 Package Identification & Augmentation
* **Status**: In progress upstream (branch `cottsay/pep621`).
* **Scope**:
  - `colcon_core/package_identification/pep621.py`: Detect directories containing `pyproject.toml` with `[project]` table and identify package name/type.
  - `colcon_core/package_augmentation/pep621.py`: Parse `project.dependencies` into build/run/test dependencies.

### Feature 2: PEP 517/621 Build Task Integration
* **Status**: In progress upstream (branch `cottsay/pep621`).
* **Scope**:
  - `colcon_core/task/python_project/build.py`: Implement task handler for PEP 517 projects.
  - Invoke `build_wheel` using `AsyncHookCaller`.
  - Call `install_wheel` to install the generated `.whl` into the target `install_base`.
  - Ensure CLI flags (`--install-base`, `--symlink-install` fallbacks) are respected.

### Feature 3: PEP 660 Editable Installation (`--symlink-install`)
* **Scope**:
  - Invoke `build_editable` hook when `--symlink-install` is specified.
  - Graceful fallback to standard wheel install if the backend does not support `build_editable`.
  - Resolve the ROS data file linking gap: ensure non-Python assets (`launch/`, `urdf/`, `config/`) in `share/` remain symlinked or live-editable.

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