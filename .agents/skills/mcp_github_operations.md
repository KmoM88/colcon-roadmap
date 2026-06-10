# Skill: MCP GitHub Operations

This skill outlines instructions for utilizing the editor-installed GitHub MCP server tools to interact with remote repositories without local cloning.

## Available MCP Tool Specifications

### 1. Code Ingestion & Diff Analysis
* **Tool**: `github__get_pull_request` or `github__get_pull_request_diff`
* **Usage Context**: Fetch the merged PR from `colcon/colcon-core` containing updated tests.
* **Extraction Targets**: Inspect changed files under `test/` directories, noting specific `pytest` fixtures, class arrangements, and mock structures.

### 2. Remote Repository Inspection
* **Tool**: `github__get_repository_content`
* **Usage Context**: Query directory listings for target repositories sequentially.
* **Extraction Targets**: Verify existence of `test/` or `tests/` directories at root.

### 3. Deep File Inspection
* **Tool**: `github__get_file_contents`
* **Usage Context**: Retrieve code contents of discovered test files.
* **Extraction Targets**: Analyze import baselines, instantiation configurations, and structural patterns to compare against the `colcon-core` reference.

### 4. Direct Pull Request Generation
* **Tool**: `github__create_pull_request`
* **Usage Context**: Open an automated PR on the orchestrator repository containing the final ecosystem analysis.