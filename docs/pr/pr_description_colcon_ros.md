### Summary
Enables `colcon-ros` (`AmentPythonBuildTask` and `RosAmentPythonPackageAugmentation`) to natively build and test ROS 2 `ament_python` packages that use standard PEP 517 / PEP 621 `pyproject.toml` packaging without requiring a legacy `setup.py`.

This PR represents **Stage 3** of the Modern Python Packaging architectural roadmap (see [Roadmap Gist](https://gist.github.com/KmoM88/0357abff37b5a32ab801cac7d399d4ed)) and builds on standard Python project support in `colcon-core` (`colcon/colcon-core#750` and `colcon/colcon-core#751`). Marked as **Draft** until the `colcon-core` primitives land.

---

### Background & Motivation
In modern Python (PEP 517, PEP 518, PEP 621), `pyproject.toml` is the standard configuration file for Python packages across backends such as `flit_core`, `hatchling`, and `setuptools.build_meta`.

Previously, when a ROS 2 package specified:
```xml
<export>
  <build_type>ament_python</build_type>
</export>
```
1. `AmentPythonBuildTask` required a `setup.py` file and invoked `setup.py` commands directly, failing when only `pyproject.toml` was present.
2. Standard Python wheels install `[project.scripts]` executables into `bin/`, whereas `ros2 run <pkg> <node>` discovers package executables under `lib/<pkg>/`.
3. `RosAmentPythonPackageAugmentation` returned early when `setup.py` was absent, leaving `get_python_setup_options` unset so `colcon test` (`AmentPythonTestTask` / `PytestPythonTestingStep`) could not match `pytest` dependencies declared in `pyproject.toml`.

---

### Changes
1. **Build Delegation & `ros2 run` Script Placement ([`colcon_ros/task/ament_python/build.py`](https://github.com/colcon/colcon-ros/pull/171/files))**:
   - Detects `ament_python` packages containing `pyproject.toml` without `setup.py` and delegates wheel compilation and installation to `colcon_core.task.python_project.build.PythonProjectBuildTask`.
   - Passes `script_dir_override=Path('lib') / self.context.pkg.name` when supported by `PythonProjectBuildTask.build()` so `[project.scripts]` entry points install into `lib/<pkg_name>/` where `ros2 run` expects them (without requiring a legacy `setup.cfg`).
   - Passes `additional_hooks=additional_hooks` directly as a flat hook list so `create_environment_scripts` registers both `.dsv` and shell (`.sh` / `.bat` / `.ps1`) `ament_prefix_path` hooks in package-level environment scripts.
   - Installs `share/ament_index/resource_index/packages/<pkg_name>` and `share/<pkg_name>/package.xml` *after* `PythonProjectBuildTask.build()` completes (so `remove_distributions` during rebuilds does not delete freshly created files, and wheel-provided manifests/markers are preserved without clobbering), and records both relative paths in `.dist-info/RECORD` for clean uninstallation.
   - Logs a clear error and returns `1` if the installed `colcon-core` version does not yet provide `PythonProjectBuildTask`.

2. **Test Metadata Augmentation for `colcon test` ([`colcon_ros/package_augmentation/ros_ament_python.py`](https://github.com/colcon/colcon-ros/pull/171/files))**:
   - Populates `desc.metadata['get_python_setup_options']` from `pyproject.toml` (`[project.dependencies]`, `[project.optional-dependencies]`, and PEP 735 `[dependency-groups]` test groups, merged with `setup.cfg` `[options]` when present) when `setup.py` is absent, enabling `AmentPythonTestTask` / `PytestPythonTestingStep` to match `pytest` during `colcon test`.

3. **Automated Unit & Integration Tests ([`test/test_task_ament_python_build.py`](https://github.com/colcon/colcon-ros/pull/171/files), [`test/spell_check.words`](https://github.com/colcon/colcon-ros/pull/171/files))**:
   - Added end-to-end integration test (`test_ament_python_build_pep621`) with `flit_core.buildapi` verifying repeated rebuilds, `[project.scripts]` placement in `lib/<pkg>/`, `ament_index` and `package.xml` installation and deduplicated `.dist-info/RECORD` entries, `ament_prefix_path` hook registration in `package.dsv` / `package.sh`, and `pytest` dependency discovery.
   - Added backend-independent unit tests (`test_ament_python_build_python_project_unit`, `test_ros_ament_python_augmentation_pyproject`) covering `ImportError` handling, `script_dir_override` and flat `additional_hooks` forwarding, failure return codes, pre-existing marker preservation, and PEP 621 / PEP 735 test dependency augmentation.

---

### Dual-Manifest Note (`package.xml` + `pyproject.toml`)
Because `colcon` runs PEP 517 hooks with `--no-isolation` against the workspace environment, ROS 2 `ament_python` packages using `pyproject.toml` should declare their PEP 518 build backend in `package.xml` (e.g. `<build_depend>python3-flit-core</build_depend>`, `<build_depend>python3-hatchling</build_depend>`, or `<build_depend>python3-setuptools</build_depend>` plus `<build_depend>python3-wheel</build_depend>` on platforms with `setuptools < 70.1`) so `rosdep install` provisions them in CI and buildfarm environments.

---

### Verification
- Full `pytest --cov --cov-branch` suite passing (`16 passed`), including `test_flake8`, `test_spell_check`, `test_copyright_license`, unit tests, and end-to-end `flit_core` integration tests.
