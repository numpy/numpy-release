# Contributing to the `numpy-release` repository

This repository has fairly strict contribution rules for security and
auditability reasons, as explained in the README. PRs with improvements or bug
fixes are very welcome, however CI jobs will not run for anyone who doesn't
have commit access.


## Updating the pinned dependencies

Every build and test dependency is pinned, with hashes, in `uv.lock`. The dependency
groups it pins live in the committed `pyproject.toml`, which is *generated* from the
`build`, `test`, `openblas32`, `openblas64`, `test-core`, `hypothesis` groups from
the `pyproject.toml` of`numpy/numpy`. It needs to be consistent with the `numpy/numpy`
commit this  branch builds (`SOURCE_REF_TO_BUILD` in`.github/workflows/wheels.yml`). The
build scripts install from the lock file with `uv export --require-hashes`.

Locking numpy's own `pyproject.toml` would work too, but it would pin all of its
dependency groups - `doc`, `dev`, `typecheck` and the rest - which is about 180 extra
packages that are never installed here, and a lock file six times the size.

Because `pyproject.toml` is a copy, it goes stale whenever numpy changes those three
groups. The `check_lock` CI job uses `tools/sync_dependency_groups.py` to
generate a `pyproject.toml` from `numpy/numpy`, diffs it against the committed one (in
this repository), and then runs `uv lock --check`, before any wheels are built.

To regenerate both `uv.lock` and `pyproject.toml`:

```bash
tools/update_lock.sh              # sync to numpy's dependency groups
tools/update_lock.sh --upgrade    # ... and also bump every pin to the latest release
```

This expects a `numpy/numpy` checkout at `../numpy`, at the commit named by
`SOURCE_REF_TO_BUILD`; set `$NUMPY_SRC` if yours lives somewhere else. Use a `uv` at
least as new as CI's `UV_VERSION` - older ones write a different lock file format.

Releases published within the last 7 days are ignored, so that a version published in the
last few days can't end up in a build. uv writes that window into the lock file and
`uv lock --check` only passes when given the *same* value, so it is hardcoded in two
places that have to agree: the `check_lock` job in `wheels.yml`, and
`tools/update_lock.sh`. Change one and CI will reject the lock file you generate.

## Reviewing a lock file change

Check `pyproject.toml` first: it determines everything else, and a change to it should
correspond to a change in numpy's dependency groups. `check_lock` proves that it does.

For `uv.lock` itself, worth checking on top of the version changes:

- That the diff contains no `source = { registry = ... }` pointing anywhere other than
  `https://pypi.org/simple`, and no `source = { url = ... }` or `{ git = ... }` entries.
- That `requires-python` and the `[options]` block at the top of the file are unchanged;
  a dropped `exclude-newer-span` means the cooldown was silently skipped.
- That the number of packages hasn't grown unexpectedly. The `check_lock` job writes the
  packages that get installed to its job summary on every run, so a PR touching the lock
  file can be reviewed by comparing its summary against the one from the most recent run
  on `main`. To produce that list locally:

  ```bash
  uv export --frozen --no-hashes --no-emit-project --no-default-groups \
      --group build --group openblas32 --group test-core --group test --group openblas64
  ```


## Running CI jobs on your own fork

To get CI to run on your own fork for changes in a branch named
`my-branch-name`, add a temporary commit to your branch that adds a trigger:

```diff
--- a/.github/workflows/wheels.yml
+++ b/.github/workflows/wheels.yml
@@ -22,6 +22,7 @@ on:
   push:
     branches:
       - main
+      - my-branch-name
   workflow_dispatch:
     inputs:
       environment:
```
If you title the commit, e.g., `DEBUG: run on fork`, it's easy to drop the
commit again once you're done testing and before opening a PR to the
`numpy/numpy-release` repository.

Note that this will run *a lot of jobs*. If you're doing iterative testing,
it's recommended to only select the platform(s) you're interested in like this:

```diff
--- a/.github/workflows/wheels.yml
+++ b/.github/workflows/wheels.yml
@@ -22,6 +22,7 @@ on:
   push:
     branches:
       - main
+      - my-branch-name
   workflow_dispatch:
     inputs:
       environment:
@@ -48,20 +49,8 @@ jobs:
         # Github Actions doesn't support pairing matrix values together, let's improvise
         # https://github.com/github/feedback/discussions/7835#discussioncomment-1769026
         buildplat:
-          - [ubuntu-22.04, manylinux_x86_64, ""]
-          - [ubuntu-22.04, musllinux_x86_64, ""]
-          - [ubuntu-22.04-arm, manylinux_aarch64, ""]
           - [ubuntu-22.04-arm, musllinux_aarch64, ""]
-          - [macos-13, macosx_x86_64, openblas]
-
-          # targeting macos >= 14. Could probably build on macos-14, but it would be a cross-compile
-          - [macos-13, macosx_x86_64, accelerate]
-          - [macos-15, macosx_arm64, openblas]
-          - [macos-15, macosx_arm64, accelerate]
-          - [windows-2022, win_amd64, ""]
-          - [windows-2022, win32, ""]
-          - [windows-11-arm, win_arm64, ""]
-        python: ["cp311", "cp312", "cp313", "cp313t", "cp314", "cp314t", "pp311"]
+        python: ["cp314", "cp314t"]
         exclude:
           # Don't build PyPy 32-bit windows
           - buildplat: [windows-2022, win32, ""]
```


## Commit messages and linear history

Please use the same [commit message format as for the main `numpy` repository](https://numpy.org/devdocs/dev/development_workflow.html#writing-the-commit-message).

This repository requires linear history. It's preferred that contributors edit
their commit history so the PRs they submit contain clean, independent commits.
Note that each commit should be able to pass CI - if one commit depends on
another, they should be merged. Maintainers may decide to squash-merge if those
requirements aren't met.
