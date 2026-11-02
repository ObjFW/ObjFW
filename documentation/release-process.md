Release process
===============

* Update `changes.md` and cherry-pick the change into main
* **Make sure the library version has been increased for all libraries that had
  changes / bug fixes! Don‘t forget to increase the minor for every library
  that had new features added and the patch level for every library that had
  bug fixes!**
* Change the version in `AC_INIT` and the `BUNDLE_VERSION` in `configure.ac`
  and commit. This commit should have the `${version}-release` tag!
* Push the commits but not the tag
* Run `git checkout ${version}-release` and run `git clean -fxd`, then
  `./autogen.sh && ./configure`. Don‘t forget this, or the version might be
  wrong!
* Generate and sign tarballs using `make release`
* Extract `objfw-${version}.tar.gz` and `objfw-docs-${version}.tar.gz` as well
  as `objfw-${previousVersion}.tar.gz` and
  `objfw-docs-${previousVersion}.tar.gz`. Then diff the current against the
  previous version and check nothing unexpected is in there.
* If everything looks okay, push the tag
* Upload the tarballs and their signatures
* Extract the new documentation and put it [here](https://objfw.nil.im/docs/)
* Create a [new release](https://git.nil.im/ObjFW/ObjFW/releases/new)
* Announce the new release on the [Fediverse](https://ap.nil.im/objfw)
* Announce the new release in the Matrix room and change the topic to
include the new release


Updating Distributions
======================

[![Packaging status](https://repology.org/badge/vertical-allrepos/objfw.svg)](https://repology.org/project/objfw/versions)


pkgsrc
------

In `devel/objfw`:

* Edit `Makefile` to increase the version
* Run `make makesum` to update `distinfo`. Check it is correct.
* Run `make package`
* Run `make print-PLIST >PLIST` to update the `PLIST`. Look at the diff and fix
  any custom `PLIST` entries that this reverted. Pay attention to what is
  already in the other `PLIST.*` files!
* Commit (include the change log in the commit message) and run `make cce`


Fedora
------

* Make sure to be on rawhide and run `git pull`
* Increase the version in `objfw.spec` and `git add` it
* Download the tarball and signature via `spectool -g objfw.spec`
* `fedpkg upload` both `objfw-${version}.tar.gz` and
  `objfw-${version}.tar.gz.sig`
* Remove the old version from `sources` and `.gitignore`, then `git add` both
* `git commit -m "Update to ${version}"`
* `for i in f43 f44 epel8 epel9 epel10 epel10.2; do git checkout $i && git
  merge rawhide; done`
* `git push --all`
* `for i in f43 f44 epel8 epel9 epel10 epel10.2 rawhide; do git checkout $i && fedpkg build --nowait; done`
* Wait for the builds to be done, then create the updates on
  [Bodhi](https://bodhi.fedoraproject.org/). Set the Karma required to 1.


Fedora MinGW
------------

* Make sure to be on the `rawhide` branch and run `git pull`
* Increase the `version` in`mingw-objfw.spec` and `git add` it
* Download the tarball and signature via `spectool -g mingw-objfw.spec`
* `fedpkg upload` both `objfw-${version}.tar.gz` and
  `objfw-${version}.tar.gz.sig`
* Remove the old version from `sources` and `.gitignore`, then `git add` both
* `git commit -m "Update to ${version}"`
* `for i in f43 f44; do git checkout $i && git merge rawhide; done`
* `git push --all`
* `for i in f43 f44 rawhide; do git checkout $i && fedpkg build --nowait; done`
* Wait for the builds to be done, then create the updates on
  [Bodhi](https://bodhi.fedoraproject.org/). Set the Karma required to 1.


Debian
------

* Clone the [ObjFW Salsa project](https://salsa.debian.org/debian/objfw)
* Download the tarball and signature and verify it
* Run `gbp import-orig ../objfw-${version}.tar.gz`
* Run `gbp dch`, update the `changelog` as necessary
* Perform changes to `debian/*`, if necessary
* Commit
* Run `gbp buildpackage`
* Run `git tag debian/${version}-${debversion}`, e.g.  `git tag debian/1.1.5-1`
* Run `git push && git push --tags`
* Ping a Debian developer to upload the package


MSYS2
-----

* Edit the
  [`PKGBUILD`](https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-objfw/PKGBUILD)
  file to increase the version and update the hash
* Commit with the message “objfw: Update to ${version}” and create a draft pull
  request. This will trigger CI.
* Once CI passed, click on “Ready for review”


OpenIndiana
-----------

* Edit the
  [Makefile](https://github.com/OpenIndiana/oi-userland/blob/oi/hipster/components/library/objfw/Makefile)
  to increase the version and update the hash
* If a library minor increased, the `*.p5m files` need to be changed as well
* Run `gmake sample-manifest`, `gmake publish`, `gmake test` and
  `gmake REQUIRED_PACKAGES`
* Commit with the message “library/objfw: update to ${version}” and create a
  pull request


Alpine Linux
------------

* Edit the
  [APKBUILD](https://gitlab.alpinelinux.org/alpine/aports/-/blob/master/community/objfw/APKBUILD?ref_type=heads)
  to increase the version and update the file name and hash
* Commit with the message “community/objfw: upgrade to ${version}” and create a
  draft pull request. This will trigger CI.
* Once CI passed, click on “Mark as ready”
* Only for bug fix-only releases: Repeat the same for every stable branch, but
  prefix the PR subject (not the commit) with the branch, e.g. “[3.19]
  community/objfw: upgrade to 1.0.6”


Haiku
-----

In dev-libs/objfw:

* Rename the recipe file to the new version
* Update the hash
* Update the library versions as necessary
* Run `haikuporter --test objfw_x86` (for gcc2h) or `haikuporter --test objfw`
* Commit & push


OpenBSD
-------

In devel/objfw:

* Edit `Makefile` and increase the version and potentially library versions
* Run `make makesum`
* Run `make update-plist` to update the `PLIST`. Look at the diff and revert
  any unwanted diffs.
* Run `cvs diff` and send the output to
  [ports@openbsd.org](mailto:ports@openbsd.org)


FreeBSD
-------

In devel/objfw:

* Edit `Makefile` and increase the version
* Run `make makesum`
* Run `make makeplist >pkg-plist` and check and edit `pkg-plist`
* Run `make install`
* Create a patch and [create a bug](https://bugs.freebsd.org/bugzilla/) titled
  “devel/objfw: Update to ${version}”
* Attach the patch and change log to the bug
* Mention whether the update should be applied to the quarterly


ArchLinux
---------

* Edit `PKGBUILD` in AUR and increase the version and update the hash
* Run `makepkg`
* Run `makepkg --printsrcinfo >.SRCINFO`
* `git add PKGBUILD .SRCINFO`, then commit and push


MorphOS
-------

(Note: MorphOS CVS is not public. These steps can hence only be performed by
MorphOS team members with CVS access.)

In `morphoswb/libs/objfw`:

* Delete the old tarball and `cvs rm` it
* Copy the new tarball and `cvs add` it
* Edit `Makefile` and change the version
* If the next MorphOS version is an uneven version and the ObjFW release is a
  bug fix release, check out the branch (e.g. using
  `cvs up -r morphos_3_21_branch`) and repeat the above steps
