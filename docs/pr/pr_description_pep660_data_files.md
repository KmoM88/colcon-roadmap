### Summary
Adds native support for symlinking non-Python data files (`share/` assets, launch files, parameter files, configuration files) when building modern PEP 517 / PEP 621 projects with `--symlink-install`.

This PR represents **Stage 2** of the Modern Python Packaging architectural roadmap (see [Roadmap Gist](https://gist.github.com/KmoM88/0357abff37b5a32ab801cac7d399d4ed)) and builds on top of PR #750. Marked as **Draft** until Stage 1 (PR #750) lands.

---

### Background & Problem
PEP 660 defines a standardized hook (`build_editable`) for editable installations in modern Python builds. However, PEP 660 only makes Python source code dynamically editable (via `.pth` path files or import loader hooks). 

In complex workspaces (such as ROS 2 or multi-package projects), packages declare non-Python assets that are installed into `share/<package_name>/`:
- Launch files (`.launch.py`)
- Configuration YAMLs
- URDF / robot descriptions
- Plugins and resource markers

When built into a wheel via PEP 660, those non-code files are packed as static files in the `.data/` directory and copied to `install/`. Consequently, modifying a launch file or config in `src/` does not reflect in `install/`, defeating the purpose of `--symlink-install` during local development and requiring full package rebuilds.

---

### Implementation
1. **`colcon_core/task/python_project/build.py`**:
   - Implemented `_get_data_files_mapping(pkg)`:
     - Discovers data file specifications declared in `setup.cfg` (`[options.data_files]`).
     - Discovers data file specifications declared in `pyproject.toml` (`[tool.setuptools.data-files]` and Hatchling's `[tool.hatch.build.targets.wheel.shared-data]`).
   - When `--symlink-install` is active:
     - Invokes `colcon_core.task.install()` to create real symbolic links directly from source files to the target path under `install_base`.
     - Appends each installed target to `.dist-info/RECORD` to ensure clean discovery and uninstallation via `remove_distributions`.

2. **Automated Integration Tests (`test/test_integration_pep621.py`)**:
   - Added `test_integration_symlink_install_data_files`:
     - Creates a test package declaring launch and config files in `setup.cfg` and `pyproject.toml`.
     - Builds using `--symlink-install`.
     - Asserts installed files are true OS symlinks pointing directly to the source files.
     - Edits source files in-place and asserts changes are visible immediately without rebuilding.

---

### Testing Done
- Automated integration test `test_integration_symlink_install_data_files` added to `test/test_integration_pep621.py`.
- Verified with full test suite.
- Linters: `flake8` and `scspell3k` clean.
