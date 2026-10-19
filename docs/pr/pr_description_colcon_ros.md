# Pull Request Description: colcon-ros Phase 5

* **Target Repository**: `colcon/colcon-ros`
* **Base Branch**: `master`
* **Compare Branch**: `KmoM88:feature/ros-ament-python-project`
* **Commit**: `fc03806`
* **Comparison Web URL**: [colcon/colcon-ros:master...KmoM88:colcon-ros:feature/ros-ament-python-project](https://github.com/colcon/colcon-ros/compare/master...KmoM88:colcon-ros:feature/ros-ament-python-project)

---

## Proposed PR Title
```text
feat(ament_python): support modern PEP 621 pyproject.toml packages without setup.py
```

---

## Proposed PR Body (Markdown to copy-paste into GitHub)

```markdown
### Summary

Enables `colcon-ros`'s `AmentPythonBuildTask` to natively build ROS 2 `ament_python` packages that use standard PEP 517 / PEP 621 `pyproject.toml` packaging without requiring a legacy `setup.py`.

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
     - Return code `None` (success).
     - Existence of the `ament_index` marker file.
     - Presence of `package.xml` in `share/my_ros_pkg/`.
     - Proper installation of the Python module and `.dist-info`.
     - Correct generation of `share/my_ros_pkg/hook/ament_prefix_path.dsv`.

### Testing Done

- **Automated Tests**:
  - `pytest test/test_task_ament_python_build.py` $\rightarrow$ **PASSED** (0.13s).
  - Existing `colcon-ros` tests continue to pass without regression.
- **Code Style & Linters**:
  - `flake8 colcon_ros/task/ament_python/build.py test/test_task_ament_python_build.py` $\rightarrow$ **0 warnings / 0 errors**.
- **Cross-compatibility**:
  - Tested in conjunction with `colcon-core` branch `feature/pep621-upstream-pr` / `cottsay/pep621`.

### Related Issues / PRs

- `colcon/colcon-core#736`: Support standard Python packaging (PEP 517/518/621/660)
- `colcon/colcon-core#741`: In-process wheel installer (merged)
```
