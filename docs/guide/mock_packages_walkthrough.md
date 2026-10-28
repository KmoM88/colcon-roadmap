# Walkthrough & Verification Guide: Mock Packages & Python Standards in Colcon

This guide provides a practical, step-by-step walkthrough explaining how `colcon` handles Python packages—from the legacy `setup.py` / `setup.cfg` workflow to modern standard Python builds (PEP 517, PEP 518, PEP 621, and PEP 660) and modern ROS 2 `ament_python` packages.

All example packages described in this guide are located in [`examples/mock_packages/`](../../examples/mock_packages/) and can be verified automatically using the included demonstration script.

---

## 🚀 Quick Start: Running the Verification Suite

To run all 4 demonstration scenarios end-to-end and see the live outputs:

```bash
# From the repository root using the virtual environment:
submodules/colcon-ros/.venv/bin/python3 scripts/test_mock_packages.py
```

### Expected Output Summary
```text
======================================================================
COLCON PYTHON STANDARDS: MOCK PACKAGES DEMO & VERIFICATION SUITE
======================================================================
▶ Running Scenario 1: Classic package (setup.py)
  [Identification] Type: 'python', Name: 'classic_pkg'
  [Build Layout] Generated 1 egg-info artifacts in build/
  [Install Layout] Installed classic module at: lib/python3.12/site-packages/classic_pkg/__init__.py
✔ Scenario 1 PASSED: Classic setup.py workflow verified.

▶ Running Scenario 2: Modern PEP 621 package (pyproject.toml)
  [Identification] Type: 'python.project', Name: 'modern_flit_pkg'
  [In-Process Wheel] Installed dist-info at: lib/python3.12/site-packages/modern_flit_pkg-0.1.0.dist-info
  [CLI Entry Point] Generated executable wrapper in bin/: modern-cli (mode: 0o100775)
  [Script Output] "Executing from modern PEP 621 package (flit_core)!"
✔ Scenario 2 PASSED: Modern PEP 621 wheel extraction verified.

▶ Running Scenario 3: Modern PEP 660 editable & symlinked data
  [Standard Build] Verified shared-data copied to: share/data_pkg/launch/demo.launch.py
  [Symlink Install] Verified data file links to source: share/data_pkg/launch/demo.launch.py -> .../demo.launch.py
  [Live Modification] Source edits reflected in install/ instantly!
✔ Scenario 3 PASSED: Non-Python data files symlinking verified.

▶ Running Scenario 4: Modern ROS 2 ament_python without setup.py
  [Test Augmentation] Verified pytest dependency discovered for colcon test
  [ROS Index] Created resource index marker: share/ament_index/resource_index/packages/ros_pyproject_pkg
  [ROS Manifest] Copied package.xml to: share/ros_pyproject_pkg/package.xml
  [ROS Hook] Generated environment hook & package script: share/ros_pyproject_pkg/hook/ament_prefix_path.dsv
  [ROS Node] Node executable installed at: lib/ros_pyproject_pkg/sample-node
  [Node Output] "Executing sample-node from modern ament_python package without setup.py!"
✔ Scenario 4 PASSED: Modern ROS 2 ament_python build verified.

======================================================================
🎉 ALL 4 MOCK SCENARIOS COMPLETED AND VALIDATED SUCCESSFULLY!
======================================================================
```

---

## 🔍 Detailed Scenario Breakdown

### Scenario 1: Classic Package (`01_classic_setup_py`)

* **Directory**: [`examples/mock_packages/01_classic_setup_py`](../../examples/mock_packages/01_classic_setup_py)
* **Key Files**:
  ```text
  01_classic_setup_py/
  ├── classic_pkg/
  │   ├── __init__.py
  │   └── cli.py
  ├── package.xml
  ├── setup.cfg
  └── setup.py
  ```

#### How Colcon Processes It (Legacy Behavior):
1. **Identification**: Handled by `colcon_core.package_identification.python.PythonPackageIdentification`.
   - **Priority**: `100` (highest).
   - Reads `setup.cfg` `[metadata] name = classic_pkg` and assigns package type `python`.
2. **Build Task**: Handled by `PythonBuildTask`.
   - Spawns Python subprocess running `python3 setup.py egg_info` and `build`.
   - Creates `.egg-info` directories in `<build_base>/`.
   - Copies files into `<install_base>/lib/pythonX.Y/site-packages/`.

---

### Scenario 2: Modern Pure PEP 621 Package (`02_modern_pep621_flit`)

* **Directory**: [`examples/mock_packages/02_modern_pep621_flit`](../../examples/mock_packages/02_modern_pep621_flit)
* **Key Files**:
  ```text
  02_modern_pep621_flit/
  ├── modern_flit_pkg/
  │   ├── __init__.py
  │   └── cli.py
  ├── pyproject.toml      <-- Pure standard manifest (NO setup.py or setup.cfg!)
  └── README.md
  ```

#### Highlights of the Manifest (`pyproject.toml`):
```toml
[build-system]
requires = ["flit_core >=3.2,<4"]
build-backend = "flit_core.buildapi"

[project]
name = "modern_flit_pkg"
version = "0.1.0"
description = "Pure PEP 621 package using flit_core"
dependencies = []

[project.scripts]
modern-cli = "modern_flit_pkg.cli:main"
```

#### How Colcon Processes It (New Python Project Pipeline):
1. **Identification**: Handled by `colcon_core.package_identification.pep621.PEP621PackageIdentification`.
   - **Priority**: `90` (intentionally lower than `100`, ensuring backward compatibility when `setup.py` exists).
   - Detects `[project].name` and assigns package type `python.project`.
2. **Augmentation**: `PEP621PackageAugmentation` parses `project.dependencies` into colcon build/run/test dependencies.
3. **Build Task**: Handled by `PythonProjectBuildTask`.
   - Invokes backend hook `build_wheel` via isolated subprocess IPC (`AsyncHookCaller`).
   - Produces a standard wheel archive in `<build_base>/wheel/`.
   - Extracts and installs the wheel **in-process** via `colcon_core.python_project.wheel.install_wheel` without external `pip`.
   - Generates executable script wrappers in `<install_base>/bin/modern-cli` with `0o755` permissions using `distlib.scripts.ScriptMaker`.

---

### Scenario 3: Modern PEP 660 Editable & Symlinked Data Files (`03_modern_editable_data_files`)

* **Directory**: [`examples/mock_packages/03_modern_editable_data_files`](../../examples/mock_packages/03_modern_editable_data_files)
* **Key Files**:
  ```text
  03_modern_editable_data_files/
  ├── data_pkg/
  │   └── __init__.py
  ├── launch/
  │   └── demo.launch.py     <-- Non-code asset in share/
  ├── config/
  │   └── demo.yaml          <-- Parameter config in share/
  ├── pyproject.toml         <-- Hatchling shared-data manifest
  └── README.md
  ```

#### The Editable Dilemma & Colcon's Solution:
* **The Problem**: Standard PEP 660 (`build_editable`) makes Python code dynamically loadable (via `.pth` path files or loader hooks). However, non-code files (such as ROS `.launch.py` files, URDFs, or configurations) are packed statically in the wheel's `.data/` directory and copied into `<install_base>/share/`. Modifying a launch file in `src/` previously had no effect in `install/` without a full package rebuild.
* **The Solution in `colcon-core`**:
  - `_get_data_files_mapping(pkg)` inspects `setup.cfg` (`[options.data_files]`) or `pyproject.toml` (`[tool.setuptools.data-files]` / Hatchling's `[tool.hatch.build.targets.wheel.shared-data]`).
  - When `--symlink-install` is passed, `colcon_core.task.install()` creates **true filesystem symlinks** directly from the source launch/config files to `<install_base>/share/`.
  - Appends symlinked entries into `.dist-info/RECORD` so `remove_distributions` cleanly uninstalls them.
  - **Result**: You can edit `launch/demo.launch.py` in your editor, and `ros2 launch` immediately sees your changes without rebuilding!

---

### Scenario 4: Modern ROS 2 `ament_python` Without `setup.py` (`04_ros2_ament_pyproject`)

* **Directory**: [`examples/mock_packages/04_ros2_ament_pyproject`](../../examples/mock_packages/04_ros2_ament_pyproject)
* **Key Files**:
  ```text
  04_ros2_ament_pyproject/
  ├── ros_pyproject_pkg/
  │   ├── __init__.py
  │   ├── node.py
  │   └── launch/
  │       └── robot.launch.py
  ├── package.xml         <-- ROS 2 manifest (<build_type>ament_python</build_type>)
  ├── pyproject.toml      <-- PEP 621 manifest (NO setup.py!)
  └── README.md
  ```

#### How Colcon Processes It (Modernized `colcon-ros`):
1. **Identification**: `colcon-ros` identifies the package as `ros.ament_python` based on `package.xml`.
2. **Build Routing**: `AmentPythonBuildTask` detects that `setup.py` is absent and `pyproject.toml` is present:
   - Instead of failing looking for `setup.py`, it automatically delegates wheel compilation to `PythonProjectBuildTask`.
3. **Preserving ROS 2 Contracts**:
   - Creates the resource index marker: `<install_base>/share/ament_index/resource_index/packages/ros_pyproject_pkg` and records it in `.dist-info/RECORD`.
   - Copies (or symlinks under `--symlink-install`) `package.xml` into `<install_base>/share/ros_pyproject_pkg/package.xml` and records it in `.dist-info/RECORD`.
   - Generates the `AMENT_PREFIX_PATH` environment hook (`ament_prefix_path.dsv` / `.sh`) and registers it in `package.dsv` / `package.sh` and `.dist-info/RECORD`.
   - Installs `[project.scripts]` executables into `<install_base>/lib/ros_pyproject_pkg/` (`ros2 run` discovery path) via `script_dir_override`.
   - Populates `get_python_setup_options` via `RosAmentPythonPackageAugmentation` so `colcon test` discovers `pytest`.

---

## 📊 Comparison Matrix: Classic vs. Modern Builds

| Dimension | Classic (`01_classic_setup_py`) | Modern Pure PEP 621 (`02_modern_pep621_flit`) | Modern Editable (`03_modern_editable_data_files`) | Modern ROS 2 (`04_ros2_ament_pyproject`) |
| :--- | :--- | :--- | :--- | :--- |
| **Manifest** | `setup.py` + `setup.cfg` | `pyproject.toml` | `pyproject.toml` (+ `setup.cfg` data files) | `package.xml` + `pyproject.toml` |
| **Package Type** | `python` | `python.project` | `python.project` | `ros.ament_python` |
| **Priority** | 100 | 90 | 90 | Handled by ROS indexer |
| **Wheel Engine** | None (setuptools direct invocation) | In-process `install_wheel` (PR #741) | In-process `install_wheel` (PEP 660 editable) | In-process `install_wheel` |
| **CLI Wrappers** | Setuptools console_scripts | `distlib.scripts.ScriptMaker` (`0o755`) | `distlib.scripts.ScriptMaker` | `distlib.scripts.ScriptMaker` |
| **Data Files** | Static copy to `share/` | Static wheel `.data/` | **Live OS Symlinks** to source files | **Live OS Symlinks** / `package.xml` copied |
| **ROS Index** | Manual or setuptools data_files | None (pure Python) | None (pure Python) | **Automatic `ament_index` & `.dsv` hooks** |
| **Uninstallation** | Incomplete (leftover files) | Metadata-driven `remove_distributions` | Metadata-driven `remove_distributions` | Metadata-driven `remove_distributions` |

---

## 🛡️ Optional Feature Flag Strategy (`COLCON_FEATURE_FLAGS`)

If maintainers prefer a staged rollout to guarantee 0% risk of breaking production workspaces:
* Setting `COLCON_FEATURE_FLAGS=pep621_builds` gates `PEP621PackageIdentification`:
  - When unset: `colcon` ignores `pyproject.toml` and behaves identically to legacy releases.
  - When set: Modern Python project discovery activates automatically.
