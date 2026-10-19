# colcon-roadmap: Native Standard Python Builds (PEP 517/518/621/660)

This repository orchestrates the engineering, testing, and upstream integration roadmap for bringing modern Python packaging standards (PEP 517, PEP 518, PEP 621, PEP 660) natively into [`colcon-core`](https://github.com/colcon/colcon-core) and [`colcon-ros`](https://github.com/colcon/colcon-ros).

---

## 🎯 Project Overview & Status

Direct invocation of `setup.py install` / `develop` has been deprecated across the Python ecosystem. This initiative replaces legacy shims and prototype extensions (`colcon-python-project`) by establishing native, high-performance, in-process wheel handling and metadata-driven packaging.

### Current Milestone Status

* **Phase 1: Harmonize `cottsay/pep621`** $\rightarrow$ **COMPLETED** (Commit `816a0d3`).
* **Phase 2: Multi-Backend Integration Testing** $\rightarrow$ **COMPLETED** (Commit `c40901a`, `flit_core` and `hatchling` test fixtures).
* **Phase 3: Upstream PR Preparation for `colcon-core`** $\rightarrow$ **READY FOR SUBMISSION** (Rebased on `master`).
* **Phase 4: PEP 660 Editable Data Files Symlinking** $\rightarrow$ **COMPLETED** (Commit `de2050f`).
* **Phase 5: ROS 2 `ament_python` Modernization in `colcon-ros`** $\rightarrow$ **COMPLETED** (Commit `fc03806`).
* **Phase 6: Prototype Deprecation (`colcon-python-project`)** $\rightarrow$ **PENDING UPSTREAM MERGE**.

---

## 🧭 Documentation Index

| Document | Purpose |
| :--- | :--- |
| **[Current Status](current_status.md)** | Technical analysis of merged PRs (#728, #732, #741), branch states, and test results. |
| **[Action Plan & Next Steps](action_plan_next_steps.md)** | Phased engineering roadmap, feature branch structure, and verification results. |
| **[Roadmap](roadmap.md)** | Architectural evolution, feature flags, and backend compatibility matrix. |
| **[Migration Instructions](migration_instructions.md)** | Transition strategy from `colcon-python-project` to native `colcon-core`. |

---

## 📦 Pull Request Submissions & Materials

All PR materials (titles, descriptions, test logs, and comparison links) are formatted and ready for manual web submission:

### 1. `colcon-core` Core PEP 621 Support (Fases 1, 2 y 3)
* **Target**: `colcon/colcon-core:master` $\leftarrow$ `KmoM88:feature/pep621-upstream-pr`
* **Artifacts**: [docs/pr/pr_description_pep621.md](docs/pr/pr_description_pep621.md) & [docs/pr/issue_736_comment.md](docs/pr/issue_736_comment.md)
* **Compare URL**: [colcon/colcon-core:master...KmoM88:colcon-core:feature/pep621-upstream-pr](https://github.com/colcon/colcon-core/compare/master...KmoM88:colcon-core:feature/pep621-upstream-pr)

### 2. `colcon-core` PEP 660 Data Files Symlinking (Fase 4)
* **Target**: `colcon/colcon-core:master` $\leftarrow$ `KmoM88:feature/pep660-editable-data-files`
* **Artifact**: [docs/pr/pr_description_pep660_data_files.md](docs/pr/pr_description_pep660_data_files.md)
* **Compare URL**: [colcon/colcon-core:master...KmoM88:colcon-core:feature/pep660-editable-data-files](https://github.com/colcon/colcon-core/compare/master...KmoM88:colcon-core:feature/pep660-editable-data-files)

### 3. `colcon-ros` PEP 621 `ament_python` Support (Fase 5)
* **Target**: `colcon/colcon-ros:master` $\leftarrow$ `KmoM88:feature/ros-ament-python-project`
* **Artifact**: [docs/pr/pr_description_colcon_ros.md](docs/pr/pr_description_colcon_ros.md)
* **Compare URL**: [colcon/colcon-ros:master...KmoM88:colcon-ros:feature/ros-ament-python-project](https://github.com/colcon/colcon-ros/compare/master...KmoM88:colcon-ros:feature/ros-ament-python-project)

---

## 🧪 Verification & Linters

* **`colcon-core`**: 24/24 unit and integration tests passing (`pytest`) in 0.70s; `flake8` clean (0 warnings).
* **`colcon-ros`**: 1/1 integration tests passing in 0.13s; `flake8` clean (0 warnings).
