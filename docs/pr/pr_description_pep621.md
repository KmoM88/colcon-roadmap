# Pull Request: Native Support for PEP 621 Standard Python Projects

**PR**: [colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750)  
**Target Base**: `colcon/colcon-core:cottsay/pep621`  
**Head Branch**: `KmoM88/colcon-core:feature/pep621-upstream-pr`  
**Direct Comparison URL**: [Compare on GitHub](https://github.com/colcon/colcon-core/compare/cottsay/pep621...KmoM88:colcon-core:feature/pep621-upstream-pr)

---

## Title
`feat: native support for PEP 621 standard Python projects`

---

## Description

### Summary
This PR introduces native support for building standard Python packages declared with `pyproject.toml` according to PEP 517, PEP 518, and PEP 621, without requiring legacy `setup.py` invocations.

It builds directly upon:
1. The backend hook caller infrastructure (PR #732).
2. The in-process wheel installation and uninstallation engine (`wheel.py`, PR #741, merged in v0.21.2).
3. The upstream groundwork by @cottsay in `cottsay/pep621`.

### Key Features Introduced

1. **Package Identification (`PEP621PackageIdentification`)**:
   - Inspects `pyproject.toml` for the `[project]` table using `load_and_cache_spec`.
   - Assigns package type `python.project`.
   - Configured with `PRIORITY = 90` (lower than legacy `setup.cfg`/`setup.py` at `100`), guaranteeing zero regressions for legacy packages.

2. **Dependency Augmentation (`PEP621PackageAugmentation`)**:
   - Maps static metadata from `[project]`:
     - `build-system.requires` $\rightarrow$ `build` dependencies.
     - `project.dependencies` $\rightarrow$ `run` dependencies.
     - `project.optional-dependencies.test` $\rightarrow$ `test` dependencies.
   - Extracts version, authors, and maintainers.

3. **Build Task (`PythonProjectBuildTask`)**:
   - Registered for package type `python.project`.
   - Dispatches `build_wheel` (or `build_editable` when `--symlink-install` is requested and supported by the backend).
   - Installs the resulting `.whl` in-process via `install_wheel` into the target `install_base`.
   - Records colcon environment hooks/scripts into `.dist-info/RECORD`.
   - Writes PEP 610 `direct_url.json` (`{"dir_info": {"editable": true}}`) for editable installations.

---

### Enhancements & Verification over Original WIP Branch

* **Async Test Runner Alignment**:
  Replaced `@pytest.mark.asyncio` in `test_task_python_project_build.py` with `colcon-core`'s canonical helper `from .run_until_complete import run_until_complete`. This eliminates external test harness dependencies on `pytest-asyncio`.
* **Code Style & Linters**:
  Import ordering and line lengths formatted strictly according to repository `flake8` standards (0 errors).
* **End-to-End Integration Suite (`test/test_integration_pep621.py`)**:
  Added automated end-to-end integration tests using real modern build backends:
  - `flit_core.buildapi`: Minimal pure PEP 621 project build, wheel extraction, runtime import.
  - `hatchling.build`: Console script entry points (`[project.scripts]`), wrapper generation in `bin/`, execution permissions (`0o755`), script execution.
  - Idempotent clean rebuild: Verification that `remove_distributions` removes deleted source files on subsequent builds.
  - Editable builds: `--symlink-install` verification calling `build_editable` with PEP 610 recording.

### Test Results
```bash
pytest test/test_package_identification_pep621.py \
       test/test_package_augmentation_pep621.py \
       test/test_task_python_project_build.py \
       test/test_install_wheel.py \
       test/test_remove_wheel.py \
       test/test_integration_pep621.py -v

============================== 23 passed in 0.74s ==============================
flake8: 0 errors
```

---

### Optional Rollout Safeguard: Feature Flag
While priority `90` already safeguards legacy workspaces, if preferred by maintainers for gradual adoption, the package identification can be optionally guarded behind:
```python
if not is_feature_flag_set('pep621_builds'):
    return
```
allowing early CI opt-in via `COLCON_FEATURE_FLAGS=pep621_builds` prior to general release.
