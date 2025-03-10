#!/bin/bash

# Skip this script if running in CI
if [ -n "$CI" ]; then
  exit 0
fi

# Check if pre-commit is already installed
if command -v pre-commit >/dev/null 2>&1; then
  echo "pre-commit is already installed."
  exit 0
fi

echo "Pre-commit (https://pre-commit.com) is required in wobo-okr."

# Check if the OS is macOS
if [[ "$(uname)" == "Darwin" ]]; then
  # Check if Homebrew is installed
  if command -v brew >/dev/null 2>&1; then
    echo "Homebrew is installed. Installing pre-commit..."
    brew install pre-commit
  else
    echo "Homebrew is not installed. Please install Homebrew first."
    echo "Visit https://brew.sh/ for installation instructions."
  fi
else
  echo "This script is intended for macOS with Homebrew installed."
  echo "For other systems, please refer to the pre-commit installation documentation:"
  echo "https://pre-commit.com/#install"
fi
