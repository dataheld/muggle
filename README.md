# muggle

devops package

## Installation

```sh
cp -f muggle/post-checkout.sample .git/modules/muggle/hooks/post-checkout
chmod +x .git/modules/muggle/hooks/post-checkout
cp -f muggle/post-checkout.sample .git/modules/muggle/hooks/post-merge
chmod +x .git/modules/muggle/hooks/post-merge
cp -f muggle/post-checkout.sample .git/modules/muggle/hooks/post-rewrite
chmod +x .git/modules/muggle/hooks/post-rewrite
sh muggle/install.sh
```
