An update on the native implementation status for PEP 517/518/621/660:

Following the merged wheel extraction and uninstallation engine (#741) and the groundwork in branch `cottsay/pep621`, PR #750 has been submitted to complete and verify the core PEP 621 pipeline:

* **PR**: [colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750) (targeting branch `cottsay/pep621`)
* **Head Branch**: [`KmoM88/colcon-core:feature/pep621-upstream-pr`](https://github.com/KmoM88/colcon-core/tree/feature/pep621-upstream-pr)

### Highlights of PR #750:
1. **Test Runner Alignment**: Converted async tests to use `from .run_until_complete import run_until_complete` (no `pytest-asyncio` plugin dependency).
2. **Integration Suite**: Added multi-backend automated integration tests (`test/test_integration_pep621.py`) covering `flit_core` and `hatchling` (CLI script generation in `bin/` with `0o755` permissions, clean rebuild removals, and editable builds).
3. **Linters**: Passing `flake8` and `scspell3k` (27/27 test items passing).

---

### Architectural Roadmap & Staged Proposal
To structure the ecosystem rollout (including editable data files symlinking for ROS 2 launch files and `ament_python` support in `colcon-ros`), a comprehensive staged proposal is available here:

👉 **https://gist.github.com/KmoM88/0357abff37b5a32ab801cac7d399d4ed**
