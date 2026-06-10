---
description: Setup remediation forks as submodules and check out development branches
---

# Workflow: Setup Remediation Forks

When the user types `/setup_remediation_forks`, execute the following sequential steps to initialize the forked repositories as submodules and prepare their development branches.

## Environment & Scope Context
* **Orchestrator Repository**: `KmoM88/colcon-roadmap`
* **Report Path**: `docs/outputs/test_reports/ecosystem_alignment_analysis.md`
* **Submodule Destination Directory**: `remediation/`
* **Submodule Branch Name Pattern**: `<username>/tmp-path` (e.g. `KmoM88/tmp-path`)

---

## Execution Steps

### Step 1: Fork List Extraction
1. Read the end of `docs/outputs/test_reports/ecosystem_alignment_analysis.md` and parse the JSON block to extract the `fork_list`.
2. Retrieve the active GitHub username (defaulting to the authenticated session username `KmoM88`).

### Step 2: Submodule Registration & Checkout Loop
For each repository in the `fork_list` (e.g. `colcon-cmake`, `colcon-library-path`, `colcon-python-setup-py`, `colcon-ros`):
1. **Directory Check**: Check if the submodule directory `remediation/<repo-name>` already exists in the workspace.
2. **Add Submodule**: Run the git command to register the fork as a submodule:
   ```bash
   git submodule add https://github.com/<username>/<repo-name>.git remediation/<repo-name>
   ```
3. **Branch Setup**: Enter the submodule directory, create and checkout the development branch:
   ```bash
   cd remediation/<repo-name>
   git checkout -b <username>/tmp-path
   ```
4. **Submodule Verification**: Confirm that the submodule is pointing to the correct branch and repository.

### Step 3: Workspace Commit & Push
In the orchestrator repository root:
1. Add the updated `.gitmodules` and the new submodule references:
   ```bash
   git add .gitmodules remediation/
   ```
2. Commit the changes:
   ```bash
   git commit -m "chore: setup submodules for remediation forks"
   ```
3. Push the current orchestrator branch to `origin`:
   ```bash
   git push origin feature/test-walkthrough-analysis
   ```
