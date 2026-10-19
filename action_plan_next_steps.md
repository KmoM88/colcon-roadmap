# Action Plan: Next Steps for PEP 621 / Standard Python Builds

This document defines the actionable, step-by-step roadmap for validating, finalizing, and integrating PEP 621 standard Python builds in `colcon-core`, building upon the merged PR #741 and Scott Logan's upstream branch `cottsay/pep621`.

---

## Phase 1: Harmonize & Validate the `cottsay/pep621` Implementation [COMPLETED]

Scott Logan's branch `origin/cottsay/pep621` provides the core implementation of PEP 621 identification, dependency augmentation, and build task execution.

### Action Items & Completed Results
1. **Branch Tracking & Sync**: [DONE]
   * Tracking branch checked out in fork `submodules/kmom88-colcon-core`:
     ```bash
     git -C submodules/kmom88-colcon-core checkout -b cottsay/pep621 upstream/cottsay/pep621
     ```
2. **Align Async Tests with colcon-core Conventions**: [DONE]
   * Replaced `@pytest.mark.asyncio` in `test/test_task_python_project_build.py` with `from .run_until_complete import run_until_complete`.
   * Formatted imports according to `flake8` standards.
   * Committed in `816a0d3` (*"fix: adapt async tests and clean up import formatting for PEP 621"*).
   * Pushed to fork: [`KmoM88/colcon-core`](https://github.com/KmoM88/colcon-core) on branch `cottsay/pep621`.
3. **Run Unit Tests & Code Quality Suite**: [DONE]
   * All 19 related unit tests pass cleanly:
     - `test_install_wheel.py` (5 passed)
     - `test_remove_wheel.py` (4 passed)
     - `test_package_identification_pep621.py` (2 passed)
     - `test_package_augmentation_pep621.py` (4 passed)
     - `test_task_python_project_build.py` (3 passed)
   * `flake8` and repository style standards pass with 0 errors.

---

## 2. Feature Branches & Multi-Repository Architecture

To structure the remaining work without risking regressions and ensuring clean upstream contributions, the development is organized across dedicated feature branches in the forks of `colcon-core` and `colcon-ros`:

| Repository | Fork Target | Base Branch | Feature Branch | Objective |
| :--- | :--- | :--- | :--- | :--- |
| **`colcon-core`** | `KmoM88/colcon-core` | `cottsay/pep621` (`816a0d3`) | `feature/pep621-integration-tests` | Automated end-to-end integration tests using real backends (`flit_core`, `hatchling`, `setuptools`). |
| **`colcon-core`** | `KmoM88/colcon-core` | `feature/pep621-integration-tests` | `feature/pep621-upstream-pr` | Rebased, clean branch against upstream `colcon/colcon-core:master` formatted for PR submission. |
| **`colcon-core`** | `KmoM88/colcon-core` | `feature/pep621-upstream-pr` | `feature/pep660-editable-data-files` | Handling `--symlink-install` and data files (`share/`) for editable installations. |
| **`colcon-ros`** | `KmoM88/colcon-ros` | `upstream/master` | `feature/ros-ament-python-project` | Adapter in `colcon-ros` so packages with `<build_type>ament_python</build_type>` and `pyproject.toml` use standard Python build tasks. |

---

## Phase 2: Integration Testing with Real Packages & Submodules [COMPLETED]

* **Feature Branch**: `feature/pep621-integration-tests` in `submodules/kmom88-colcon-core` (Commit `c40901a`).
* **Test Suite Added**: `test/test_integration_pep621.py` (Passed 4/4 integration tests, 23/23 total suite tests).

### Validated Test Scenarios

| Test Case | Build Backend | Features Tested | Verification Result |
| :--- | :--- | :--- | :--- |
| **`test_integration_flit_core_minimal`** | `flit_core.buildapi` | Pure PEP 621, identification, wheel generation, installation, runtime import | **PASSED** (0.45s) |
| **`test_integration_hatchling_cli_scripts`** | `hatchling.build` | `[project.scripts]` entry points, execution wrapper in `bin/`, `0o755` permissions | **PASSED** (CLI output verified) |
| **`test_integration_clean_rebuild`** | `flit_core.buildapi` | Idempotent builds & `remove_distributions` ensuring deleted source files vanish from `install/` | **PASSED** (residual files purged) |
| **`test_integration_symlink_install_editable`** | `hatchling.build` | `--symlink-install` calling `build_editable`, PEP 610 `direct_url.json`, live editing | **PASSED** (live updates verified) |

---

## Phase 3: Upstream Alignment & PR Submission [IN PROGRESS]

* **Active Feature Branch**: `feature/pep621-upstream-pr` in `submodules/kmom88-colcon-core`.

Once the implementation is validated with real backends:
1. **Rebase & Polish**:
   * Rebase branch onto latest `colcon/colcon-core:master` (`6bfb100+`).
   * Preserve Scott Logan (`cottsay`) commit authorship for original PEP 621 groundwork (`80acf29`) and include co-authored/subsequent commits for the test runner fix (`816a0d3`) and integration suite.
2. **Engage with Upstream on Issue #736**:
   * Post a comprehensive technical update on upstream issue [#736](https://github.com/colcon/colcon-core/issues/736) reporting full test suite passes (19/19 + integration tests).
   * Propose opening a PR targeting `colcon/colcon-core:master` (or alternatively providing a PR directly into Scott Logan's `cottsay/pep621` fork branch).
3. **Feature Flag Rollout Strategy (`COLCON_FEATURE_FLAGS`)**:
   * `colcon-core` provides a native feature flag mechanism via `colcon_core.feature_flags.is_feature_flag_set` (controlled by `COLCON_FEATURE_FLAGS`).
   * **Proposal for Upstream Merge**: If maintainers express caution regarding potential workspace side-effects, offer to guard `PEP621PackageIdentification` behind a feature flag (e.g. `is_feature_flag_set('pep621_builds')` or `python_project`).
   * When unset, legacy workspaces remain completely untouched; when set (or once promoted to `IMPLEMENTED_FLAGS` in a subsequent minor release), standard Python discovery activates.
   * This gives maintainers a zero-risk path to merge the code into `colcon-core:master` without waiting for a breaking release.
4. **Open Pull Request**:
   * Submit the PR with detailed testing evidence, rationale for `run_until_complete` over `pytest-asyncio`, verification with multiple backends, and the feature flag option.

---

## Phase 4: PEP 660 Editable Installations & Non-Python Data Files

* **Active Feature Branch**: `feature/pep660-editable-data-files` in `submodules/kmom88-colcon-core`.

Once standard builds are solid, close the remaining editable gaps:
1. **Backend Editable Compatibility**:
   * Verify how backends (`setuptools`, `flit_core`, `hatchling`) generate editable wheels via `build_editable`.
   * Validate PEP 610 `direct_url.json` (`{"dir_info": {"editable": true}}`) writing.
2. **Non-Python Asset Symlinking (ROS Data Files)**:
   * PEP 660 only makes Python code live-editable via `.pth` or loader hooks. Assets copied into `share/` are static in the wheel.
   * Design a mechanism to ensure non-code files (such as ROS launch files, URDFs, configurations) can be optionally symlinked to the source directory when `--symlink-install` is used.

---

## Phase 5: ROS 2 `ament_python` Modernization in `colcon-ros`

* **Active Feature Branch**: `feature/ros-ament-python-project` in `submodules/colcon-ros` (`KmoM88/colcon-ros`).

To enable ROS 2 packages to take full advantage of Python standard packaging:
1. **Identify `ament_python` with `pyproject.toml`**:
   * In `colcon-ros`, inspect packages with `<build_type>ament_python</build_type>` in `package.xml`.
   * If a `pyproject.toml` with `[project]` is present and no `setup.py` exists, route package building to the modern pipeline.
2. **Implement `AmentPythonProjectBuildTask`**:
   * Create an ament task that delegates to `PythonProjectBuildTask` from `colcon-core`.
   * Automatically append `AMENT_PREFIX_PATH` hooks and verify the `package index` registration in `<install_base>/share/ament_index/`.
3. **Testing**:
   * Validate building a sample ROS 2 package using PEP 621 without `setup.py`.

---

## Phase 6: Deprecation and Archival of `colcon-python-project`

Once native support is merged in `colcon-core` and `colcon-ros`:
1. Document the deprecation of the monolithic prototype repository (`colcon/colcon-python-project`).
2. Close PR #1 in `colcon-python-project` pointing to the official native implementation in `colcon-core`.
