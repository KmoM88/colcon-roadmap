# data_pkg

Demonstrates backend-scoped PEP 660 `--symlink-install` behavior for non-Python data files using `hatchling` `[tool.hatch.build.targets.wheel.shared-data]`.
Launch files and config files under `share/` are copied during standard builds and directly symlinked to the source directory during `--symlink-install`.
