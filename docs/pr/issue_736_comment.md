# Update Comment for Upstream Issue #736

**Issue**: [colcon/colcon-core#736](https://github.com/colcon/colcon-core/issues/736)  
**Target Topic**: Modern Python Packaging (PEP 517/518/621/660) Native Implementation Status

---

Hi @cottsay and colcon team,

Following up on the wheel extraction engine merged in #741 and the groundwork in branch `cottsay/pep621`:

I have completed, harmonized, and verified the end-to-end PEP 621 pipeline:

1. **Async Test Runner**:
   Adapted `test_task_python_project_build.py` to use `from .run_until_complete import run_until_complete` instead of `@pytest.mark.asyncio`, aligning it cleanly with `colcon-core`'s internal test conventions without requiring external plugins.
2. **End-to-End Integration Tests (`test/test_integration_pep621.py`)**:
   Added integration tests exercising real modern build backends:
   - Pure PEP 621 package build & runtime import with `flit_core`.
   - Entry point script generation and execution with `hatchling` (`[project.scripts]` $\rightarrow$ `bin/` wrapper).
   - Rebuilds and removal of deleted files via `remove_distributions`.
   - Editable installs with `--symlink-install` via `build_editable` and PEP 610 recording.
3. **Test Suite Status**:
   All 23 related tests pass cleanly (19 unit tests + 4 real backend integration tests), with 0 flake8 errors:
   ```bash
   pytest test/test_package_identification_pep621.py \
          test/test_package_augmentation_pep621.py \
          test/test_task_python_project_build.py \
          test/test_install_wheel.py \
          test/test_remove_wheel.py \
          test/test_integration_pep621.py
   # 23 passed in 0.74s
   ```
4. **Rebased Branch Available**:
   The commits are rebased on top of `master` preserving your authorship for the initial groundwork:
   [`KmoM88/colcon-core:feature/pep621-upstream-pr`](https://github.com/KmoM88/colcon-core/tree/feature/pep621-upstream-pr)
   (Comparison: https://github.com/colcon/colcon-core/compare/master...KmoM88:colcon-core:feature/pep621-upstream-pr)

I have opened PR #750 ([colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750)) targeting your branch `cottsay/pep621` so you can review and merge it into your branch directly.

To outline the broader roadmap, I compiled a staged proposal covering the follow-up steps (PEP 660 data files symlinking and ROS 2 `ament_python` support) in this gist:
👉 https://gist.github.com/KmoM88/0357abff37b5a32ab801cac7d399d4ed

Thanks!
