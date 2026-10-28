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

## Phase 3: Upstream Alignment & PR Submission [SUBMITTED AS PR #750]

* **PR**: [colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750)
* **Target Branch**: `colcon/colcon-core:cottsay/pep621`
* **Head Branch**: `KmoM88/colcon-core:feature/pep621-upstream-pr` (Commit `4a594c8`).
* **PR Artifacts**:
  - PR Description & Changelog: [docs/pr/pr_description_pep621.md](file:///home/fede/github/kmom88/colcon-roadmap/docs/pr/pr_description_pep621.md)
  - Issue #736 Update Comment: [docs/pr/issue_736_comment.md](file:///home/fede/github/kmom88/colcon-roadmap/docs/pr/issue_736_comment.md)
  - Comparison URL: [colcon/colcon-core:cottsay/pep621...KmoM88:colcon-core:feature/pep621-upstream-pr](https://github.com/colcon/colcon-core/compare/cottsay/pep621...KmoM88:colcon-core:feature/pep621-upstream-pr)

### Accomplished Items:
1. **Rebase & Polish**: [DONE]
   * Preserved Scott Logan (`cottsay`) commit authorship (`80acf29`) followed by the test runner fixes (`816a0d3`), integration suite (`c40901a`), and flake8/spell-check fixes (`4a594c8`).
2. **PR #750 Submitted**: [DONE]
   * Submitted to `cottsay/pep621` to facilitate seamless review and integration into the upstream branch.
3. **CI Linters & Verification**: [DONE]
   * Flake8 and `scspell3k` passing with 0 errors, 44/46 GitHub Actions checks passed (the remaining 2 were runner capacity cancellations on macOS).
4. **Issue #736 Update Prepared**: [DONE]
   * Technical response summarizing test results, `run_until_complete` alignment, and link to PR #750.

---

## Phase 4: PEP 660 Editable Installations & Non-Python Data Files [COMPLETED]

* **Feature Branch**: `feature/pep660-editable-data-files` in `submodules/kmom88-colcon-core` (Commit `de2050f`).
* **Implementation**:
  - `_get_data_files_mapping(pkg)` in `colcon_core/task/python_project/build.py` extracts non-Python data files defined in `setup.cfg` (`[options.data_files]`) or `pyproject.toml` (`[tool.setuptools.data-files]` and `[tool.hatch.build.targets.wheel.shared-data]`).
  - When `--symlink-install` is active, invokes `colcon_core.task.install()` to create real symbolic links from source to `install_base` (e.g. `share/<package>/launch`), and registers each installed target into `.dist-info/RECORD`.
  - Enables true editable workflows for ROS 2 launch files, parameter files, and configuration assets without rebuilding.
* **Testing & Verification**:
  - Added `test_integration_symlink_install_data_files` to `test/test_integration_pep621.py`.
  - Validates live editing of source launch files and verification of symlinks on disk.
  - All 24 unit & integration tests passing in 0.70s, `flake8` clean (0 errors), pushed to `KmoM88/colcon-core`.

---

## Phase 5: ROS 2 `ament_python` Modernization in `colcon-ros` [COMPLETED]

* **Feature Branch**: `feature/ros-ament-python-project` in `submodules/colcon-ros` (`KmoM88/colcon-ros`, Commit `fc03806`).
* **Implementation**:
  - `AmentPythonBuildTask` in `colcon_ros/task/ament_python/build.py` automatically detects packages specifying `<build_type>ament_python</build_type>` with `pyproject.toml` (and no `setup.py`).
  - Routes execution to `PythonProjectBuildTask` while preserving ROS index registration (`share/ament_index/...`), `package.xml` placement, and `AMENT_PREFIX_PATH` environment hooks.
* **Testing & Verification**:
  - Added automated test `test/test_task_ament_python_build.py` exercising an end-to-end `ament_python` build with `flit_core`.
  - Verified marker creation in `ament_index`, `package.xml` copying, `.dsv` hook creation, and module installation.
  - Flake8 clean (0 errors) and test passing (`PASSED in 0.13s`).

---

## Phase 6: Deprecation and Archival of `colcon-python-project`

Once native support is merged in `colcon-core` and `colcon-ros`:
1. Document the deprecation of the monolithic prototype repository (`colcon/colcon-python-project`).
2. Close PR #1 in `colcon-python-project` pointing to the official native implementation in `colcon-core`.
