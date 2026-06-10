# Skill: Submodule Remediation

This skill defines the Git commands and directory structures for adding and initializing remediation forks as Git submodules, and setting up their development branches.

## Procedures

### 1. Identity Resolution
Retrieve the active GitHub username to use for the branch names and repository URLs.
* Local Git username query:
  ```bash
  git config user.name
  ```
* Remote GitHub user query via MCP:
  - Call `github__get_me` to find the exact username (`login` field).

### 2. Git Submodule Addition
For a given target repository (`<repo-name>`), add the user's fork as a Git submodule:
* Path: `remediation/<repo-name>`
* Add Command:
  ```bash
  git submodule add https://github.com/<username>/<repo-name>.git remediation/<repo-name>
  ```

### 3. Submodule Branch Management
Navigate into the submodule and set up the development branch following the colcon-core PR naming pattern (`<username>/tmp-path`):
* Navigate to directory:
  ```bash
  cd remediation/<repo-name>
  ```
* Checkout development branch:
  ```bash
  git checkout -b <username>/tmp-path
  ```
* (Optional) Push the newly created branch to the fork's remote:
  ```bash
  git push -u origin <username>/tmp-path
  ```

### 4. Orchestrator Commits
Track the added submodules in the main repository:
* Add the changes:
  ```bash
  git add .gitmodules remediation/<repo-name>
  ```
* Commit changes:
  ```bash
  git commit -m "chore: add submodule for <repo-name> remediation"
  ```
