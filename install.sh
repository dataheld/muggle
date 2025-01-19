#!/bin/bash
echo "(Re-)Installing Muggle..."
# Change to the directory where the script resides
cd "$(dirname "$0")"

echo "(Over-)writing GitHub Actions workflow files ..."
cp -f gha/lint.yml ../.github/workflows/lint.yml

echo "(Re-)creating Symbolic Links ..."

./scripts/symlink_ignore.bash --source in_submodule.make --target Makefile
./scripts/symlink_ignore.bash \
  --source docker-compose.yml \
  --target docker-compose.yml
./scripts/symlink_ignore.bash \
  --source .markdownlint.yml \
  --target .markdownlint.yml
./scripts/symlink_ignore.bash \
  --source super-linter.env \
  --target super-linter.env

echo "Done."
