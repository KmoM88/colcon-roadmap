# Stage 1: Core PEP 621 Pipeline & Multi-Backend Integration Suite

* **Parent Plan**: [PR, Branch, Feature & Release Plan](../README.md)
* **Historic Baseline**: [Historic PRs & Prototype Reference](../historic_prs_reference.md)

---

## 1. Branch & Pull Request Metadata

| Field | Value |
| :--- | :--- |
| **Stage** | Stage 1 (Release Wave 1) |
| **Status** | **Submitted & Open Upstream** |
| **Upstream Pull Request** | [colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750) |
| **Target Base Branch** | `colcon/colcon-core:cottsay/pep621` (`80acf29`) |
| **Feature Branch** | [`KmoM88/colcon-core:feature/pep621-upstream-pr`](https://github.com/KmoM88/colcon-core/tree/feature/pep621-upstream-pr) (Commit `4a594c8`) |
| **Intermediate Work Branches** | [`KmoM88/colcon-core:cottsay/pep621`](https://github.com/KmoM88/colcon-core/tree/cottsay/pep621) (`816a0d3`), [`KmoM88/colcon-core:feature/pep621-integration-tests`](https://github.com/KmoM88/colcon-core/tree/feature/pep621-integration-tests) (`c40901a`) |
| **GitHub Compare Diff** | [colcon/colcon-core:cottsay/pep621...KmoM88:colcon-core:feature/pep621-upstream-pr](https://github.com/colcon/colcon-core/compare/cottsay/pep621...KmoM88:colcon-core:feature/pep621-upstream-pr) |
| **PR Materials** | [pr_description_pep621.md](../../pr/pr_description_pep621.md), [issue_736_comment.md](../../pr/issue_736_comment.md), [pr_750_priority_comment.md](../../pr/pr_750_priority_comment.md) |

---

## 2. Context & Problem Statement

Upstream branch `colcon/colcon-core:cottsay/pep621` (`80acf29`) introduced the core `python.project` extensions (`PEP621PackageIdentification`, `PEP621PackageAugmentation`, and `PythonProjectBuildTask`), but two blockers prevented merging `cottsay/pep621` into `colcon/colcon-core:master`:

1. **Async Test Runner Incompatibility**: `test/test_task_python_project_build.py` decorated async tests with `@pytest.mark.asyncio`, which is not declared in `colcon-core`'s test dependencies (`setup.cfg` `[options.extras_require] test`) and breaks bootstrap CI environments that run `pytest` without third-party async plugins.
2. **Lack of Real PEP 517/660 Backend Verification**: All unit tests mocked `AsyncHookCaller` and `install_wheel`; there was no end-to-end integration coverage proving that real third-party build backends (`flit_core`, `hatchling`) build wheels, generate executable `[project.scripts]` wrappers, clean up deleted modules across rebuilds, and emit PEP 660 editable installations with PEP 610 `direct_url.json`.

---

## 3. Implementation Decisions & Trade-offs

1. **Target `cottsay/pep621` Rather Than `master` Directly**:
   - *Decision*: Opened [colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750) against `colcon/colcon-core:cottsay/pep621` instead of duplicating `80acf29` in a large PR against `master`.
   - *Rationale*: Preserves clean authorship on `80acf29` and isolates `#750`'s diff strictly to test-runner alignment and real-backend integration coverage so the branch author can merge `#750` into `cottsay/pep621` in one step.
2. **Use `run_until_complete` Instead of Adding `pytest-asyncio`**:
   - *Decision*: Reused `test/run_until_complete.py` (`from .run_until_complete import run_until_complete`), matching existing async task tests in `colcon-core`.
   - *Rationale*: Zero new test dependencies in `setup.cfg` and 100% compatibility with Debian/Ubuntu `stdeb` and bootstrap CI jobs.
3. **Graceful Backend Skipping via `pytest.importorskip`**:
   - *Decision*: Guarded each real-backend integration test with `pytest.importorskip('flit_core')` / `pytest.importorskip('hatchling')` (`editables`).
   - *Rationale*: Minimal CI runners (`stdeb`, `bootstrap`) without optional PEP 517 backends cleanly skip real-backend tests instead of failing collection, while developer and full environments execute the complete lifecycle.
4. **Keep Identification Priority (`PRIORITY = 90` vs `80`) Separate from `#750`**:
   - *Decision*: Documented the alphabetical tie between `'pep621'` (`PRIORITY = 90`) and `'python_setup_py'` (`PRIORITY = 90` in `colcon-python-setup-py`) in [pr_750_priority_comment.md](../../pr/pr_750_priority_comment.md) rather than modifying production identification priority inside `#750`.
   - *Rationale*: Keeps `#750` 100% test-scoped while preserving a ready-to-apply 1-line policy adjustment if maintainers prefer `setup.py` precedence on hybrid repositories.

---

## 4. Technical Solution

### Modified & Added Files
* **`test/test_task_python_project_build.py` [MODIFIED]**:
  - Removed `@pytest.mark.asyncio` and `async def` test signatures, wrapping `await task.build()` calls in `run_until_complete(task.build())`.
  - Sorted imports per `flake8-import-order` (`google` style).
* **`test/test_integration_pep621.py` [NEW]**:
  - `test_integration_flit_core_minimal`: Builds a pure `pyproject.toml` (`flit_core.buildapi`) package via `PEP621PackageIdentification` -> `PEP621PackageAugmentation` -> `PythonProjectBuildTask`, verifying `.dist-info/RECORD`, `INSTALLER`, environment scripts, and runtime `importlib` import from `install_base`.
  - `test_integration_hatchling_cli_scripts`: Builds a `hatchling.build` package declaring `[project.scripts]`, verifying executable wrapper generation in `<install_base>/bin/` (`Scripts/` on Windows) and subprocess execution output.
  - `test_integration_clean_rebuild`: Builds v1 (`mod_a.py`, `mod_b.py`), removes `mod_b.py` in v2, rebuilds into the same `install_base`, and verifies `remove_distributions()` purges `mod_b.py` and stale `.dist-info`.
  - `test_integration_symlink_install_editable`: Builds with `symlink_install=True` via `hatchling` (`editables`), verifying PEP 660 `build_editable`, PEP 610 `direct_url.json` (`{"dir_info": {"editable": true}}`), and live source-code edits reflected without rebuilding.

---

## 5. Validation & Verification Results

* **Core PEP 621 Unit Tests**: `19 passed` across `test_install_wheel.py`, `test_remove_wheel.py`, `test_package_identification_pep621.py`, `test_package_augmentation_pep621.py`, and `test_task_python_project_build.py`.
* **Multi-Backend Integration Suite**: `4 passed` in `test/test_integration_pep621.py` (`flit_core` and `hatchling` standard + PEP 660 editable lifecycles).
* **Linters**: `test_flake8.py`, `test_spell_check.py`, and `test_copyright_license.py` passing with 0 errors.

---

## 6. Upstream Merge & Release Readiness

1. Merge [colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750) into `colcon/colcon-core:cottsay/pep621`.
2. Open/merge `colcon/colcon-core:cottsay/pep621` into `colcon/colcon-core:master` (Wave 1), unblocking [Stage 2 (`#751`)](stage2_editable_data_files.md) and [Stage 4 Group B (`4A`, `4C`)](stage4_group_b_pep621_followups.md) rebases onto `master` in Wave 2.
