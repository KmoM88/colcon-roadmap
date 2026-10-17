# Proposed Issue Comment: Phase 2 Migration Approach & Divergences

Hi everyone,

Following up on the proposed roadmap, I have analyzed the prototype code in `colcon-python-project` and prepared the specific approach for **Phase 2: Standard PEP 517 Build Task Adoption**. 

Here is a summary of how we plan to approach this phase, including a few notable divergences from the original proposal to align with `colcon-core`'s architecture and improve performance/reliability.

---

## 1. Divergences from the Original Phase 2 Proposal

### A. In-Process Wheel Installation vs. Subprocess `pip`
* **Original Proposal**: Spawn a subprocess to run `python -m pip install --no-deps --target / <wheel>`.
* **Adjusted Approach**: Perform **in-process wheel extraction and installation** (ported from the `colcon-python-project` prototype).
* **Rationale**: Spawning `pip` has notable overhead, requires `pip` to be present in the target interpreter's environment, and makes it harder to control metadata creation. By unzipping the wheel in-process, we can:
  1. Directly map `.data/` subpaths to their correct locations (like `share/`) without relying on platform-specific install schemes.
  2. Write a clean PEP 376-compliant `INSTALLER` record (indicating installation by `colcon-core`).
  3. Write and sign the finalized `.dist-info/RECORD` file containing accurate relative paths, sizes, and SHA-256 hashes of all written files (including the generated console script wrappers).

### B. Leveraging the PR #728 Discovery Framework
* **Original Proposal**: Described a general requirement to uninstall previous wheels.
* **Adjusted Approach**: We will leverage the newly merged **PR #728** (`InstalledDistribution` and `get_installed_files()`) to implement uninstallation.
* **Rationale**: PR #728 already contains the complex metadata discovery and file-enumeration logic. We can use it directly to find and cleanly delete *any* existing metadata footprint (such as old `.egg-info` directories, `.egg-link` files, or `.dist-info` wheels) and clean up empty parent directories before unpacking the new wheel. This avoids duplicating file-scanning utilities.

---

## 2. Proposed Implementation Steps (Phased PRs)

To keep reviews manageable, we propose splitting Phase 2 into **three sequential pull requests**:

### PR 1: Uninstallation & Cleanup Utilities (`remove_distributions`)
* **Task**: Implement `remove_distributions(name, install_base)` in a new module `colcon_core/python_project/wheel.py`.
* **Approach**: Uses `InstalledDistribution.discover` to find the package's existing files, unlinks them, recursively cleans up empty parent directories, and deletes any `.egg-link` references.
* **Testing**: Add `test/test_wheel.py` reusing the mock distribution fixtures (`typical-dist-info`, `typical-egg-link`, etc.) introduced in PR #728.

### PR 2: In-Process Wheel Installation Engine (`install_wheel`)
* **Task**: Implement `install_wheel(wheel_path, install_base)` in `colcon_core/python_project/wheel.py`.
* **Approach**: Unpacks the wheel, maps `.data/` subdirectories, generates executable script wrappers for entry points via `distlib.scripts.ScriptMaker`, and writes the completed `RECORD` and `INSTALLER` metadata.
* **Testing**: Unit tests mocking `.whl` ZIP structures containing package code, entry points, and `.data/` files to verify correct target output mapping.

### PR 3: Build Task Integration (`PythonBuildTask` Routing)
* **Task**: Modify `PythonBuildTask.build` in `colcon_core/task/python/build.py`.
* **Approach**: Route to the PEP 517 build path if `pyproject.toml` is present and `setup.py` is absent. Call the backend hook `build_wheel` via `AsyncHookCaller` and pass the path of the built wheel to `install_wheel`. Ensure CLI parameters are forwarded, and that post-install environment hook/script generation continues to run unmodified.

---

I would appreciate any feedback or thoughts on this approach—particularly the pivot to in-process wheel extraction instead of executing `pip`.
