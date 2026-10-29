# Stage 4 — Group B: Stacked `cottsay/pep621` Follow-Up Branches (`4A` & `4C`)

* **Parent Plan**: [PR, Branch, Feature & Release Plan](../README.md)
* **Stacked Ancestor**: [Stage 1: Core PEP 621 Pipeline](stage1_core_pep621.md) (`feature/pep621-upstream-pr` @ `4a594c8`)
* **Branch Blueprint**: [stage4_branch_plan.md](../../plans/stage4_branch_plan.md)

---

## 1. Branch & Fork CI Validation Metadata

| Field | Branch 3 — Stage 4A (`TASK-8`) | Branch 4 — Stage 4C (`TASK-9`) |
| :--- | :--- | :--- |
| **Release Wave** | Wave 2 (Stacked on `#750` -> `colcon-core:master`) | Wave 2 (Stacked on `#750` -> `colcon-core:master`) |
| **Status** | **Implemented, Pushed to Fork & 44/44 Fork-CI Green** *(no upstream PR opened)* | **Implemented, Pushed to Fork & 44/44 Fork-CI Green** *(no upstream PR opened)* |
| **Feature Branch** | [`KmoM88/colcon-core:feature/python-project-test-task`](https://github.com/KmoM88/colcon-core/tree/feature/python-project-test-task) (`d4b93bc`) | [`KmoM88/colcon-core:feature/pep621-dynamic-metadata`](https://github.com/KmoM88/colcon-core/tree/feature/pep621-dynamic-metadata) (`49fcded`) |
| **Base Commit** | `KmoM88/colcon-core:feature/pep621-upstream-pr` (`4a594c8`) | `KmoM88/colcon-core:feature/pep621-upstream-pr` (`4a594c8`) |
| **Fork Compare Diff** | [KmoM88/colcon-core:feature/pep621-upstream-pr...feature/python-project-test-task](https://github.com/KmoM88/colcon-core/compare/feature/pep621-upstream-pr...feature/python-project-test-task) | [KmoM88/colcon-core:feature/pep621-upstream-pr...feature/pep621-dynamic-metadata](https://github.com/KmoM88/colcon-core/compare/feature/pep621-upstream-pr...feature/pep621-dynamic-metadata) |
| **Fork CI Validation PR** | [KmoM88/colcon-core#5](https://github.com/KmoM88/colcon-core/pull/5) ([Run 40802478808](https://github.com/KmoM88/colcon-core/actions/runs/40802478808) — **44/44 jobs green**) | [KmoM88/colcon-core#5](https://github.com/KmoM88/colcon-core/pull/5) ([Run 40802478808](https://github.com/KmoM88/colcon-core/actions/runs/40802478808) — **44/44 jobs green**) |
| **Pitfalls Remediated** | Pitfall 2 (`colcon test` execution & PEP 621 / PEP 735 test options for pure `python.project`) | Pitfall 7 (`project.dynamic` resolution via `load_and_cache_metadata` & PEP 517 `build_wheel` fallback) |

---

## 2. Branch 3 (Stage 4A): `feature/python-project-test-task` (`d4b93bc`)

### Problem Statement
1. On `cottsay/pep621`, `setup.cfg` registered `python.project` under `colcon_core.task.build` (`PythonProjectBuildTask`), but did not register `python.project` under `colcon_core.task.test`. Running `colcon test` on a pure non-ROS PEP 621 package skipped test execution completely.
2. `PythonTestTask.test()` calls `get_setup_data(pkg, env)` (`pkg.metadata['get_python_setup_options'](env)`) so `PytestPythonTestingStep.match()` can check `has_test_dependency(setup_py_data, 'pytest')`. `PEP621PackageAugmentation` on `cottsay/pep621` never populated `get_python_setup_options` and only inspected `[project.optional-dependencies].test`, missing `tests`/`testing` extras and PEP 735 `[dependency-groups]`.

### Implementation Decisions
1. **Subclass `PythonTestTask` with No-Op `add_arguments`**:
   - `PythonTestTask.add_arguments()` already registers `--python-testing`, `--pytest-args`, and `--pytest-with-coverage` on the `test` verb parser. Overriding `PythonProjectTestTask.add_arguments(self, *, parser): pass` prevents `argparse.ArgumentError: conflicting option string: --python-testing` while inheriting the entire `colcon_core.python_testing` step dispatch, JUnit `pytest.xml` reporting, and `TestFailure` event handling.
2. **Static `get_python_setup_options` with Cycle-Safe PEP 735 `[dependency-groups]`**:
   - Extracted `[project.dependencies]` (`install_requires`), `[project.optional-dependencies]` (`extras_require`), and PEP 735 `[dependency-groups]` (`test`, `tests`, `testing`, normalized via PEP 503 `[-_.]+ -> '-'` with cycle-safe `{include-group = "..."}` traversal into `tests_require`), passing the resulting dictionary through `colcon_core.package_augmentation.python.extract_dependencies()` and exposing `get_python_setup_options`.

### Solution Files
* `colcon_core/task/python_project/test.py` [NEW]: `PythonProjectTestTask(PythonTestTask)`.
* `setup.cfg` [MODIFIED]: Added `python.project = colcon_core.task.python_project.test:PythonProjectTestTask` under `colcon_core.task.test`.
* `colcon_core/package_augmentation/pep621.py` [MODIFIED]: Added `_normalize_group_name`, `_resolve_dependency_group`, `_extract_pyproject_options`, `extract_dependencies` integration, and `desc.metadata['get_python_setup_options']`.
* `test/test_task_python_project_test.py` [NEW], `test/test_package_augmentation_pep621.py` [MODIFIED], `test/test_integration_pep621.py` [MODIFIED]: Unit tests for parser coexistence and step dispatch, PEP 735 `include-group` cycle-safe tests, and `test_integration_python_project_test_task` (`flit_core` build + `PythonProjectTestTask.test()` generating `pytest.xml`).

---

## 3. Branch 4 (Stage 4C): `feature/pep621-dynamic-metadata` (`49fcded`)

### Problem Statement
1. `colcon_core/python_project/metadata.py` (`load_metadata`, `load_and_cache_metadata`, `options_from_metadata`) existed on `cottsay/pep621`, yet `PEP621PackageAugmentation` never called it when `pyproject.toml` declared `dynamic = ["version", "dependencies", ...]`.
2. `load_metadata(desc)` unconditionally invoked `prepare_metadata_for_build_wheel`, which is an *optional* hook in PEP 517; backends implementing only `build_wheel` raised a hook error.

### Implementation Decisions
1. **Zero-Subprocess Guard for Static Manifests**:
   - Invoked `_load_dynamic_metadata(desc)` *only* when `set(project.get('dynamic') or ()) & {'authors', 'dependencies', 'maintainers', 'optional-dependencies', 'version'}` is non-empty. Static PEP 621 workspaces spawn zero backend subprocesses during `colcon list` / `colcon graph` / `colcon build`.
2. **PEP 517 `build_wheel` `.dist-info` Extraction Fallback**:
   - Checked `'prepare_metadata_for_build_wheel' in await hook_caller.list_hooks()` inside `load_metadata(desc)`. When absent, built a wheel into a `TemporaryDirectory`, extracted only `.dist-info/*` members via `ZipFile.extract`, and loaded `Distribution.at(dist_info_dir).metadata`.
3. **Graceful Discovery Degradation When Build Backends Are Missing**:
   - Caught `(CalledProcessError, OSError, RuntimeError, ValueError)` around `loop.run_until_complete(load_and_cache_metadata(desc))`, closed the dedicated `new_event_loop()` in `finally:`, and logged a `logger.warning(...)` so `colcon list` still reports the package and its static `[build-system].requires` even before build dependencies are installed.
4. **Closure-Safe Rebase Merge Coordination with Branch 3 (`4A`)**:
   - When combining `4A` and `4C` (validated in [`ci/stage4-all-validation`](https://github.com/KmoM88/colcon-core/tree/ci/stage4-all-validation) @ `32dd42a`), `dyn_options = options_from_metadata(metadata)` updates `options['install_requires']` and `options['extras_require']` *in place* rather than rebinding `options`, preserving static PEP 735 `[dependency-groups]` `tests_require` inside `get_python_setup_options`.

### Solution Files
* `colcon_core/python_project/metadata.py` [MODIFIED]: Added `list_hooks()` check and `build_wheel` `.dist-info` fallback in `load_metadata(desc)`.
* `colcon_core/package_augmentation/pep621.py` [MODIFIED]: Added `_DYNAMIC_FIELDS`, `_load_dynamic_metadata`, `_augment_maintainers_from_metadata` (using `email.utils.getaddresses`), and dynamic field backfill.
* `test/spell_check.words`, `test/test_python_project_metadata.py` [NEW], `test/test_package_augmentation_pep621.py` [MODIFIED], `test/test_integration_pep621.py` [MODIFIED]: Unit tests for `prepare_metadata_for_build_wheel` + `build_wheel` fallback, zero-subprocess static guard, error warning degradation, and `test_integration_dynamic_metadata_flit_core`.

---

## 4. Validation & Verification Results

* **Individual Local Full Suites**:
  - `feature/python-project-test-task` (`d4b93bc`): **`256 passed, 5 skipped`** (`0` linter errors).
  - `feature/pep621-dynamic-metadata` (`49fcded`): **`257 passed, 5 skipped`** (`0` linter errors).
* **Combined Integration Branch (`ci/stage4-all-validation` @ `32dd42a`)**:
  - Local Full Suite: **`272 passed, 5 skipped`**.
  - Fork-Local GitHub Actions Matrix ([KmoM88/colcon-core#5](https://github.com/KmoM88/colcon-core/pull/5)): **44/44 jobs passing** in run [40802478808](https://github.com/KmoM88/colcon-core/actions/runs/40802478808) across Ubuntu, macOS, and Windows (Python 3.8–3.14, `stdeb`, and `bootstrap`).
