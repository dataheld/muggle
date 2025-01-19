#!/bin/sh
echo "(Re-)Installing Muggle..."
echo "(Re-)creating Symbolic Links ..."
ln -s in_submodule.make ../Makefile
git check-ignore Makefile
