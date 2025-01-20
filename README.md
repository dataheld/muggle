# muggle

devops package

## Installation

Run this once to set up the git hooks.

```sh
cp -f muggle/update_hook.sample .git/modules/muggle/hooks/post-checkout
chmod +x .git/modules/muggle/hooks/post-checkout
cp -f muggle/update_hook.sample .git/modules/muggle/hooks/post-merge
chmod +x .git/modules/muggle/hooks/post-merge
cp -f muggle/update_hook.sample .git/modules/muggle/hooks/post-rewrite
chmod +x .git/modules/muggle/hooks/post-rewrite
sh muggle/install.sh
```

After this, muggle is installed.
All future necessary updates will happen automatically,
whenever you update the muggle submodule.

You can also always rerun the `muggle/install.sh` script;
it is idempotent.
