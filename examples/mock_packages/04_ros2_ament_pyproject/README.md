# ros_pyproject_pkg

Modern ROS 2 package using `<build_type>ament_python</build_type>` without `setup.py`.
Builds via `colcon-ros`'s modernized `AmentPythonBuildTask` and `colcon-core`'s `PythonProjectBuildTask`, installing `[project.scripts]` executables into `lib/ros_pyproject_pkg/` (`ros2 run` layout), registering `ament_index` and `package.xml` in `.dist-info/RECORD`, and exposing test dependencies via `RosAmentPythonPackageAugmentation`.
