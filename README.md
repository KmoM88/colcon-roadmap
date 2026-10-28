# colcon-roadmap: Native Standard Python Builds (PEP 517/518/621/660)

This repository orchestrates the engineering, testing, and upstream integration roadmap for bringing modern Python packaging standards (PEP 517, PEP 518, PEP 621, PEP 660) natively into [`colcon-core`](https://github.com/colcon/colcon-core) and [`colcon-ros`](https://github.com/colcon/colcon-ros).

---

## 🎯 Project Overview & Status

Direct invocation of `setup.py install` / `develop` has been deprecated across the Python ecosystem. This initiative replaces legacy shims and prototype extensions (`colcon-python-project`) by establishing native, high-performance, in-process wheel handling and metadata-driven packaging.

### Current Milestone Status

* **Phase 1: Harmonize `cottsay/pep621`** $\rightarrow$ **COMPLETED** (Commit `816a0d3`).
* **Phase 2: Multi-Backend Integration Testing** $\rightarrow$ **COMPLETED** (Commit `c40901a`, `flit_core` and `hatchling` test fixtures).
* **Phase 3: Upstream PR for `colcon-core`** $\rightarrow$ **SUBMITTED ([colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750))** (Targeting `cottsay/pep621`).
* **Phase 4: PEP 660 Editable Data Files & Script Override** $\rightarrow$ **DRAFT PR UPDATED ([colcon/colcon-core#751](https://github.com/colcon/colcon-core/pull/751))** (Commit `463df5f`, 46/46 CI checks passing).
* **Phase 5: ROS 2 `ament_python` Modernization in `colcon-ros`** $\rightarrow$ **DRAFT PR OPENED ([colcon/colcon-ros#171](https://github.com/colcon/colcon-ros/pull/171))** (Commit `fc03806`).
* **Phase 6: Prototype Deprecation (`colcon-python-project`)** $\rightarrow$ **PENDING UPSTREAM MERGE**.

---

## 🧭 Documentation Index

| Document | Purpose |
| :--- | :--- |
| **[Current Status](current_status.md)** | Technical analysis of merged PRs (#728, #732, #741), branch states, and test results. |
| **[Action Plan & Next Steps](action_plan_next_steps.md)** | Phased engineering roadmap, feature branch structure, and verification results. |
| **[Roadmap](roadmap.md)** | Architectural evolution, feature flags, and backend compatibility matrix. |
| **[Pitfalls & Remediation Plan](docs/plans/pitfalls_and_remediation_plan.md)** | Audit of 9 architectural pitfalls (ros2 run, colcon test, data files parity) and PR staging strategy. |
| **[Upstream Proposal (Gist)](https://gist.github.com/KmoM88/0357abff37b5a32ab801cac7d399d4ed)** | Staged architectural proposal submitted upstream ([docs/proposals/pep621_pep660_upstream_proposal.md](docs/proposals/pep621_pep660_upstream_proposal.md)). |
| **[Migration Instructions](migration_instructions.md)** | Transition strategy from `colcon-python-project` to native `colcon-core`. |

---

## 📦 Pull Request Submissions & Materials

All PR materials (titles, descriptions, test logs, and comparison links) are formatted and documented:

### 1. `colcon-core` Core PEP 621 Support (Fases 1, 2 y 3)
* **PR**: [colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750)
* **Target**: `colcon/colcon-core:cottsay/pep621` $\leftarrow$ `KmoM88:feature/pep621-upstream-pr`
* **Artifacts**: [docs/pr/pr_description_pep621.md](docs/pr/pr_description_pep621.md) & [docs/pr/issue_736_comment.md](docs/pr/issue_736_comment.md)
* **Compare URL**: [colcon/colcon-core:cottsay/pep621...KmoM88:colcon-core:feature/pep621-upstream-pr](https://github.com/colcon/colcon-core/compare/cottsay/pep621...KmoM88:colcon-core:feature/pep621-upstream-pr)

### 2. `colcon-core` PEP 660 Data Files Symlinking (Fase 4)
* **PR**: [colcon/colcon-core#751](https://github.com/colcon/colcon-core/pull/751) (Draft)
* **Target**: `colcon/colcon-core:master` $\leftarrow$ `KmoM88:feature/pep660-editable-data-files`
* **Artifact**: [docs/pr/pr_description_pep660_data_files.md](docs/pr/pr_description_pep660_data_files.md)
* **Compare URL**: [colcon/colcon-core:master...KmoM88:colcon-core:feature/pep660-editable-data-files](https://github.com/colcon/colcon-core/compare/master...KmoM88:colcon-core:feature/pep660-editable-data-files)

### 3. `colcon-ros` PEP 621 `ament_python` Support (Fase 5)
* **PR**: [colcon/colcon-ros#171](https://github.com/colcon/colcon-ros/pull/171) (Draft)
* **Target**: `colcon/colcon-ros:master` $\leftarrow$ `KmoM88:feature/ros-ament-python-project`
* **Artifact**: [docs/pr/pr_description_colcon_ros.md](docs/pr/pr_description_colcon_ros.md)
* **Compare URL**: [colcon/colcon-ros:master...KmoM88:colcon-ros:feature/ros-ament-python-project](https://github.com/colcon/colcon-ros/compare/master...KmoM88:colcon-ros:feature/ros-ament-python-project)

---

## 🧪 Verification & Linters

* **`colcon-core`**: Full suite passing (`256 passed, 5 skipped`, including unit, multi-backend integration, `flake8`, `scspell3k`, and copyright checks); **46/46 GitHub Actions checks green** on PR #751.
* **`colcon-ros`**: 1/1 integration tests passing in 0.13s; `flake8` clean (0 warnings).

---

## 🔬 Hands-On Mock Packages & Walkthrough Guide

To understand and test the behavior across all variations—from legacy `setup.py` packages to modern PEP 621 wheels, editable installs with live symlinked data files, and ROS 2 `ament_python`—a dedicated suite of mock packages and an automated demonstration runner are provided:

* **Comprehensive Guide**: [docs/guide/mock_packages_walkthrough.md](docs/guide/mock_packages_walkthrough.md)
* **Mock Packages**: [examples/mock_packages/](examples/mock_packages/)
  - `01_classic_setup_py`: Legacy `setup.py` / `setup.cfg` build lifecycle and egg-info generation.
  - `02_modern_pep621_flit`: Modern PEP 621 with `flit_core`, in-process wheel extraction, and CLI wrappers in `bin/`.
  - `03_modern_editable_data_files`: PEP 660 `--symlink-install` with OS symlinks for `share/` launch and config files (live modification without rebuilding).
  - `04_ros2_ament_pyproject`: Modern ROS 2 `ament_python` package without `setup.py`, preserving `ament_index`, `package.xml`, and environment hooks.
* **Run Demonstration Script**:
  ```bash
  submodules/kmom88-colcon-core/.venv/bin/python3 scripts/test_mock_packages.py
  ```
