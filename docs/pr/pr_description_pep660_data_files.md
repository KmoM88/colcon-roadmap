### Summary
Adds native support for symlinking non-Python data files (`share/` assets, launch files, parameter files, configuration files) when building modern PEP 517 / PEP 621 projects with `--symlink-install`, and exposes an optional `script_dir_override` parameter on `PythonProjectBuildTask.build()` for downstream tasks (such as `colcon-ros`).

This PR represents **Stage 2** of the Modern Python Packaging architectural roadmap (see [Roadmap Gist](https://gist.github.com/KmoM88/0357abff37b5a32ab801cac7d399d4ed)) and builds on top of PR #750. Marked as **Draft** until Stage 1 (PR #750) lands.

---

### Background & Problem
PEP 660 defines a standardized hook (`build_editable`) for editable installations in modern Python builds. However, PEP 660 only makes Python source code dynamically editable (via `.pth` path files or import loader hooks).

In complex workspaces (such as ROS 2 or multi-package projects), packages declare non-Python assets installed into `share/<package_name>/` (launch files, YAML configs, URDFs, resource markers):
- Backends like **Hatchling** pack `shared-data` into `<dist>.data/` as static file copies inside editable wheels.
- Backends like **Setuptools** omit `<dist>.data/` altogether during `build_editable`, leaving `share/` assets missing under `--symlink-install` even though `build_wheel` installs them.

Additionally, downstream build tasks (such as `colcon-ros`'s `ament_python`) need to direct `[project.scripts]` entry points to `lib/<package_name>` for `ros2 run` compatibility without requiring a legacy `setup.cfg`.

---

### Implementation
1. **`colcon_core/task/python_project/build.py`**:
   - **`script_dir_override` Parameter**: Extended `PythonProjectBuildTask.build(*, additional_hooks=None, script_dir_override=None)` so calling tasks can specify a default script installation directory when `setup.cfg` does not override it, while fixing `$base` path resolution for relative `install_base` paths.
   - **Backend-Scoped `_get_data_files_mapping(pkg, backend_name)`**:
     - Preserves 100% parity between standard `colcon build` and `--symlink-install` by scoping configuration lookup strictly to the active PEP 517 backend:
       - `setuptools.build_meta*`: resolves `setup.cfg` (`[options.data_files]`) and `pyproject.toml` (`[tool.setuptools.data-files]`), including glob expansion (`*`, `?`, `[`).
       - `hatchling.*`: resolves `[tool.hatch.build.targets.wheel.shared-data]` for both individual file mappings and recursive directory mappings.
       - Backends without external data-file semantics (e.g. `flit_core`) are left untouched so editable and release builds behave identically.
   - **Deduplicated `.dist-info/RECORD` Updates**:
     - Replaces static wheel `.data/` entries in `RECORD` cleanly when converted into symbolic links instead of appending duplicate paths or retaining stale hashes.

2. **Automated Unit & Integration Tests (`test/test_task_python_project_build.py`, `test/test_integration_pep621.py`)**:
   - `test_get_data_files_mapping_by_backend` & `test_build_task_script_override_and_record_update`: Unit-test backend-scoped data-files resolution, `script_dir_override` forwarding, and unique `RECORD` updates in `pytest-cov` without optional external backend packages.
   - `test_integration_symlink_install_data_files`: Verifies parity between standard and `--symlink-install` builds with Hatchling `shared-data` (both file and directory targets), live source editing without rebuilds, and unique `RECORD` entries.
   - `test_integration_setuptools_data_files_and_script_override`: Verifies Setuptools `[tool.setuptools.data-files]` glob expansion under `build_editable` alongside `script_dir_override='lib/<pkg>'`, with clean entry-point cache isolation across full `pytest` runs.

---

### Testing Done
- Full `colcon-core` test suite passing (`256 passed, 5 skipped`, including unit, integration, `flake8`, `scspell3k`, and copyright checks).
- **46/46 GitHub Actions CI checks passing** across `ubuntu-22.04`, `macos-latest`, and `windows-latest` on Python 3.8–3.14 (`pytest`, `bootstrap`, `stdeb`, and `codecov`).
