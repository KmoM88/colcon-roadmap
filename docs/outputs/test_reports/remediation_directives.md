# Colcon Ecosystem Test Remediation Directives

This document specifies the exact code modifications required to unify temporary directory allocation across the `colcon` ecosystem based on the reference patterns in `colcon/colcon-core#729`.

---

## 1. Compatibility Fixture (test/conftest.py)

Add the following compatibility fixture file `test/conftest.py` to each of the target repositories: `colcon-cmake`, `colcon-library-path`, `colcon-python-setup-py`, and `colcon-ros`.

```python
# Copyright 2026 Open Source Robotics Foundation, Inc.
# Licensed under the Apache License, Version 2.0

from itertools import takewhile
from pathlib import Path

import pytest

pytest_version = tuple(
    int(x) for x in takewhile(str.isdigit, pytest.__version__.split('.'))
)

if pytest_version < (3, 9):
    @pytest.fixture
    def tmp_path(tmpdir):
        """
        Compatibility fixture for temporary directory allocation.

        This can be removed when we drop support for platforms with Pytest
        versions older than 3.9 (namely Enterprise Linux 8).
        """
        return Path(tmpdir)
```

---

## 2. Target Repositories Code Modifications

### 2.1. colcon-cmake

#### File: `test/test_package_identification_cmake.py`
* **Imports**: Remove `from tempfile import TemporaryDirectory`.
* **Signature**: Add `tmp_path` to `test_identify`.
* **Body**: Replace the `with TemporaryDirectory...` block with `basepath = tmp_path` and unindent the nested body.
* **Pseudodiff**:
```diff
-from tempfile import TemporaryDirectory
...
-def test_identify():
+def test_identify(tmp_path):
     extension = CmakePackageIdentification()
 
-    with TemporaryDirectory(prefix='test_colcon_') as basepath:
-        desc = PackageDescriptor(basepath)
+    basepath = tmp_path
+    desc = PackageDescriptor(basepath)
...
-        basepath = Path(basepath)
```

#### File: `test/test_environment_cmake_prefix_path.py`
* **Imports**: Remove `from tempfile import TemporaryDirectory`.
* **Signature**: Add `tmp_path` to `test_cmake_prefix_path`.
* **Body**: Replace the `with TemporaryDirectory...` block with `prefix_path = tmp_path` and unindent the nested body.
* **Pseudodiff**:
```diff
-from tempfile import TemporaryDirectory
...
-def test_cmake_prefix_path():
+def test_cmake_prefix_path(tmp_path):
     extension = CmakePrefixPathEnvironment()
 
-    with TemporaryDirectory(prefix='test_colcon_') as prefix_path:
-        prefix_path = Path(prefix_path)
-        with patch(
-            'colcon_cmake.environment.cmake_prefix_path'
-            '.create_environment_hook',
-            return_value=['/some/hook', '/other/hook']
-        ):
...
+    prefix_path = tmp_path
+    with patch(
+        'colcon_cmake.environment.cmake_prefix_path'
+        '.create_environment_hook',
+        return_value=['/some/hook', '/other/hook']
+    ):
```

#### File: `test/test_environment_cmake_module_path.py`
* **Imports**: Remove `from tempfile import TemporaryDirectory`.
* **Signature**: Add `tmp_path` to `test_cmake_module_path`.
* **Body**: Replace the `with TemporaryDirectory...` block with `prefix_path = tmp_path` and unindent the nested body.
* **Pseudodiff**:
```diff
-from tempfile import TemporaryDirectory
...
-def test_cmake_module_path():
+def test_cmake_module_path(tmp_path):
     extension = CmakeModulePathEnvironment()
 
-    with TemporaryDirectory(prefix='test_colcon_') as prefix_path:
-        prefix_path = Path(prefix_path)
-        with patch(
-            'colcon_cmake.environment.cmake_module_path.'
-            'create_environment_hook',
-            return_value=['/some/hook', '/other/hook']
-        ):
...
+    prefix_path = tmp_path
+    with patch(
+        'colcon_cmake.environment.cmake_module_path.'
+        'create_environment_hook',
+        return_value=['/some/hook', '/other/hook']
+    ):
```

#### File: `test/test_task_cmake_build.py`
* **Signature**: Change `tmpdir` to `tmp_path` in `test_build_package`.
* **Body**: Remove the `tmp_path = Path(tmpdir)` casting.
* **Pseudodiff**:
```diff
-def test_build_package(tmpdir, cmake_target):
-    tmp_path = Path(tmpdir)
+def test_build_package(tmp_path, cmake_target):
     _test_build_package(tmp_path, cmake_target=cmake_target)
```

---

### 2.2. colcon-library-path

#### File: `test/test_environment_library_path.py`
* **Signature**: Change `tmpdir` to `tmp_path` in `test_library_path`.
* **Body**: Replace `prefix_path = Path(tmpdir)` with `prefix_path = tmp_path`.
* **Pseudodiff**:
```diff
-def test_library_path(tmpdir, search_path):
+def test_library_path(tmp_path, search_path):
     extension = LibraryPathEnvironment()
-    prefix_path = Path(tmpdir)
+    prefix_path = tmp_path
```

---

### 2.3. colcon-python-setup-py

#### File: `test/test_package_identification_python_setup_py.py`
* **Imports**: Remove `from tempfile import TemporaryDirectory`.
* **Signature**: Add `tmp_path` to `test_identify`.
* **Body**: Replace the `with TemporaryDirectory...` block with `basepath = tmp_path` and unindent the nested body.
* **Pseudodiff**:
```diff
-from tempfile import TemporaryDirectory
...
-def test_identify():
+def test_identify(tmp_path):
     extension = PythonPackageIdentification()
     augmentation_extension = PythonPackageAugmentation()
 
-    with TemporaryDirectory(prefix='test_colcon_') as basepath:
-        desc = PackageDescriptor(basepath)
+    basepath = tmp_path
+    desc = PackageDescriptor(basepath)
```

---

### 2.4. colcon-ros

#### File: `test/test_ament_index_augmentation.py`
* **Imports**: Remove `from tempfile import TemporaryDirectory`.
* **Signature**: Add `tmp_path` to `test_ament_index_augmentation`.
* **Body**: Replace the `with TemporaryDirectory...` block with `mock_prefix = tmp_path` and unindent the nested body.
* **Pseudodiff**:
```diff
-from tempfile import TemporaryDirectory
...
-def test_ament_index_augmentation():
-    with TemporaryDirectory() as mock_prefix:
-        mock_prefix = Path(mock_prefix)
+def test_ament_index_augmentation(tmp_path):
+    mock_prefix = tmp_path
```

#### File: `test/test_package_identification_ros.py`
* **Imports**: Remove `from tempfile import TemporaryDirectory`.
* **Signature**: Add `tmp_path` to `test_identify`.
* **Body**: Replace the `with TemporaryDirectory...` block with `basepath = tmp_path` and unindent the nested body.
* **Pseudodiff**:
```diff
-from tempfile import TemporaryDirectory
...
-def test_identify():
+def test_identify(tmp_path):
     extension = RosPackageIdentification()
     augmentation_extension = extension
 
-    with TemporaryDirectory(prefix='test_colcon_') as basepath:
-        desc = PackageDescriptor(basepath)
+    basepath = tmp_path
+    desc = PackageDescriptor(basepath)
```
