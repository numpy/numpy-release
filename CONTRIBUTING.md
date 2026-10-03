# Contributing to the `numpy-release` repository

This repository has fairly strict contribution rules for security and
auditability reasons, as explained in the README. PRs with improvements or bug
fixes are very welcome, however CI jobs will not run for anyone who doesn't
have commit access.


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
