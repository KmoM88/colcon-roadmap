# Stage 5: `colcon-python-project` Deprecation & Archival Plan (Planned Only — No Implementation)

* **Parent Plan**: [PR, Branch, Feature & Release Plan](../README.md)
* **Historic Prototype Context**: [Historic PRs & Prototype Reference](../historic_prs_reference.md)

> [!IMPORTANT]
> **Status: PLANNED ONLY — NO IMPLEMENTATION**
> Per project scope and release sequencing, Stage 5 is strictly a **post-merge, post-release plan**. No branches, commits, pull requests, comments, or repository settings changes have been (or should be) executed on `colcon/colcon-python-project` prior to the upstream merges and tagged releases of Waves 1–3.

---

## 1. Stage Metadata

| Field | Value |
| :--- | :--- |
| **Stage** | Stage 5 (Release Wave 4) |
| **Status** | **Planned Only — No Implementation** |
| **Target Repository** | [`colcon/colcon-python-project`](https://github.com/colcon/colcon-python-project) |
| **Related Historic PR** | [colcon/colcon-python-project#1](https://github.com/colcon/colcon-python-project/pull/1) |
| **Blocking Preconditions** | Tagged upstream releases of `colcon-core` (Waves 1–2) and `colcon-ros` (Wave 3) |

---

## 2. Rationale for Holding Stage 5 as Planned-Only

1. **Upstream Release Dependency**: Users and evaluators referencing `colcon/colcon-python-project` or [colcon/colcon-core#736](https://github.com/colcon/colcon-core/issues/736) need released PyPI / Debian packages of `colcon-core` and `colcon-ros` containing native PEP 621 / PEP 660 support before the prototype repository is formally marked deprecated or archived.
2. **Maintainer Ownership**: Closing [colcon/colcon-python-project#1](https://github.com/colcon/colcon-python-project/pull/1) and archiving the `colcon/colcon-python-project` GitHub repository are administrative maintainer actions performed after the native pull requests land.

---

## 3. Entry Gate Checklist (Must Be Completed Before Executing Stage 5)

Stage 5 becomes eligible for execution **only after** all of the following upstream milestones are complete:

- [ ] **Wave 1 Merged**: [colcon/colcon-core#750](https://github.com/colcon/colcon-core/pull/750) + `colcon/colcon-core:cottsay/pep621` merged into `colcon/colcon-core:master`, alongside Group A follow-ups ([stage4_group_a_master_followups.md](stage4_group_a_master_followups.md)).
- [ ] **Wave 2 Merged & Released**: [colcon/colcon-core#751](https://github.com/colcon/colcon-core/pull/751) and Group B follow-ups ([stage4_group_b_pep621_followups.md](stage4_group_b_pep621_followups.md)) merged into `colcon/colcon-core:master` and published in a tagged `colcon-core` release.
- [ ] **Wave 3 Merged & Released**: [colcon/colcon-ros#171](https://github.com/colcon/colcon-ros/pull/171) merged into `colcon/colcon-ros:master` (with updated `colcon-core` minimum version) and published in a tagged `colcon-ros` release.

---

## 4. Planned Post-Release Actions (Future Maintainer Steps)

Once all Section 3 entry gates are satisfied:

1. **README Deprecation Notice in `colcon/colcon-python-project`**:
   - Add a short top-of-README notice stating that `colcon-python-project` was an experimental prototype whose functionality has been integrated natively into `colcon-core` (for pure Python `pyproject.toml` packages) and `colcon-ros` (for ROS 2 `ament_python` `pyproject.toml` packages), noting the minimum released versions of both packages.
2. **Close Prototype PR #1 & Update Issue #736**:
   - Close [colcon/colcon-python-project#1](https://github.com/colcon/colcon-python-project/pull/1) with cross-links to the merged `colcon-core` and `colcon-ros` pull requests and release tags.
   - Post final completion links on [colcon/colcon-core#736](https://github.com/colcon/colcon-core/issues/736).
3. **Repository Archival**:
   - Archive `colcon/colcon-python-project` as read-only on GitHub so search results and historical links remain intact without accepting new issues or PRs.
