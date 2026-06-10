---
description: Test alignment scan
---

# Workflow: Test Alignment Scan

When the user types `/test_alignment` execute the following sequential steps to complete the test consistency analysis across the target ecosystem.

## Environment & Scope Context
* **Reference Repository**: `colcon/colcon-core`
* **Reference PR ID**: `729`
* **Target Repositories List**:
    * `colcon-common-extensions`
    * `colcon-argcomplete`
    * `colcon-bash`
    * `colcon-cd`
    * `colcon-cmake`
    * `colcon-core`
    * `colcon-defaults`
    * `colcon-devtools`
    * `colcon-library-path`
    * `colcon-metadata`
    * `colcon-notification`
    * `colcon-output`
    * `colcon-package-information`
    * `colcon-package-selection`
    * `colcon-parallel-executor`
    * `colcon-powershell`
    * `colcon-python-setup-py`
    * `colcon-recursive-crawl`
    * `colcon-ros`
    * `colcon-test-result`
    * `colcon-zsh`
* **Orchestrator Repository**: `your-username/colcon-migration-orchestrator`

---

## Execution Steps

### Step 1: Pattern Extraction
1. Invoke `TestAnalystAgent` to read the reference PR from `colcon/colcon-core` using the MCP tool `github__get_pull_request`.
2. Extract the canonical test architecture, naming conventions, and setup requirements.

### Step 2: Ecosystem Evaluation Loop
For each repository in the target list, execute the following sub-steps sequentially using MCP tools:
1. **Directory Validation**: Call `github__get_repository_content` for the root path. Check for the existence of testing directories.
2. **Structural Comparison**: If test files exist, fetch content via `github__get_file_contents`. Assess if files align with the `colcon-core` implementation rules.
3. **Classification**: Categorize the repository into one of two groups:
    * `Missing Tests`: No testing framework or files found.
    * `Refactor Required`: Tests exist but use outdated patterns or lack alignment with the reference PR logic.

### Step 3: Synthesis and Report Generation
1. Compile the granular repository analysis into a structured Markdown document tracking the justification for each classification.
2. Append a conclusive summary detailing which repositories must be forked to execute remediation.

### Step 4: Workspace Commit & Remote Lifecycle
1. Instruct `OrchestratorPRAgent` to write the finalized report to `docs/outputs/test_reports/ecosystem_alignment_analysis.md`.
2. Execute native git terminal actions within the orchestrator repository:
    ```bash
    git checkout -b feature/test-walkthrough-analysis
    git add docs/outputs/test_reports/ecosystem_alignment_analysis.md
    git commit -m "docs: add colcon ecosystem test alignment analysis"
    git push origin feature/test-walkthrough-analysis
    ```
3. Use MCP tool `github__create_pull_request` to open a Pull Request targeting `main` in the orchestrator repository.

---

## Final Output Structure Expectation
The generated report file must conclude exactly with this markdown JSON snippet for subsequent execution automation:

```json
{
  "fork_list": [
    "repo-name-to-fork-1",
    "repo-name-to-fork-2"
  ]
}