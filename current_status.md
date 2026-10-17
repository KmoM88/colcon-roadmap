# Current Status of PEP 517/518/621/660 Adoption in colcon-core

This document outlines the current state of PEP 517/518/621/660 standards adoption inside `colcon-core` and the surrounding ecosystem, reflecting recently merged upstream changes and active pull requests/branches.

---

## 1. Summary of Current Adoption

Significant components have been successfully merged into upstream `colcon-core`:
* **Hook Invocations (PR #732)**: `AsyncHookCaller` and decorator extension points.
* **Metadata & Distribution Discovery (PR #728)**: `InstalledDistribution` and installed file enumeration.
* **Wheel Installation Engine (PR #741)**: In-process wheel unpacking (`install_wheel`), RECORD signing, console script generation, and clean uninstallation (`remove_distributions`).

```
┌────────────────────────────────────────────────────────┐
│                      colcon-core                       │
│  [MERGED] PR #732: AsyncHookCaller (PEP 517 hooks)     │
│  [MERGED] PR #728: InstalledDistribution               │
│  [MERGED] PR #741: In-process Wheel Install & Removal  │
│  ────────────────────────────────────────────────────  │
│  [IN PROGRESS] cottsay/pep621:                         │
│   ├─ PEP 621 Package Identification                   │
│   ├─ Dependency Augmentation                           │
│   └─ Python Project Build Task Integration             │
└────────────────────────────────────────────────────────┘
```

---

## 2. Status within `colcon-core`

### What is Merged:
1. **`AsyncHookCaller`** (`colcon_core/python_project/hook_caller/__init__.py` - PR #732):
   Subprocess execution infrastructure to invoke standard PEP 517/518 backend hooks (e.g. `build_wheel`, `get_requires_for_build_wheel`) dynamically inside an isolated environment via pipes and pickle serialization.
2. **`InstalledDistribution`** (`colcon_core/python_project/distribution.py` - PR #728):
   Enumeration of installed files, namespaces, entry points, and bytecode caching paths across standard library directories (`purelib`, `platlib`).
3. **In-process Wheel Installation & Removal** (`colcon_core/python_project/wheel.py` - PR #741):
   * `remove_distributions(name, install_base)`: Queries live metadata on disk via `InstalledDistribution` to delete installed package files and prune empty parent directories.
   * `install_wheel(wheel_path, install_base, ...)`: Unpacks PEP 427 wheel archives, translates `.data/` directory contents (e.g., `share/`), generates executable console script wrappers using `distlib.scripts.ScriptMaker`, and writes valid PEP 376 `INSTALLER` and `RECORD` files.

### What is In Progress (Upstream Branch `cottsay/pep621`):
* **PEP 621 Package Identification** (`colcon_core/package_identification/pep621.py`):
  Identifies packages declaring `pyproject.toml` with `[project]` tables without requiring legacy `setup.cfg`/`setup.py`.
* **PEP 621 Package Augmentation** (`colcon_core/package_augmentation/pep621.py`):
  Extracts dependencies from `project.dependencies` and `project.optional-dependencies`.
* **Python Project Build Task** (`colcon_core/task/python_project/build.py`):
  Dispatches build tasks that invoke `build_wheel` via `AsyncHookCaller` and pass the resulting archive to `install_wheel`.

---

## 3. Next Features Needed

1. **Build Task Integration**:
   Finalize and stabilize the build task routing (`colcon_core/task/python_project/build.py` or within `colcon_core/task/python/build.py`) so `colcon build` can seamlessly build and install wheels for packages with `pyproject.toml`.
2. **Package Identification & Dynamic Requirements**:
   Ensure both static PEP 621 (`pyproject.toml` `[project]`) and dynamic backend hooks (`get_requires_for_build_wheel`) work cohesively.
3. **PEP 660 Editable Installs (`--symlink-install`)**:
   Support `build_editable` hook invocation and address non-Python data file linking (ROS launch files, URDFs, configuration files).

---

## 4. Testing & Verification Strategies

### A. Unit Tests
* **Wheel Installation & Cleanup**: Existing unit test suites in `test/test_install_wheel.py` and `test/test_remove_wheel.py`.
* **Identification & Augmentation**: Unit tests verifying that packages with `pyproject.toml` are correctly identified and their dependencies mapped to colcon dependency categories.

### B. Integration Tests with Real Workspaces
* **Self-Building Colcon Extensions**: Convert or test building colcon submodules (e.g. `colcon-output`, `colcon-defaults`) with a modern `pyproject.toml` using backends like `flit_core`, `hatchling`, or `setuptools.build_meta`.
* **Mock Sample Repositories**:
  1. Pure Python package with `flit_core` (no `setup.py`).
  2. Package with console scripts (verifying script generation under `install/bin`).
  3. Package with data files (verifying placement under `install/share`).
* **Verification Checks**:
  1. `colcon build --packages-select <sample_pkg>` completes with exit code 0.
  2. Executables in `install/bin` run correctly.
  3. Rebuilding after modifications uninstalls stale files via `remove_distributions`.
