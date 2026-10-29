# Roadmap: Native PEP 517/518/621/660 Support in colcon-core and colcon-ros

This roadmap tracks the delivery of modern Python packaging standards (PEP 517/518/621/660) across `colcon-core` and `colcon-ros`, replacing legacy `setup.py` invocations while maintaining backward compatibility with existing ROS and Python workspaces.

---

## 1. Context & Motivation

* **Standards Modernization**: The Python packaging ecosystem has deprecated direct invocations of `setup.py install` and `setup.py develop` in favor of standard build backends (Flit, Hatchling, Setuptools `build_meta`) declared in `pyproject.toml`.
* **Standardized Metadata**: Dependencies and package definitions are standardized in `pyproject.toml` (`[build-system]` and `[project]`).
* **Goal**: Provide native support in `colcon-core` and `colcon-ros` so Python and ROS 2 `ament_python` packages with standard `pyproject.toml` can be discovered, built, tested, installed, and uninstalled cleanly without external shims.

---

## 2. Merged Upstream Foundations (`colcon-core` `v0.21.2` / `v0.21.3`)

- [x] **PR #732: Hook Caller Infrastructure (`AsyncHookCaller`)**
  - Subprocess execution channel for backend hooks (`build_wheel`, `get_requires_for_build_wheel`) via OS pipes and pickle serialization.
  - Extension point `HookCallerDecoratorExtensionPoint`.
  - TOML parser loader (`load_and_cache_spec`) with standard `tomllib` (Python 3.11+) and fallbacks.

- [x] **PR #728: Distribution Metadata Discovery (`InstalledDistribution`)**
  - Live query and discovery of installed Python files, packages, namespaces, entry points, and bytecode caching (`.pyc`).

- [x] **PR #741: In-Process Wheel Installation & Uninstallation Engine (`wheel.py`)**
  - `remove_distributions`: Cleanly uninstalls previous package installations and prunes empty parent directories using disk metadata.
  - `install_wheel`: Unpacks `.whl` archives, maps `.data/` directories (e.g. `share/`), generates executable entry-point script wrappers via `distlib.scripts.ScriptMaker`, and writes PEP 376 `INSTALLER` and `RECORD` files.

---

## 3. Delivered Features & Active Pull Requests (Stages 1–3)

| Stage & Branch | Repository | Status | Focus & Deliverable |
| :--- | :--- | :--- | :--- |
| `cottsay/pep621` (`816a0d3`) | `KmoM88/colcon-core` | **Completed** | Aligned async test runner (`run_until_complete`), PEP 621 identification, augmentation & build task. |
| `feature/pep621-integration-tests` (`c40901a`) | `KmoM88/colcon-core` | **Completed** | Real multi-backend fixtures (`flit_core`, `hatchling`), CLI scripts, clean rebuilds. |
| **Stage 1**: `feature/pep621-upstream-pr` (`4a594c8`) | `KmoM88/colcon-core` | **PR #750 Submitted** | [colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750) targeting `cottsay/pep621`. |
| **Stage 2**: `feature/pep660-editable-data-files` (`463df5f`) | `KmoM88/colcon-core` | **PR #751 (Draft, 46/46 CI Green)** | [colcon/colcon-core#751](https://github.com/colcon/colcon-core/pull/751): Backend-scoped editable data files, `script_dir_override` + `$base` fix, deduplicated `RECORD` updates (`256 passed, 5 skipped`). |
| **Stage 3**: `feature/ros-ament-python-project` (`359ab5c`) | `KmoM88/colcon-ros` | **PR #171 (Draft, 16/16 pytest Green)** | [colcon/colcon-ros#171](https://github.com/colcon/colcon-ros/pull/171): `ament_python` `pyproject.toml` builds, `lib/<pkg>` script override for `ros2 run`, flat hooks, post-wheel `RECORD` tracking, and `colcon test` augmentation. |
| **Final Phase PoC**: [`poc/`](poc/README.md) | `KmoM88/colcon-roadmap` + `KmoM88/{demos,examples,teleop_twist_keyboard}` | **Implemented & Verified** | Dockerized ROS 2 Jazzy 6-stage showcase across active `ros2/*` packages migrated to pure `pyproject.toml` (`hatchling`, `flit_core`, `setuptools.build_meta`). |

> [!IMPORTANT]
> The full technical audit of 10 architectural pitfalls and their staged PR remediation matrix is maintained in **[docs/plans/pitfalls_and_remediation_plan.md](docs/plans/pitfalls_and_remediation_plan.md)**.

### Feature 1: PEP 621 Package Identification & Augmentation [COMPLETED — STAGE 1]
* **Status**: Submitted in [colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750) (`4a594c8`).
* **Scope**:
  - `colcon_core/package_identification/pep621.py`: Detects directories containing `pyproject.toml` with `[project].name` and assigns `python.project`.
  - `colcon_core/package_augmentation/pep621.py`: Maps `[build-system].requires`, `[project].dependencies`, and `[project.optional-dependencies].test`.

### Feature 2: PEP 517/621 Build Task Integration [COMPLETED — STAGE 1]
* **Status**: Submitted in [colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750) (`4a594c8`).
* **Scope**:
  - `colcon_core/task/python_project/build.py`: Invokes `build_wheel` / `build_editable` via `AsyncHookCaller`, unpacks via `install_wheel`, writes PEP 610 `direct_url.json`, and registers colcon environment hooks in `.dist-info/RECORD`.
  - Optional rollout gating supported via `COLCON_FEATURE_FLAGS=pep621_builds`.

### Feature 3: PEP 660 Editable Data Files & Script Directory Override [COMPLETED — STAGE 2]
* **Status**: Verified in Draft PR [colcon/colcon-core#751](https://github.com/colcon/colcon-core/pull/751) (`463df5f`, **46/46 GitHub Actions CI checks green**).
* **Scope**:
  - Exposes `script_dir_override=None` on `PythonProjectBuildTask.build()` and fixes relative `install_base` `$base` resolution.
  - Scopes `_get_data_files_mapping(pkg, backend_name)` to `setuptools.build_meta*` (with glob expansion across `setup.cfg` and `[tool.setuptools.data-files]`) and `hatchling.*` (file and directory `[tool.hatch.build.targets.wheel.shared-data]`).
  - Deduplicates `.dist-info/RECORD` entries in place when replacing wheel `.data/` copies with symbolic links.

### Feature 4: ROS 2 `ament_python` with Standard Python Builds [COMPLETED — STAGE 3]
* **Status**: Verified in Draft PR [colcon/colcon-ros#171](https://github.com/colcon/colcon-ros/pull/171) (`359ab5c`, **16/16 `pytest --cov --cov-branch` checks green** + **4/4 mock scenarios passing**).
* **Scope**:
  - `AmentPythonBuildTask`: Detects `package.xml` (`<build_type>ament_python</build_type>`) packages with `pyproject.toml` and no `setup.py`, delegates to `PythonProjectBuildTask` with `script_dir_override=Path('lib') / pkg.name` (`ros2 run` path) and flat `additional_hooks`, and installs/records `ament_index` and `package.xml` after wheel installation.
  - `RosAmentPythonPackageAugmentation`: Populates `get_python_setup_options` from `pyproject.toml` (`[project.dependencies]`, `[project.optional-dependencies]`, PEP 735 `[dependency-groups]`) so `AmentPythonTestTask` matches `pytest` during `colcon test`.

---

## 4. Planned Next Stages (Stages 4–5)

### Stage 4 — Group A: Independent Single-Concern PRs Targeting `colcon-core:master`
- [ ] **Stage 4B (`SetuptoolsDecorator`)**: Port `SetuptoolsDecorator` (`HookCallerDecoratorExtensionPoint`) to redirect `--build-base` and `--egg-base` to temporary directories so `setuptools.build_meta` never leaves `.egg-info/` in the source tree.
- [ ] **Stage 4D (Wheel `script_dir` & Windows Symlink Resilience)**: Ensure `script_dir.mkdir(parents=True, exist_ok=True)` in `colcon_core/python_project/wheel.py` before calling cached `ScriptMaker.make_multiple()` after `remove_distributions()`, and fall back to file copy with a warning on Windows when `os.symlink()` lacks `SeCreateSymbolicLinkPrivilege`.

### Stage 4 — Group B: Follow-Up Single-Concern PRs Stacked on `cottsay/pep621` (`#750`)
- [ ] **Stage 4A (`PythonProjectTestTask`)**: Register `python.project` under `colcon_core.task.test` so pure non-ROS PEP 621 packages run `pytest` natively via `colcon test`.
- [ ] **Stage 4C (Dynamic Metadata Hook Integration)**: Connect `PEP621PackageAugmentation` to `colcon_core.python_project.metadata.load_and_cache_metadata()` when `project.dynamic` fields (`version`, `dependencies`, `optional-dependencies`) are declared.

### Stage 5: Ecosystem Transition & Deprecation
- [ ] **Deprecate `colcon/colcon-python-project`**: Once Stages 1–3 merge upstream, publish a deprecation notice pointing to native `colcon-core` / `colcon-ros` support and close prototype PR #1.

---

## 5. Verification Commands

* **`colcon-core` unit & integration suite**:
  ```bash
  cd submodules/kmom88-colcon-core && .venv/bin/pytest
  ```
* **`colcon-ros` unit, integration & linter suite**:
  ```bash
  cd submodules/colcon-ros && .venv/bin/pytest --cov --cov-branch
  ```
* **End-to-end mock workspace scenarios (Scenarios 1–4)**:
  ```bash
  submodules/colcon-ros/.venv/bin/python3 scripts/test_mock_packages.py
  ```
* **Dockerized ROS 2 Jazzy Proof of Concept (Primary target or full 3-backend matrix)**:
  ```bash
  ./poc/run_poc.sh
  ./poc/run_poc.sh --target all
  ```
