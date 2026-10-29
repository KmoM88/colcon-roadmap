# Historic Pull Requests & Prototype Implementation Reference

This reference document summarizes the historic prototype, upstream tracking issue, merged `colcon-core` foundation pull requests (`#728`, `#732`, `#741`), and upstream feature branch (`cottsay/pep621`) upon which Stages 1–4 are built.

* **Parent Plan**: [PR, Branch, Feature & Release Plan](README.md)
* **Detailed SWE Audit Reports**:
  - [colcon-python-project PR #1 Analysis](../analysis/colcon/colcon-python-project/pr/1/swe_analysis.md)
  - [colcon-core PR #741 Analysis](../analysis/colcon/colcon-core/pr/741/swe_analysis.md)
  - [colcon-core Branch `cottsay/pep621` Analysis](../analysis/colcon/colcon-core/branch/cottsay/pep621/swe_analysis.md)

---

## 1. Chronological Evolution Matrix

| Milestone | Repository & Reference | Commit / Release | Status | Architectural Role |
| :--- | :--- | :--- | :--- | :--- |
| **Out-of-Tree Prototype** | [colcon/colcon-python-project#1](https://github.com/colcon/colcon-python-project/pull/1) | 67-commit draft | **Superseded Prototype** | Proved PEP 517 subprocess hooks and in-process wheel extraction, but broke mixed workspaces by overriding the legacy `python` package type. |
| **Upstream Roadmap Issue** | [colcon/colcon-core#736](https://github.com/colcon/colcon-core/issues/736) | Issue tracker | **Open Tracking Issue** | Coordinated decomposing `colcon-python-project` into native, backward-compatible `colcon-core` PRs. |
| **Foundation 1: Installed Distribution Discovery** | [colcon/colcon-core#728](https://github.com/colcon/colcon-core/pull/728) | Released in `v0.21.2`+ | **Merged Upstream** | Added `colcon_core.python_project.distribution.InstalledDistribution` for live `.dist-info` / `.egg-info` and `.pyc` file enumeration on disk. |
| **Foundation 2: Subprocess Hook Caller & Spec Loader** | [colcon/colcon-core#732](https://github.com/colcon/colcon-core/pull/732) | Released in `v0.21.2`+ | **Merged Upstream** | Added `AsyncHookCaller` (PEP 517 IPC over OS pipes + pickle), `HookCallerDecoratorExtensionPoint`, and `load_and_cache_spec` (`pyproject.toml` loader). |
| **Foundation 3: In-Process Wheel Engine** | [colcon/colcon-core#741](https://github.com/colcon/colcon-core/pull/741) | `845927c` (`v0.21.2` / `v0.21.3`) | **Merged Upstream** | Added `colcon_core/python_project/wheel.py` (`install_wheel`, `remove_distributions`, `ScriptMaker` wrappers, `.data/` mapping, PEP 376 `RECORD` / `INSTALLER`). |
| **Upstream PEP 621 Base Branch** | [`colcon/colcon-core:cottsay/pep621`](https://github.com/colcon/colcon-core/tree/cottsay/pep621) | `80acf29` | **Active Upstream Branch** | Introduced `PEP621PackageIdentification`, `PEP621PackageAugmentation`, `PythonProjectBuildTask`, `metadata.py`, and the `pep621_builds` feature flag. |

---

## 2. Prototype Origin: `colcon/colcon-python-project#1`

* **Pull Request**: [colcon/colcon-python-project#1](https://github.com/colcon/colcon-python-project/pull/1)
* **Deep Audit**: [../analysis/colcon/colcon-python-project/pr/1/swe_analysis.md](../analysis/colcon/colcon-python-project/pr/1/swe_analysis.md)

### Implementation Context & Lessons Learned
1. **What It Proved**:
   - Executing PEP 517/660 backend hooks (`get_requires_for_build_wheel`, `prepare_metadata_for_build_wheel`, `build_wheel`, `build_editable`) in isolated Python subprocesses communicating over OS pipes with pickled payloads avoids importing build backends into `colcon`'s own interpreter process.
   - Extracting `.whl` ZIP archives in-process and generating console scripts via `distlib.scripts.ScriptMaker` is 3x–5x faster than spawning `pip install` subprocesses, avoids requiring `pip` in target deployment environments, and preserves full control over installation scheme directories and PEP 376 `RECORD` signing.
2. **Why It Was Superseded by Native `colcon-core` Integration**:
   - **Global `python` Type Override Regression**: Registering an out-of-tree plugin with higher priority over the existing `python` package type hijacked legacy `setup.py` packages across mixed ROS workspaces, breaking packages relying on classic `distutils`/`setuptools` behaviors.
   - **Code Duplication & Stale CI**: Duplicated distribution-enumeration helpers and drifted against modern `flake8` / CI matrices (21/22 CI checks failing on the prototype repository).
   - **Strategic Decision**: Introduce a distinct `python.project` package type natively inside `colcon-core` so legacy `python` (`setup.py` / `setup.cfg`) and modern `python.project` (`pyproject.toml` PEP 621) packages coexist without interference in the same workspace.

---

## 3. Merged Upstream Foundations in `colcon-core` (`v0.21.2` / `v0.21.3`)

### 3.1 PR #728 — `InstalledDistribution` (`colcon_core/python_project/distribution.py`)
* **Pull Request**: [colcon/colcon-core#728](https://github.com/colcon/colcon-core/pull/728)
* **Problem Solved**: Prior `setup.py` builds relied on build-directory staging artifacts or incomplete file lists, leaving stale Python modules or `.pyc` files behind in `install_base` when source files were renamed or deleted.
* **Delivered Solution**:
  - Queries installed `.dist-info` and `.egg-info` metadata directories directly under `install_base` via `importlib.metadata`.
  - Enumerates all installed files recorded in `RECORD` / `installed-files.txt` together with derived `__pycache__/*.pyc` bytecode artifacts and platform install scheme paths (`purelib`, `platlib`, `scripts`, `data`).

### 3.2 PR #732 — `AsyncHookCaller` & `pyproject.toml` Spec Loader
* **Pull Request**: [colcon/colcon-core#732](https://github.com/colcon/colcon-core/pull/732)
* **Problem Solved**: `colcon` needed an asynchronous, non-blocking PEP 517 backend runner compatible with `colcon`'s event-loop task executor, plus a zero-overhead cached TOML reader supporting Python 3.8+.
* **Delivered Solution**:
  - `colcon_core/python_project/hook_caller.py`: `AsyncHookCaller` executes `_list_hooks.py` and `_call_hook.py` in a child Python process, streaming stdout/stderr into `colcon`'s event reactor while returning structured hook return values over an OS pipe.
  - `colcon_core/python_project/hook_caller_decorator/__init__.py`: Defines `HookCallerDecoratorExtensionPoint` and `get_decorated_hook_caller(desc)` so backend-specific wrappers can customize `config_settings` or environment variables.
  - `colcon_core/python_project/spec.py`: `load_and_cache_spec(desc)` parses `pyproject.toml` once per `PackageDescriptor` (using stdlib `tomllib` on Python 3.11+ with `tomli` compatibility fallback on Python 3.8–3.10) and caches the dictionary on `desc.metadata`.
* **Follow-Up Edge Case Resolved Later in Stage 4B**:
  - `setup.cfg` in PR #732 omitted registering `colcon_core.python_project.hook_caller_decorator` under `[options.entry_points] colcon_core.extension_point`. Addressed in Stage 4B ([stages/stage4_group_a_master_followups.md](stages/stage4_group_a_master_followups.md), commit `bdf5077`).

### 3.3 PR #741 — In-Process Wheel Engine (`colcon_core/python_project/wheel.py`)
* **Pull Request**: [colcon/colcon-core#741](https://github.com/colcon/colcon-core/pull/741) (Commit `845927c`, authored by Federico Rossi, reviewed and merged by Scott K Logan)
* **Deep Audit**: [../analysis/colcon/colcon-core/pr/741/swe_analysis.md](../analysis/colcon/colcon-core/pr/741/swe_analysis.md)
* **Delivered Solution**:
  - `remove_distributions(name, base)`: Discovers prior installations via `InstalledDistribution.discover`, unlinks every installed file and `.egg-link` (catching locked-file `(OSError, PermissionError)` on Windows with a warning), and recursively prunes empty parent directories up to `install_base`.
  - `install_wheel(wheel, base, *, script_dir_override=None)`: Calls `remove_distributions` first for idempotent rebuilds, extracts `.whl` archives into `purelib`/`platlib`, maps `<dist>.data/<scheme>/...` (such as `data/share/...` -> `<base>/share/...`), generates cross-platform executable wrappers for `console_scripts` / `gui_scripts` via `distlib.scripts.ScriptMaker`, writes `INSTALLER` (`colcon-core`), and signs `.dist-info/RECORD` with POSIX-normalized relative paths and SHA-256 digests.
* **Verification**: 9 unit tests in `test/test_install_wheel.py` and `test/test_remove_wheel.py`, merged across the full upstream CI matrix.
* **Follow-Up Edge Case Resolved Later in Stage 4D**:
  - `_get_script_maker(script_dir)` used `functools.lru_cache`, while `distlib`'s `FileOperator._created` memoized directory creation across calls in the same Python process after `remove_distributions()` pruned an empty `script_dir`. Addressed in Stage 4D ([stages/stage4_group_a_master_followups.md](stages/stage4_group_a_master_followups.md), commit `85a79ae`).

---

## 4. Upstream Base Branch: `colcon/colcon-core:cottsay/pep621` (`80acf29`)

* **Branch**: [`colcon/colcon-core:cottsay/pep621`](https://github.com/colcon/colcon-core/tree/cottsay/pep621) (Commit `80acf29`)
* **Deep Audit**: [../analysis/colcon/colcon-core/branch/cottsay/pep621/swe_analysis.md](../analysis/colcon/colcon-core/branch/cottsay/pep621/swe_analysis.md)

### Capabilities Introduced in `80acf29`
1. **`PEP621PackageIdentification` (`colcon_core/package_identification/pep621.py`)**: Identifies directories containing `pyproject.toml` with `[project].name` as `desc.type = 'python.project'` (gated when `pep621_builds` feature flag logic applies).
2. **`PEP621PackageAugmentation` (`colcon_core/package_augmentation/pep621.py`)**: Populates static `build`, `run`, and `test` (`[project.optional-dependencies].test`) dependencies, `version`, and `maintainers`/`authors`.
3. **`PythonProjectBuildTask` (`colcon_core/task/python_project/build.py`)**: Orchestrates `build_wheel` / `build_editable` via `get_decorated_hook_caller`, unpacks wheels via `install_wheel`, creates colcon environment hooks/scripts, writes PEP 610 `direct_url.json`, and appends generated files to `RECORD`.
4. **`colcon_core/python_project/metadata.py`**: Helper module defining `load_metadata`, `load_and_cache_metadata`, and `options_from_metadata`.

### Remaining Gaps Addressed by Stages 1–4
* **Async Test Harness & Real-Backend Coverage**: `test_task_python_project_build.py` used `@pytest.mark.asyncio` (not in `colcon-core` dependencies) and lacked end-to-end `flit_core` / `hatchling` integration tests -> **Resolved in [Stage 1](stages/stage1_core_pep621.md) (`#750`)**.
* **Editable Data-Files Asymmetry, `RECORD` Duplicates & Downstream `script_dir_override`**: `--symlink-install` read `setup.cfg` unconditionally across backends, duplicated `RECORD` rows, doubled relative `install_base` `$base` paths, and lacked a `script_dir_override` parameter on `build()` -> **Resolved in [Stage 2](stages/stage2_editable_data_files.md) (`#751`)**.
* **ROS 2 `ament_python` Integration (`ros2 run`, `ament_index` `RECORD` & `colcon test`)**: `colcon-ros` still required `setup.py` for build routing, script placement in `lib/<pkg>/`, and `pytest` augmentation -> **Resolved in [Stage 3](stages/stage3_colcon_ros_ament_python.md) (`colcon-ros#171`)**.
* **Setuptools Source-Tree Pollution, Cached `ScriptMaker` Rebuilds, Windows Symlink Fallback, Pure `python.project` `colcon test`, and Dynamic Metadata**: -> **Resolved in [Stage 4 Group A](stages/stage4_group_a_master_followups.md) and [Stage 4 Group B](stages/stage4_group_b_pep621_followups.md) ([KmoM88/colcon-core#5](https://github.com/KmoM88/colcon-core/pull/5))**.
