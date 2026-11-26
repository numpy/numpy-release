set -xe

PROJECT_DIR="${1:-$PWD}"
NUMPY_SRC_DIR="${1:-$PWD}/numpy-src"

# install test dependencies via uv
# the lock file lives in this repo, not in the numpy checkout
PYTHON_EXE="$(python -c 'import sys; print(sys.executable)')"
PLATFORM=$(python -c "import sys;print(sys.platform)")

if [[ "$PLATFORM" = "emscripten" ]] ; then
  TEST_GRP="--only-group test-core"
  # no hypothesis wheels for pyemscripten_2026_5 (cp315-pyodide_wasm32) yet
  if [[ "$(python -c 'import sys; print(sys.version_info[:2] == (3, 14))')" = "True" ]] ; then
    TEST_GRP="$TEST_GRP --only-group hypothesis"
  fi
else
  TEST_GRP="--only-group test"
fi

uv export --project "$PROJECT_DIR" $TEST_GRP --frozen | \
    uv pip install --python "$PYTHON_EXE" --no-deps --require-hashes -r -
