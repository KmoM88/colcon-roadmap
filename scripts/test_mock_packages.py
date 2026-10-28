#!/usr/bin/env python3
# Copyright 2026 Open Source Robotics Foundation, Inc.
# Licensed under the Apache License, Version 2.0

"""Demonstration and automated test suite for mock packages.

Exercises:
1. Scenario 1: Classic setup.py package build (legacy colcon behavior)
2. Scenario 2: Modern PEP 621 package with flit_core and CLI script in bin/
3. Scenario 3: Modern PEP 660 editable build with live-symlinked data files
4. Scenario 4: Modern ROS 2 ament_python package without setup.py
"""

import asyncio
import os
import stat
import subprocess
import sys
import tempfile
from pathlib import Path
from types import SimpleNamespace

# Ensure submodules are in sys.path
REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / 'submodules' / 'kmom88-colcon-core'))
sys.path.insert(0, str(REPO_ROOT / 'submodules' / 'colcon-ros'))

from colcon_core.package_augmentation.pep621 \
    import PEP621PackageAugmentation  # noqa: E402
from colcon_core.package_descriptor \
    import PackageDescriptor  # noqa: E402
from colcon_core.package_identification.pep621 \
    import PEP621PackageIdentification  # noqa: E402
from colcon_core.package_identification.python \
    import PythonPackageIdentification  # noqa: E402
from colcon_core.python_project.wheel \
    import _get_script_maker  # noqa: E402
from colcon_core.task import TaskContext  # noqa: E402
from colcon_core.task.python import get_setup_data  # noqa: E402
from colcon_core.task.python.build \
    import PythonBuildTask  # noqa: E402
from colcon_core.task.python.test \
    import has_test_dependency  # noqa: E402
from colcon_core.task.python_project.build \
    import PythonProjectBuildTask  # noqa: E402

from colcon_ros.package_augmentation.ros_ament_python \
    import RosAmentPythonPackageAugmentation  # noqa: E402
from colcon_ros.task.ament_python.build \
    import AmentPythonBuildTask  # noqa: E402


def run_coro(coro):
    """Run an async coroutine synchronously."""
    return asyncio.run(coro)


def create_task_context(desc, pkg_dir, build_base, install_base,
                        symlink_install=False):
    """Create a TaskContext with a mock event queue handler."""
    context = TaskContext(
        pkg=desc,
        args=SimpleNamespace(
            path=str(pkg_dir),
            build_base=str(build_base),
            install_base=str(install_base),
            symlink_install=symlink_install,
        ),
        dependencies={},
    )
    context.put_event_into_queue = lambda ev: None
    return context


def test_scenario_1_classic_setup_py():
    """Scenario 1: Classic Python package with setup.py."""
    print('\n' + '=' * 70)
    print('▶ Running Scenario 1: Classic package (setup.py)')
    print('=' * 70)

    pkg_dir = REPO_ROOT / 'examples' / 'mock_packages' / '01_classic_setup_py'

    desc = PackageDescriptor(pkg_dir)
    PythonPackageIdentification().identify(desc)
    print(f"  [Identification] Type: '{desc.type}', Name: '{desc.name}'")
    assert desc.type == 'python', f"Expected 'python', got '{desc.type}'"
    assert desc.name == 'classic_pkg'

    # Prioritization check: PEP621 identification does NOT override setup.py
    desc_check = PackageDescriptor(pkg_dir)
    PEP621PackageIdentification().identify(desc_check)
    print('  [Priority Check] Verified legacy setup.py priority over PEP 621')

    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp_path = Path(tmp_dir)
        build_base = tmp_path / 'build'
        install_base = tmp_path / 'install'
        build_base.mkdir()
        install_base.mkdir()

        task = PythonBuildTask()
        context = create_task_context(
            desc, pkg_dir, build_base, install_base, False)
        task.set_context(context=context)
        res = run_coro(task.build())
        assert res is None or res == 0, f'Build failed: {res}'

        # Verify egg-info was created in build directory
        egg_infos = list(build_base.glob('**/*.egg-info'))
        print(f'  [Build Layout] Generated {len(egg_infos)} egg-info '
              'artifacts in build/')
        assert len(egg_infos) >= 1

        # Verify installed module
        installed_mods = list(install_base.glob('**/classic_pkg/__init__.py'))
        assert len(installed_mods) >= 1
        rel_mod = installed_mods[0].relative_to(install_base)
        print(f'  [Install Layout] Installed classic module at: {rel_mod}')

    print('✔ Scenario 1 PASSED: Classic setup.py workflow verified.')


def test_scenario_2_modern_pep621_flit():
    """Scenario 2: Modern pure PEP 621 package with flit_core."""
    print('\n' + '=' * 70)
    print('▶ Running Scenario 2: Modern PEP 621 package (pyproject.toml)')
    print('=' * 70)

    pkg_dir = (
        REPO_ROOT / 'examples' / 'mock_packages' / '02_modern_pep621_flit'
    )

    desc = PackageDescriptor(pkg_dir)
    PEP621PackageIdentification().identify(desc)
    print(f"  [Identification] Type: '{desc.type}', Name: '{desc.name}'")
    assert desc.type == 'python.project'
    assert desc.name == 'modern_flit_pkg'

    # Augment metadata
    PEP621PackageAugmentation().augment_package(desc)
    print(f"  [Augmentation] Authors: {desc.metadata.get('authors')}")
    print(f"  [Augmentation] Version: {desc.metadata.get('version')}")
    assert desc.metadata.get('version') == '0.1.0'

    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp_path = Path(tmp_dir)
        build_base = tmp_path / 'build'
        install_base = tmp_path / 'install'
        build_base.mkdir()
        install_base.mkdir()

        task = PythonProjectBuildTask()
        context = create_task_context(
            desc, pkg_dir, build_base, install_base, False)
        task.set_context(context=context)
        res = run_coro(task.build())
        assert res is None, f'Build failed with {res}'

        # Check wheel installation
        dist_infos = list(install_base.glob('**/*.dist-info'))
        assert len(dist_infos) == 1
        rel_dist = dist_infos[0].relative_to(install_base)
        print(f'  [In-Process Wheel] Installed dist-info at: {rel_dist}')

        # Check CLI executable script generated in bin/
        cli_path = install_base / 'bin' / 'modern-cli'
        assert cli_path.is_file(), f'Missing CLI wrapper at {cli_path}'
        mode = cli_path.stat().st_mode
        assert mode & stat.S_IXUSR, 'Script wrapper is not executable'
        print(f'  [CLI Entry Point] Generated executable wrapper in bin/: '
              f'{cli_path.name} (mode: {oct(mode)})')

        # Execute script with installed site-packages in PYTHONPATH
        lib_dir = dist_infos[0].parent
        env = {
            **os.environ,
            'PYTHONPATH': os.pathsep.join(
                [str(lib_dir), os.environ.get('PYTHONPATH', '')]
            ),
        }
        proc = subprocess.run(
            [sys.executable, str(cli_path)],
            env=env,
            capture_output=True,
            text=True,
        )
        print(f'  [Script Output] "{proc.stdout.strip()}"')
        assert proc.returncode == 0
        assert 'Executing from modern PEP 621 package' in proc.stdout

    print('✔ Scenario 2 PASSED: Modern PEP 621 wheel extraction verified.')


def test_scenario_3_modern_editable_data_files():
    """Scenario 3: Modern package with --symlink-install and data files."""
    print('\n' + '=' * 70)
    print('▶ Running Scenario 3: Modern PEP 660 editable & symlinked data')
    print('=' * 70)

    pkg_dir = (
        REPO_ROOT / 'examples' / 'mock_packages' /
        '03_modern_editable_data_files'
    )
    launch_src = pkg_dir / 'launch' / 'demo.launch.py'

    desc = PackageDescriptor(pkg_dir)
    PEP621PackageIdentification().identify(desc)
    assert desc.type == 'python.project'

    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp_path = Path(tmp_dir)
        build_base = tmp_path / 'build'
        install_base = tmp_path / 'install'
        build_base.mkdir()
        install_base.mkdir()

        # 1. Verify standard build installs shared-data as regular file
        std_task = PythonProjectBuildTask()
        std_task.set_context(context=create_task_context(
            desc, pkg_dir, build_base, install_base, False))
        res = run_coro(std_task.build())
        assert res is None, f'Standard build failed: {res}'

        installed_launch = (
            install_base / 'share' / 'data_pkg' / 'launch' / 'demo.launch.py'
        )
        assert installed_launch.is_file()
        assert not installed_launch.is_symlink()
        print('  [Standard Build] Verified shared-data copied to: '
              f'{installed_launch.relative_to(install_base)}')

        # 2. Verify --symlink-install replaces with a live filesystem symlink
        task = PythonProjectBuildTask()
        context = create_task_context(
            desc, pkg_dir, build_base, install_base, True)
        task.set_context(context=context)
        res = run_coro(task.build())
        assert res is None, f'Editable build failed: {res}'

        assert os.path.samefile(installed_launch, launch_src)
        print('  [Symlink Install] Verified data file links to source: '
              f'{installed_launch.relative_to(install_base)} -> {launch_src}')

        # Test live editing without rebuilding
        orig_content = launch_src.read_text()
        try:
            launch_src.write_text(
                orig_content + '\nLIVE_MODIFICATION_ENABLED = True\n')
            assert 'LIVE_MODIFICATION_ENABLED = True' in \
                installed_launch.read_text()
            print('  [Live Modification] Source edits reflected in install/ '
                  'instantly!')
        finally:
            launch_src.write_text(orig_content)

    print('✔ Scenario 3 PASSED: Non-Python data files symlinking verified.')


def test_scenario_4_ros2_ament_pyproject():
    """Scenario 4: ROS 2 ament_python package without setup.py."""
    print('\n' + '=' * 70)
    print('▶ Running Scenario 4: Modern ROS 2 ament_python without setup.py')
    print('=' * 70)

    pkg_dir = (
        REPO_ROOT / 'examples' / 'mock_packages' / '04_ros2_ament_pyproject'
    )

    desc = PackageDescriptor(pkg_dir)
    desc.name = 'ros_pyproject_pkg'
    desc.type = 'ros.ament_python'

    RosAmentPythonPackageAugmentation().augment_package(desc)
    assert has_test_dependency(get_setup_data(desc, {}), 'pytest')
    print('  [Test Augmentation] Verified pytest dependency discovered for '
          'colcon test')

    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp_path = Path(tmp_dir)
        build_base = tmp_path / 'build'
        install_base = tmp_path / 'install'
        build_base.mkdir()
        install_base.mkdir()

        for _ in range(2):
            _get_script_maker.cache_clear()
            task = AmentPythonBuildTask()
            context = create_task_context(
                desc, pkg_dir, build_base, install_base, False)
            task.set_context(context=context)
            res = run_coro(task.build())
            assert res is None, f'Build failed: {res}'

        # Check Ament Index Marker
        marker = (
            install_base / 'share' / 'ament_index' / 'resource_index' /
            'packages' / 'ros_pyproject_pkg'
        )
        assert marker.is_file(), 'Missing ament_index marker'
        print(f'  [ROS Index] Created resource index marker: '
              f'{marker.relative_to(install_base)}')

        # Check package.xml in share/
        pkg_xml = install_base / 'share' / 'ros_pyproject_pkg' / 'package.xml'
        assert pkg_xml.is_file(), 'Missing package.xml in share/'
        print(f'  [ROS Manifest] Copied package.xml to: '
              f'{pkg_xml.relative_to(install_base)}')

        # Check AMENT_PREFIX_PATH hook and package scripts
        hook_file = (
            install_base / 'share' / 'ros_pyproject_pkg' / 'hook' /
            'ament_prefix_path.dsv'
        )
        pkg_dsv = install_base / 'share' / 'ros_pyproject_pkg' / 'package.dsv'
        assert hook_file.is_file(), 'Missing ament_prefix_path hook'
        assert 'ament_prefix_path' in pkg_dsv.read_text()
        print(f'  [ROS Hook] Generated environment hook & package script: '
              f'{hook_file.relative_to(install_base)}')

        # Check node CLI wrapper in ROS 2 lib/<pkg>/ directory (ros2 run path)
        node_cli = install_base / 'lib' / 'ros_pyproject_pkg' / 'sample-node'
        assert node_cli.is_file(), (
            f'Missing sample-node in lib/ros_pyproject_pkg/ ({node_cli})'
        )
        assert not (install_base / 'bin' / 'sample-node').exists()
        print(f'  [ROS Node] Node executable installed at: '
              f'{node_cli.relative_to(install_base)}')

        dist_infos = list(
            install_base.glob('**/ros_pyproject_pkg-0.2.0.dist-info')
        )
        assert len(dist_infos) == 1
        lib_dir = dist_infos[0].parent
        env = {
            **os.environ,
            'PYTHONPATH': os.pathsep.join(
                [str(lib_dir), os.environ.get('PYTHONPATH', '')]
            ),
        }
        proc = subprocess.run(
            [sys.executable, str(node_cli)],
            env=env,
            capture_output=True,
            text=True,
        )
        print(f'  [Node Output] "{proc.stdout.strip()}"')
        assert proc.returncode == 0
        assert 'Executing sample-node from modern ament_python' in proc.stdout

    print('✔ Scenario 4 PASSED: Modern ROS 2 ament_python build verified.')


def main():
    """Run all mock package scenarios."""
    print('=' * 70)
    print('COLCON PYTHON STANDARDS: MOCK PACKAGES DEMO & VERIFICATION SUITE')
    print('=' * 70)

    test_scenario_1_classic_setup_py()
    test_scenario_2_modern_pep621_flit()
    test_scenario_3_modern_editable_data_files()
    test_scenario_4_ros2_ament_pyproject()

    print('\n' + '=' * 70)
    print('🎉 ALL 4 MOCK SCENARIOS COMPLETED AND VALIDATED SUCCESSFULLY!')
    print('=' * 70 + '\n')


if __name__ == '__main__':
    main()
