# Stage 4 — Group A: Independent `colcon-core:master` Follow-Up Branches (`4B` & `4D`)

* **Parent Plan**: [PR, Branch, Feature & Release Plan](../README.md)
* **Historic Baseline**: [Historic PRs & Prototype Reference](../historic_prs_reference.md)
* **Branch Blueprint**: [stage4_branch_plan.md](../../plans/stage4_branch_plan.md)

---

## 1. Branch & Fork CI Validation Metadata

| Field | Branch 1 — Stage 4B (`TASK-6`) | Branch 2 — Stage 4D (`TASK-7`) |
| :--- | :--- | :--- |
| **Release Wave** | Wave 1 (Independent `colcon-core:master` candidate) | Wave 1 (Independent `colcon-core:master` candidate) |
| **Status** | **Implemented, Pushed to Fork & 44/44 Fork-CI Green** *(no upstream PR opened)* | **Implemented, Pushed to Fork & 44/44 Fork-CI Green** *(no upstream PR opened)* |
| **Feature Branch** | [`KmoM88/colcon-core:feature/setuptools-decorator`](https://github.com/KmoM88/colcon-core/tree/feature/setuptools-decorator) (`bdf5077`) | [`KmoM88/colcon-core:feature/wheel-script-dir-and-windows-symlink`](https://github.com/KmoM88/colcon-core/tree/feature/wheel-script-dir-and-windows-symlink) (`85a79ae`) |
| **Base Commit** | `colcon/colcon-core:master` (`6bfb100`) | `colcon/colcon-core:master` (`6bfb100`) |
| **Fork Compare Diff** | [KmoM88/colcon-core:master...feature/setuptools-decorator](https://github.com/KmoM88/colcon-core/compare/master...feature/setuptools-decorator) | [KmoM88/colcon-core:master...feature/wheel-script-dir-and-windows-symlink](https://github.com/KmoM88/colcon-core/compare/master...feature/wheel-script-dir-and-windows-symlink) |
| **Fork CI Validation PR** | [KmoM88/colcon-core#5](https://github.com/KmoM88/colcon-core/pull/5) ([Run 40802478808](https://github.com/KmoM88/colcon-core/actions/runs/40802478808) — **44/44 jobs green**) | [KmoM88/colcon-core#5](https://github.com/KmoM88/colcon-core/pull/5) ([Run 40802478808](https://github.com/KmoM88/colcon-core/actions/runs/40802478808) — **44/44 jobs green**) |
| **Pitfalls Remediated** | Pitfall 8 (`setuptools` `.egg-info/` & `build/` source-tree pollution) + PR #732 missing extension-point group | Pitfall 10 (cached `ScriptMaker` rebuild `FileNotFoundError`) & Pitfall 9 (Windows `winerror 1314` symlink fallback) |

---

## 2. Branch 1 (Stage 4B): `feature/setuptools-decorator` (`bdf5077`)

### Problem Statement
1. When `AsyncHookCaller` invokes `setuptools.build_meta` or `setuptools.build_meta:__legacy__` with `cwd=project_path`, `bdist_wheel` and `egg_info` write `<pkg>.egg-info/` and `build/` directly into the user's package source directory, polluting `git status`.
2. When PR #732 introduced `HookCallerDecoratorExtensionPoint`, `setup.cfg` on `colcon-core:master` omitted registering `colcon_core.python_project.hook_caller_decorator` under `[options.entry_points] colcon_core.extension_point`, causing `get_all_extension_points()` to filter out entry-point-registered hook caller decorators.

### Implementation Decisions
1. **Hook-Specific `--build-option` vs `--global-option` Routing**:
   - Empirically verified on `setuptools 79.0.1` that `build_wheel` forwards `--build-option` (`setuptools >= 64`), `prepare_metadata_for_build_wheel` and `build_editable` already isolate metadata in temporary directories on `setuptools >= 64`, whereas `get_requires_for_build_wheel` and `get_requires_for_build_editable` (`_get_build_requires`) *only* read `--global-option` (ignoring `--build-option`).
   - Used `--global-option` (`['egg_info', f'--egg-base={temp}']`) for `get_requires_for_build_*` (and `prepare_metadata_for_build_wheel` on `setuptools < 64`), and `ESCAPE_HATCH` (`--build-option` on `setuptools >= 64`, `--global-option` on `< 64`) with both `_ScratchEggBase` and `_ScratchBuildBase` for `build_wheel`.
2. **Immutable Caller `config_settings` & Clean `PYTHONWARNINGS` Formatting**:
   - Copied `config_settings = dict(kwargs.pop('config_settings', None) or {})` so caller dictionaries are never mutated in place, and filtered empty tokens when appending `setuptools.command.editable_wheel` `InformationOnly` suppression to `PYTHONWARNINGS`.
3. **`stdeb` Compatibility Guard in Real-Backend Test**:
   - Guarded `test_setuptools_decorator_real_backend_no_source_pollution` with `pytest.importorskip('setuptools', minversion='64.0.0')` (plus `wheel` guard on `< 70.1`) so Debian/Ubuntu `stdeb` runners with pre-PEP-621 `setuptools` skip cleanly.

### Solution Files
* `colcon_core/python_project/hook_caller_decorator/setuptools.py` [NEW]: `SetuptoolsHookCallerDecoratorExtension` and `SetuptoolsDecorator`.
* `setup.cfg` [MODIFIED]: Registered `colcon_core.python_project.hook_caller_decorator` under `colcon_core.extension_point` and `setuptools` under `colcon_core.python_project.hook_caller_decorator`.
* `test/test_hook_caller_decorator_setuptools.py` [NEW]: 5 unit + real-backend subprocess tests verifying passthrough on non-setuptools backends, `PYTHONWARNINGS`, `config_settings` immutability, entry-point discovery, and zero `.egg-info/` or `build/` directories after full PEP 517/660 hook lifecycles.

---

## 3. Branch 2 (Stage 4D): `feature/wheel-script-dir-and-windows-symlink` (`85a79ae`)

### Problem Statement
1. **Cached `ScriptMaker` Rebuild Crash (`Pitfall 10`)**: `colcon_core/python_project/wheel.py` caches `_get_script_maker(script_dir)` via `functools.lru_cache(maxsize=32)`. Inside `distlib.scripts.ScriptMaker`, `self._fileop._created` remembers directories created during the first `make_multiple()` call in a Python process and skips `os.makedirs` on subsequent calls. When `remove_distributions()` unlinks old scripts and prunes the empty `script_dir`, a second `install_wheel()` call in the same process raises `FileNotFoundError`.
2. **Unprivileged Windows Symlink Crash (`Pitfall 9`)**: `colcon_core.task.install()` called `os.symlink(src, dst)` without handling Windows accounts lacking Developer Mode / `SeCreateSymbolicLinkPrivilege` (`OSError` with `winerror == 1314`).

### Implementation Decisions
1. **Keep `functools.lru_cache` Intact and Ensure `script_dir.mkdir(parents=True, exist_ok=True)`**:
   - Calling `script_dir.mkdir(parents=True, exist_ok=True)` only when `specs` is non-empty right before `sm = _get_script_maker(script_dir)` preserves `ScriptMaker` caching while guaranteeing `script_dir` exists on disk.
2. **Narrow Windows Privilege Fallback (`winerror == 1314` Only)**:
   - Caught `OSError as e` around `os.symlink(src, dst)` and fell back to `logger.warning(...)` + `shutil.copy(src, dst)` *only* when `sys.platform == 'win32' and getattr(e, 'winerror', None) == 1314`, re-raising all other `OSError` failures.
3. **Cross-Platform `_make_winerror` Test Helper**:
   - Constructed `OSError(13, msg, None, code)` when `os.name == 'nt'` (native Windows CPython slot constructor) and `err = OSError(msg); err.winerror = code` on POSIX so `test_install_windows_symlink_privilege_fallback` runs identically on Windows, Linux, and macOS CI runners.
4. **Optional Micro-PR Split**:
   - Because `wheel.py` and `task/__init__.py` touch disjoint modules on `master`, Branch 4D can be submitted either as one small resilience PR or split into two 15-line PRs at upstream submission time.

### Solution Files
* `colcon_core/python_project/wheel.py` [MODIFIED]: Guarded `specs` block and called `script_dir.mkdir(parents=True, exist_ok=True)` prior to `_get_script_maker(script_dir)`.
* `colcon_core/task/__init__.py` [MODIFIED]: Added Windows `winerror == 1314` warning and `shutil.copy(src, dst)` fallback in `install()`.
* `test/spell_check.words`, `test/test_install_wheel.py`, `test/test_task.py` [MODIFIED]: Added `test_install_wheel_rebuild_after_remove_distributions` and `test_install_windows_symlink_privilege_fallback`.

---

## 4. Validation & Verification Results

* **Individual Local Full Suites**:
  - `feature/setuptools-decorator` (`bdf5077`): **`243 passed, 5 skipped`** (`0` linter errors).
  - `feature/wheel-script-dir-and-windows-symlink` (`85a79ae`): **`240 passed, 5 skipped`** (`0` linter errors).
* **Fork-Local GitHub Actions Matrix ([KmoM88/colcon-core#5](https://github.com/KmoM88/colcon-core/pull/5))**: **44/44 jobs passing** in run [40802478808](https://github.com/KmoM88/colcon-core/actions/runs/40802478808) across Ubuntu, macOS, and Windows (Python 3.8–3.14, `stdeb`, and `bootstrap`).
