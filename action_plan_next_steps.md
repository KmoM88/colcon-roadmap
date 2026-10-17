# Action Plan: Next Steps for PEP 621 / Standard Python Builds

This document defines the actionable, step-by-step roadmap for validating, finalizing, and integrating PEP 621 standard Python builds in `colcon-core`, building upon the merged PR #741 and Scott Logan's upstream branch `cottsay/pep621`.

---

## Phase 1: Harmonize & Validate the `cottsay/pep621` Implementation

Scott Logan's branch `origin/cottsay/pep621` provides the core implementation of PEP 621 identification, dependency augmentation, and build task execution.

### Action Items
1. **Branch Tracking & Sync**:
   * Create a dedicated tracking branch in `submodules/kmom88-colcon-core`:
     ```bash
     git -C submodules/kmom88-colcon-core checkout -b feature/pep621-standard-builds upstream/cottsay/pep621
     ```
2. **Align Async Tests with colcon-core Conventions**:
   * Replace `@pytest.mark.asyncio` in `test/test_task_python_project_build.py` with `from .run_until_complete import run_until_complete`.
   * This removes the external dependency on `pytest-asyncio` and adheres to repository standards.
3. **Run Unit Tests & Code Quality Suite**:
   * Execute unit tests using the local virtual environment:
     ```bash
     PYTHONPATH=submodules/kmom88-colcon-core \
     submodules/kmom88-colcon-core/.venv/bin/pytest \
       submodules/kmom88-colcon-core/test/test_package_identification_pep621.py \
       submodules/kmom88-colcon-core/test/test_package_augmentation_pep621.py \
       submodules/kmom88-colcon-core/test/test_task_python_project_build.py \
       submodules/kmom88-colcon-core/test/test_install_wheel.py \
       submodules/kmom88-colcon-core/test/test_remove_wheel.py
     ```
   * Run repository linters (`flake8`, `pydocstyle`) configured in `setup.cfg`.

---

## Phase 2: Integration Testing with Real Packages & Submodules

To verify end-to-end functionality beyond unit tests, test the full build lifecycle using real Python packages.

### Test Matrix

| Test Case | Build Backend | Features Tested | Verification Criteria |
| :--- | :--- | :--- | :--- |
| **Case A: Minimal PEP 621** | `flit_core` | Pure `pyproject.toml`, no `setup.py` | Package discovered as `python.project`, wheel built and installed in `install/`. |
| **Case B: Console Scripts** | `hatchling` | Entry point CLI generation | Wrapper generated in `install/bin/`, executable bit set (`0o755`), script executes correctly. |
| **Case C: Data Files** | `setuptools.build_meta` | Data files mapped to `share/` | Data files placed into `install/share/<pkg_name>/`. |
| **Case D: Clean Rebuild** | Any | Idempotent build & `remove_distributions` | Modifying/removing files and rebuilding cleanly removes stale files without residuals. |
| **Case E: Self-Hosted Submodule** | Setuptools | Converting a submodule (e.g. `colcon-output`) | Verified building a core colcon extension using the new pipeline. |

### Execution Workflow
1. Create mock package fixtures under `test/fixtures/` or a temporary workspace directory:
   ```
   workspace/
   └── src/
       └── sample_flit_pkg/
           ├── pyproject.toml
           └── sample_flit_pkg/
               └── __init__.py
   ```
2. Invoke `colcon build` with the development version of `colcon-core` loaded:
   ```bash
   colcon build --packages-select sample_flit_pkg
   ```
3. Inspect the resulting `install/` directory and test execution of any generated CLI entry points.

---

## Phase 3: Upstream Alignment & PR Submission

Once the implementation is validated and test-covered:
1. **Prepare Pull Request**:
   * Compare `cottsay/pep621` + test fixes against `colcon/colcon-core:master`.
   * Ensure documentation and docstrings are complete.
2. **Engage with Upstream on Issue #736**:
   * Post an update on issue #736 documenting the verification of the PEP 621 pipeline and offering test results / PR collaboration.
   * Coordinate with Scott Logan (`cottsay`) regarding whether to submit a PR directly targeting `master` or providing fixes into his branch.

---

## Phase 4: PEP 660 Editable Installation & Data Files

Once standard builds are solid, tackle the remaining editable gap:
1. **Backend Editable Compatibility**:
   * Verify how backends (`setuptools`, `flit_core`, `hatchling`) generate editable wheels via `build_editable`.
   * Validate PEP 610 `direct_url.json` recording.
2. **ROS Data File Symlinking**:
   * Assess how non-Python assets (`launch/`, `urdf/`, `config/`) in ROS packages can maintain live editability without requiring manual rebuilds.
