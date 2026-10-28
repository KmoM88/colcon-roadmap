### Summary
Enables `colcon-ros`'s `AmentPythonBuildTask` to natively build ROS 2 `ament_python` packages that use standard PEP 517 / PEP 621 `pyproject.toml` packaging without requiring a legacy `setup.py`.

This PR represents **Stage 3** of the Modern Python Packaging architectural roadmap (see [Roadmap Gist](https://gist.github.com/KmoM88/0357abff37b5a32ab801cac7d399d4ed)) and depends on standard Python project support in `colcon-core` (PR #750). Marked as **Draft** until the `colcon-core` primitives land.

---

### Background & Motivation
In modern Python (PEP 517, PEP 518, PEP 621), `pyproject.toml` is the standard configuration file for Python packages, supported by modern build backends such as `flit_core`, `hatchling`, and modern `setuptools`.

Currently, when a ROS 2 package specifies:
```xml
<export>
  <build_type>ament_python</build_type>
</export>
```
`AmentPythonBuildTask` assumes that the package has a `setup.py` and attempts to invoke `python3 setup.py egg_info` / `build`, failing when only a modern `pyproject.toml` is present.

With standard Python project support in `colcon-core` (`colcon_core.task.python_project.build.PythonProjectBuildTask`), `colcon-ros` can cleanly delegate the build and installation of the wheel to `PythonProjectBuildTask` while continuing to satisfy all ROS 2 specific contracts.

---

### Changes
1. **`colcon_ros/task/ament_python/build.py`**:
   - Checks if `setup.py` is absent and `pyproject.toml` is present in the package source directory.
   - When detected, routes build execution through `PythonProjectBuildTask`.
   - Maintains full ROS 2 environment and index integration:
     - Creates the package marker in `share/ament_index/resource_index/packages/<pkg_name>`.
     - Installs `package.xml` into `share/<pkg_name>/package.xml`.
     - Passes `additional_hooks` so the `AMENT_PREFIX_PATH` environment hook (`ament_prefix_path.dsv` / `.sh`) is correctly generated and registered in `dist-info/RECORD`.
   - Provides graceful fallback and error reporting if `colcon-core` does not provide `PythonProjectBuildTask`.

2. **Automated Test Suite (`test/test_task_ament_python_build.py`)**:
   - Added end-to-end integration test creating a temporary ROS 2 `ament_python` package with `package.xml` and `pyproject.toml` (using `flit_core.buildapi`, without `setup.py`).
   - Verifies:
     - Existence of the `ament_index` marker file.
     - Presence of `package.xml` in `share/my_ros_pkg/`.
     - Proper installation of the Python module and `.dist-info`.
     - Correct generation of `share/my_ros_pkg/hook/ament_prefix_path.dsv`.

---

### Testing Done
- Tested with standard Python project build tasks in `colcon-core`.
- Automated test `test/test_task_ament_python_build.py` verified.
- `flake8` clean.
