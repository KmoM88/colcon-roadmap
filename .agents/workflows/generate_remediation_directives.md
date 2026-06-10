---
description: Analyze the colcon-core reference PR and generate detailed remediation directives for submodules
---

# Workflow: Generate Remediation Directives

When the user types `/generate_remediation_directives`, execute the following sequential steps to analyze the reference PR `colcon/colcon-core#729` and generate a detailed code-remediation directives document.

## Environment & Scope Context
* **Reference Repository**: `colcon/colcon-core`
* **Reference PR ID**: `729`
* **Target Submodule Repositories**:
  * `remediation/colcon-cmake`
  * `remediation/colcon-library-path`
  * `remediation/colcon-python-setup-py`
  * `remediation/colcon-ros`
* **Directives Output Path**: `docs/outputs/test_reports/remediation_directives.md`

---

## Execution Steps

### Step 1: Reference PR Pattern Synthesis
1. Use MCP tool `github__get_pull_request` or read the locally cached PR diff to synthesize the exact modifications:
   - **`test/conftest.py`**: Retrieve the compatibility fixture implementation for `tmp_path` when pytest version is older than 3.9.
   - **`TemporaryDirectory` usage**: Extract the transition from `with TemporaryDirectory() as tmp:` (manual string-based paths and cleanup) to injecting `tmp_path` (a pathlib Path object handled by pytest).
   - **`tmpdir` usage**: Extract the transition from `tmpdir` fixture to `tmp_path` fixture.

### Step 2: Code Search and Target Mapping
For each target submodule, locate the files that were identified as requiring alignment:
1. **`colcon-cmake`**:
   - `test/test_package_identification_cmake.py`
   - `test/test_environment_cmake_prefix_path.py`
   - `test/test_environment_cmake_module_path.py`
   - `test/test_task_cmake_build.py`
2. **`colcon-library-path`**:
   - `test/test_environment_library_path.py`
3. **`colcon-python-setup-py`**:
   - `test/test_package_identification_python_setup_py.py`
4. **`colcon-ros`**:
   - `test/test_ament_index_augmentation.py`
   - `test/test_package_identification_ros.py`

### Step 3: Directives Report Compilation
Write a comprehensive report at `docs/outputs/test_reports/remediation_directives.md` detailing:
1. **Conftest Template**: The exact code for `test/conftest.py` that needs to be added to each of the 4 repositories.
2. **Legacy Import Removals**: Identify which imports (e.g. `from tempfile import TemporaryDirectory`) must be deleted in each target file.
3. **Code Diffs**: Provide clear pseudodiffs or search-and-replace directives for each target file. Show the exact before-and-after of test function signatures and body blocks (including unindentation instructions for code previously inside `with` blocks).

### Step 4: Git Commit & Remote Lifecycle
1. Commit the generated directives report:
   ```bash
   git add docs/outputs/test_reports/remediation_directives.md
   git commit -m "docs: add remediation directives for colcon test alignment"
   ```
2. Push to the remote branch:
   ```bash
   git push origin feature/test-walkthrough-analysis
   ```
