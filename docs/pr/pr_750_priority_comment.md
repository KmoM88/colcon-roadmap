### Follow-up Note: `PEP621PackageIdentification.PRIORITY` Collision with `colcon-python-setup-py`

While auditing cross-extension interactions across hybrid workspaces, I noticed a minor priority tie in `colcon_core/package_identification/pep621.py`:

```python
    # the priority needs to be lower than the extensions identifying packages
    # using setup.py and/or setup.cfg files.
    PRIORITY = 90
```

* `colcon_core`'s `PythonPackageIdentification` (`setup.cfg`) uses the default `PRIORITY = 100`.
* However, `colcon_python_setup_py`'s `PythonPackageIdentification` (`setup.py`) explicitly sets `PRIORITY = 90` (`colcon_python_setup_py/package_identification/python_setup_py.py:32`).

For hybrid packages containing both a legacy `setup.py` and a `pyproject.toml` `[project]` table, having both extensions at `PRIORITY = 90` makes package type selection (`python` vs. `python.project`) dependent on entry-point iteration order (`pep621` vs. `python_setup_py`).

To strictly honor the inline comment and preserve deterministic backward compatibility for existing `setup.py` packages, lowering `PEP621PackageIdentification.PRIORITY` to **`80`** (or `85`) eliminates the tie while still matching pure `pyproject.toml` packages cleanly.

Happy to include that 1-line adjustment in this PR or leave it for `cottsay/pep621` directly—whichever is preferred!
