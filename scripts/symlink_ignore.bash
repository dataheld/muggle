#!/bin/bash

# Reset in case getopts has been used previously in the shell.
OPTIND=1
# Initialize variables
source=""
target=""

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        --source)
            source="$2"
            shift # past argument
            shift # past value
            ;;
        --target)
            target="$2"
            shift # past argument
            shift # past value
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if required arguments were provided
if [ -z "$source" ] || [ -z "$target" ]; then
    echo "Usage: $0 --source <source> --target <target>"
    exit 1
fi

original_dir=$(pwd)
cd ..

ln -f -s "muggle/$source" "$target"
git check-ignore --quiet "$target" || \
  echo $'# Muggle symlink\n'"$target" >> \
  .gitignore

cd "$original_dir" || exit
