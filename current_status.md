# Current Status of PEP 517/518/621/660 Adoption in colcon-core

This document details the exact state of modern Python packaging standards (PEP 517/518/621/660) in `colcon-core`, incorporating the analysis of merged pull requests and upstream branches in active development.

---

## 1. Executive Summary

The modernization of Python builds in `colcon-core` has made substantial upstream progress:
* **PR #741 (Closed & Merged)**: The in-process wheel installation and uninstallation engine was officially merged into `colcon-core` (master, releases 0.21.2 / 0.21.3).
* **Branch `cottsay/pep621` (Upstream by Scott Logan)**: Implements native PEP 621 package identification, dependency augmentation, and the Python project build task (`PythonProjectBuildTask`), connecting directly to the `install_wheel` engine from PR #741.
* **Fork Branch `KmoM88/colcon-core:cottsay/pep621` (Commit `816a0d3`)**: Fixed async unit tests to adhere to `colcon-core` internal runner (`run_until_complete`), resolved flake8 import issues, verified 100% test suite pass rate (19/19 tests), and pushed to fork.

```
┌────────────────────────────────────────────────────────────────────────┐
│                              colcon-core                               │
│                                                                        │
│  [MERGED] PR #732: AsyncHookCaller (backend subprocess IPC)            │
│  [MERGED] PR #728: InstalledDistribution (installed file discovery)   │
│  [MERGED] PR #741: Wheel Engine (`install_wheel` & uninstallation)     │
│  ────────────────────────────────────────────────────────────────────  │
│  [UPSTREAM WIP] Branch `cottsay/pep621` (Scott K Logan, commit 80acf29)│
│  ├─ PEP621PackageIdentification (detects `pyproject.toml` [project])   │
│  ├─ PEP621PackageAugmentation (maps build/run/test dependencies)       │
│  ├─ PythonProjectBuildTask (builds wheel via hook -> `install_wheel`)  │
│  └─ PEP 610 Direct URL recording for editable installs (`build_editable)│
│  ────────────────────────────────────────────────────────────────────  │
│  [FORK VERIFIED] `KmoM88/colcon-core` (Commit 816a0d3)                 │
│  └─ Fixed async tests via `run_until_complete`, flake8 clean (19/19)   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. In-Depth Analysis: Merged PR #741 (Wheel Installation & Uninstallation)

* **PR**: [colcon/colcon-core#741](https://github.com/colcon/colcon-core/pull/741)
* **Author**: Federico Rossi (`KmoM88`)
* **Reviewer / Approver**: Scott K Logan (`cottsay`)
* **Merged at**: 2026-09-05 (Commit `845927c`, released in `v0.21.2` / `v0.21.3`)
* **Target File**: `colcon_core/python_project/wheel.py`

### Key Capabilities Introduced
1. **Metadata-Driven Removal (`remove_distributions`)**:
   - Queries `InstalledDistribution.discover` on disk (PR #728) to detect existing files of a distribution.
   - Deletes files, unlinks `.egg-link` files, and prunes empty parent directories up to `install_base`.
   - Windows-safe: Traps file lock errors (`PermissionError`, `OSError`) to avoid crashing active processes.
2. **In-Process Wheel Extractor (`install_wheel`)**:
   - Reads `.whl` ZIP archives without spawning external `pip` subprocesses.
   - Accurately maps library paths (`purelib` vs `platlib`) and translates `.data/` subdirectories (e.g. `share/`).
   - Generates executable script wrappers in `bin/` using `distlib.scripts.ScriptMaker`.
   - Writes PEP 376 `INSTALLER` ("colcon-core") and finalizes `RECORD` with SHA256 checksums and file sizes.
3. **Unit Tests**:
   - `test/test_install_wheel.py` (5 tests) & `test/test_remove_wheel.py` (4 tests) with 100% pass rate.

---

## 3. In-Depth Analysis: Scott Logan's Standard Python Builds (`cottsay/pep621`)

* **Upstream Branch**: `origin/cottsay/pep621` (on `colcon/colcon-core`)
* **Latest Commit**: `80acf29` ("WIP: Add support for PEP 621 projects")
* **Author**: Scott K Logan (`cottsay`)

Scott Logan implemented the missing pipeline pieces to connect the hook caller (PR #732) and wheel installer (PR #741):

### A. Package Identification (`colcon_core/package_identification/pep621.py`)
* Class: `PEP621PackageIdentification` (Priority = 90).
* Checks for `pyproject.toml` using `load_and_cache_spec(desc)`.
* If `[project].name` is defined, identifies the package type as `python.project`.
* Priority is deliberately lower than legacy `setup.cfg`/`setup.py` (priority 100), ensuring backward compatibility.

### B. Dependency Augmentation (`colcon_core/package_augmentation/pep621.py`)
* Class: `PEP621PackageAugmentation`.
* Maps dependencies directly from `pyproject.toml`:
  - `build-system.requires` $\rightarrow$ `build` dependencies.
  - `project.dependencies` $\rightarrow$ `run` dependencies.
  - `project.optional-dependencies.test` $\rightarrow$ `test` dependencies.
* Extracts metadata: `version`, `maintainers`, and `authors`.

### C. Build Task Execution (`colcon_core/task/python_project/build.py`)
* Class: `PythonProjectBuildTask` (registered for package type `python.project`).
* Reads `setup.cfg` if present for script-dir overrides.
* Resolves command environment via `get_command_environment('python_project', ...)`.
* Calls backend hook:
  - Default: `build_wheel` $\rightarrow$ outputs `.whl` into `<build_base>/wheel`.
  - With `--symlink-install`: checks if backend supports `build_editable`. If not, logs a warning and falls back to regular `build_wheel`.
* Directly calls `install_wheel(wheel_path, args.install_base, script_dir_override=...)` from PR #741.
* Generates colcon environment hooks and scripts, updating the `RECORD` index.
* For editable installs, writes PEP 610 `direct_url.json` (`{"dir_info": {"editable": true}}`) and appends it to `RECORD`.

### D. Testing & Quality Verification Assessment
* **Identification & Augmentation Tests**:
  `test_package_identification_pep621.py` (2 tests) and `test_package_augmentation_pep621.py` (4 tests) pass cleanly.
* **Build Task Tests (`test_task_python_project_build.py`)**:
  Previously marked with `@pytest.mark.asyncio`, which caused failures in standard `colcon-core` environments. Replaced with `from .run_until_complete import run_until_complete` in fork commit `816a0d3`. All 3 build task tests now pass cleanly.
* **Overall Unit Test Suite**:
  All 19 related unit tests (`install_wheel`, `remove_wheel`, `identification`, `augmentation`, `build_task`) pass at 100% (19 passed in 0.94s). Code style and import order validated with `flake8` without warnings.

---

## 4. Current Adoption Matrix

| Component | Status | Location / PR | Notes |
| :--- | :--- | :--- | :--- |
| **Backend Hook IPC** | **Merged** | PR #732 | `AsyncHookCaller` with pipes & pickle |
| **Installed File Discovery** | **Merged** | PR #728 | `InstalledDistribution` |
| **Wheel Uninstallation** | **Merged** | PR #741 | `remove_distributions` |
| **Wheel Installation** | **Merged** | PR #741 | `install_wheel`, RECORD writer, entry points |
| **PEP 621 Identification** | **Verified** | Fork commit `816a0d3` / `cottsay/pep621` | Priority 90, assigns `python.project` |
| **PEP 621 Augmentation** | **Verified** | Fork commit `816a0d3` / `cottsay/pep621` | Maps `[project.dependencies]` |
| **Python Project Build Task** | **Verified** | Fork commit `816a0d3` / `cottsay/pep621` | Calls `install_wheel` & writes hooks, async tests fixed |
| **PEP 660 Editable Hooks** | **Partial** | Fork commit `816a0d3` / `cottsay/pep621` | Dispatches `build_editable` + PEP 610 JSON |
| **ROS Data Files in Editable**| **Open Gap** | In Discussion | Non-Python data files in `share/` |
