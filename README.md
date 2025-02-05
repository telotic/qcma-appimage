# QCMA AppImage

## Summary

Building an AppImage for [qcma](https://github.com/codestation/qcma).

There are 2 ways effectively doing the same thing. Either via a Dockerfile to build it
locally on a Debian:10 distro, or using GitHub Actions on a Ubuntu 20.04 distro.

The goal is to resolve the problem of broken dependencies when running QCMA on recent
Linux distros. The QCMA package I installed from AUR now has some connection problems
to my PS Vita, likely due to changes in libxml2, while the Windows program still works,
thanks to all the old dlls packaged with the executable. This made me think that we
should do something similar for Linux by creating an AppImage.

This was heavily inspired by the following projects and works:

* https://github.com/codestation/vitamtp
* https://github.com/codestation/qcma
* Original build scripts from https://github.com/codestation/qcma-build/
* AUR PKGBUILD files for `libvitamtp` and `qcma`:
   * https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=libvitamtp
   * https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=qcma

## To build

```
docker build --output=. .
```

Or wait for the GitHub Action to finish and download the artifacts.