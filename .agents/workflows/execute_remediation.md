---
description: Implement remediation directives and run testing across forked submodules
---

# Workflow: Execute Remediation

When the user types `/execute_remediation`, execute the following sequential steps to apply the generated code changes, run pytest tests, and push the updates to both the submodules and the orchestrator repository.

## Environment & Scope Context
* **Orchestrator Repository**: `KmoM88/colcon-roadmap`
* **Directives Guide Path**: `docs/outputs/test_reports/remediation_directives.md`
* **Submodule Base Directory**: `remediation/`
* **Submodule Branch Name Pattern**: `<username>/tmp-path` (e.g. `KmoM88/tmp-path`)

---

## Execution Steps

### Step 1: Parse Directives
1. Read `docs/outputs/test_reports/remediation_directives.md` to extract the code modifications for each submodule:
   - `colcon-cmake`
   - `colcon-library-path`
   - `colcon-python-setup-py`
   - `colcon-ros`

### Step 2: Apply Code Modifications
For each submodule:
1. **Conftest Addition**: Create/write `test/conftest.py` with the compatibility fixture.
2. **Test File Refactoring**: Modify the target files to:
   - Remove `from tempfile import TemporaryDirectory` imports.
   - Inject `tmp_path` into test signatures.
   - Eliminate `with TemporaryDirectory() as ...` blocks, converting contents to use `str(tmp_path)` where necessary, and unindent the nested body.
   - Transition `tmpdir` arguments to `tmp_path` and use `Path` conversion if required.

### Step 3: Local Verification
For each submodule:
1. Navigate into the submodule directory:
   ```bash
   cd remediation/<repo-name>
   ```
2. Create and activate a clean virtual environment specifically for this submodule:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```
3. Install the submodule in editable mode along with testing requirements and dependency baselines:
   ```bash
   pip install --upgrade pip setuptools
   pip install -e .[test]
   # Install any additional required packages if not pulled by editable install
   pip install pytest pytest-cov colcon-core
   ```
4. Execute tests using pytest:
   ```bash
   pytest
   ```
5. Confirm that the test suite compiles and runs successfully, with 100% test pass rate. If errors occur, troubleshoot and fix.
6. Deactivate the virtual environment and return to the workspace root:
   ```bash
   deactivate
   cd ../..
   ```

### Step 4: Commit & Push Submodule Updates
For each submodule:
1. Navigate to the submodule directory:
   ```bash
   cd remediation/<repo-name>
   ```
2. Check that the branch is correct:
   ```bash
   git branch --show-current  # Should be KmoM88/tmp-path
   ```
3. Add and commit all modifications:
   ```bash
   git add .
   git commit -m "refact: unify temporary directory allocation to tmp_path"
   ```
4. Push the branch to your remote fork on GitHub:
   ```bash
   git push origin KmoM88/tmp-path
   ```
5. Return to workspace root:
   ```bash
   cd ../..
   ```

### Step 5: Update Orchestrator
In the orchestrator root repository:
1. Track the updated submodule gitlinks:
   ```bash
   git add remediation/
   ```
2. Commit the changes:
   ```bash
   git commit -m "chore: update submodule pointers to unified tmp_path implementations"
   ```
3. Push to origin:
   ```bash
   git push origin feature/test-walkthrough-analysis
   ```
