Following up on the PEP 517/518/621 discussion in #736 and the groundwork in `cottsay/pep621`:

This PR completes the core PEP 621 pipeline and brings it into full alignment with repository test standards:

1. **Test Runner Alignment**: Adapted async tests to `from .run_until_complete import run_until_complete`, matching `colcon-core` internal conventions without external pytest plugin dependencies.
2. **Multi-Backend Integration Tests (`test_integration_pep621.py`)**: Added automated end-to-end fixtures validating real packaging workflows with `flit_core` and `hatchling` (pure PEP 621 packages, entry-point CLI script wrappers in `bin/` with `0o755` permissions, clean rebuild removals, and editable builds).
3. **Linters & CI Conformance**: Fully compliant with `flake8` and `scspell3k`.

---

### Staged Roadmap Proposal
To keep review manageable and prevent regressions, the broader modernization plan (covering subsequent stages such as PEP 660 non-Python data files symlinking and ROS 2 `ament_python` support in `colcon-ros`) is documented in this staged architectural proposal:

👉 **https://gist.github.com/KmoM88/0357abff37b5a32ab801cac7d399d4ed**

| Stage | Component | Branch / Deliverable | Status |
| :--- | :--- | :--- | :--- |
| **Stage 1 (Current)** | `colcon-core` | **PR #750** (`feature/pep621-upstream-pr` $\rightarrow$ `cottsay/pep621`) | **In Review** |
| **Stage 2** | `colcon-core` | `feature/pep660-editable-data-files` (Symlinking `share/` assets for `--symlink-install`) | **Ready & Tested** |
| **Stage 3** | `colcon-ros` | `feature/ros-ament-python-project` (`ament_python` with pure `pyproject.toml`) | **Ready & Tested** |
| **Stage 4** | `colcon-python-project` | Deprecate standalone prototype repository | **Planned** |
