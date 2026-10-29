# Pull Request: Port Wheel Installation & Uninstallation Utilities to colcon-core

## Overview

This PR ports the core Python wheel installation and uninstallation engine from the prototype extension `colcon-python-project` into `colcon-core`. 

Previously, `colcon-core` only supported legacy setuptools-centric installations that required spawning `setup.py` scripts. As Python platforms move away from direct `setup.py` invocations in favor of standard PEP 517/518 packaging structures, this PR introduces the native utilities required to install PEP 427 wheel archives (`.whl`) and safely clean up existing package distributions from the installation prefix.

By implementing this metadata-driven layout manager directly inside `colcon-core`, we establish the foundation for native PEP 517 build task execution and modern dependency resolution.

---

## Key Features

### 1. Metadata-Driven Uninstallation (`remove_distributions`)
* **Live Discovery**: Instead of depending on ephemeral local build-cache files (such as `install.log` or `.egg-info` symlinks in the build folder), the uninstallation utility queries the target `install_base` prefix using `InstalledDistribution.discover`.
* **Clean Deletions**: Traverses the registered package files and deletes them from the filesystem. It unlinks residual `.egg-link` files and recursively removes any empty parent directories up to the `install_base`.
* **Platform Resilience**: Deletions are guarded against file lock exceptions (particularly on Windows) by wrapping unlink and rmdir operations in exceptions handlers, logging warnings instead of crashing.

### 2. Wheel Layout Extraction & Mapping (`install_wheel`)
* **Wheel Extraction**: Extracts standard PEP 427 wheel packages and determines the target library destination (purelib or platlib) based on `Root-Is-Purelib` metadata inside the wheel's `WHEEL` file.
* **Data-Files Mapping**: Decodes `.data/` directory segments (e.g. `package-1.0.data/data/...`) inside the wheel ZIP, translating them to their platform-agnostic target locations (such as `share/`) dynamically via `_get_install_path`.
* **Console Scripts Wrap**: Parses entry point mappings defined in `entry_points.txt` and uses `distlib.scripts.ScriptMaker` to generate executable script wrappers under the scripts folder.
* **Standard Packaging Metadata**: Writes the PEP 376 compliant metadata files:
  * `INSTALLER`: Marked as installed by `colcon-core`.
  * `RECORD`: Finalizes and writes the cryptographic hash signatures (`sha256`) and sizes of all extracted and generated files.

---

## Design & Code Quality

* **Zero Code Duplication**: Avoids duplicating `enumerate_files_in_distribution` or `enumerate_py_compiled` helpers from the prototype. Instead, it reuses the newly merged `InstalledDistribution` interface and its file enumeration logic (merged in PR #728).
* **Centralized Path Resolution**: Imports `_get_install_path` directly from `colcon_core.python_project.distribution` to calculate target subdirectories consistently.
* **Coding Standards**: Fully conforms to the repository style guidelines:
  * Google-style grouped imports.
  * Comprehensive reStructuredText docstrings for all modules, classes, and methods.
  * Strict single-quotes string style.
  * Centralized logging via `colcon_logger`.

---

## Verification & Testing

This PR introduces comprehensive unit tests under the test suite:
* **[test_remove_wheel.py](submodules/kmom88-colcon-core/test/test_remove_wheel.py)**:
  * Sets up a mock workspace and dynamically copies distributions (`typical-dist-info`, `typical-egg-info`, `typical-egg-link`).
  * Asserts that `remove_distributions` successfully uninstalls standard, legacy, and egg-linked packages, deletes all associated files, and cleans up empty parent directories while leaving non-empty folders untouched.
* **[test_install_wheel.py](submodules/kmom88-colcon-core/test/test_install_wheel.py)**:
  * Programmatically mocks pure Python wheels, platform-specific wheels, wheels with console scripts, and wheels with data files.
  * Asserts that `install_wheel` extracts files into correct library paths, builds CLI scripts, maps data files to `share/`, and writes valid `INSTALLER` and `RECORD` files.
  * Verifies that the installer cleans up older package versions prior to installation.

### Automated Tests
Run the newly added test suites locally:
```bash
pytest test/test_wheel.py test/test_install_wheel.py
```
