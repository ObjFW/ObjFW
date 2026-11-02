ObjFW
=====


What is ObjFW?
--------------

ObjFW is a portable, lightweight framework for the Objective-C language. It
enables you to write an application in Objective-C that will run on any
[platform supported](documentation/platforms.md) by ObjFW without having to
worry about differences between operating systems or various frameworks you
would otherwise need if you want to be portable.

It supports all modern Objective-C features when using Clang, but is also
compatible with GCC ≥ 4.6 to allow maximum portability.

ObjFW is intentionally incompatible with Foundation. This has two reasons:

* GNUstep already provides a reimplementation of Foundation, which is only
  compatible to a certain degree. This means that a developer still needs to
  care about differences between frameworks if they want to be portable. The
  idea behind ObjFW is that developers do not need to concern themselves with
  portability and making sure their code works with multiple frameworks:
  Instead, if it works with ObjFW on one platform, they can reasonably expect it
  to also work with ObjFW on another platform. ObjFW behaving differently on
  different operating systems (unless inevitable because it is a
  platform-specific part, like the Windows Registry) is considered a bug and
  will be fixed.
* Foundation predates a lot of modern Objective-C concepts. The most prominent
  one is exceptions, which are only used in Foundation as a replacement for
  `abort()`. This results in cumbersome error handling, especially in
  initializers, which in Foundation only return `nil` on error with no
  indication of what went wrong. It also means that the return of every `init`
  call needs to be checked against `nil`. But in the wild, nobody actually
  checks *each* and *every* return from `init` against `nil`, leading to bugs.
  ObjFW fixes this by making exceptions a first class citizen.

You can read more about the differences to Foundation
[here](documentation/differences-to-foundation.md).

ObjFW also comes with its own lightweight and extremely fast Objective-C
runtime, which in real world use cases was found to be significantly faster
than both GNU’s and Apple’s runtime.


Installation
------------

You can find instructions to install ObjFW on various operating systems
[here](documentation/installation.md) or instructions for compiling ObjFW from
source [here](documentation/compiling.md).


Usage
-----

To create your first, empty application, you can use `objfw-new`:

    objfw-new --app MyFirstApp

This creates a file `MyFirstApp.m`. The `-[applicationDidFinishLaunching:]`
method is called as soon as ObjFW finished all initialization. Use this as the
entry point to your own code. For example, you could add the following line
there to create a “Hello World”:

    [OFStdOut writeLine: @"Hello World!"];

You can compile your new app using `objfw-compile`:

    objfw-compile -o MyFirstApp MyFirstApp.m

`objfw-compile` is a tool that allows building applications and libraries using
ObjFW without needing a full-blown build system. If you want to use your own
build system, you can get the necessary flags from `objfw-config`.


Documentation
-------------

You can find documentation for the latest released version of ObjFW
[here](https://objfw.nil.im/docs/).

In order to build the documentation yourself (necessary to have documentation
for the `main` branch), you need to have [Doxygen](https://www.doxygen.nl)
installed. Once installed, you can build the documentation from the root
directory of the repository:

    make docs


License
-------

ObjFW is released under the GNU Lesser General Public License version 3.0.

If this license does not work for you, contact me and we can find a solution.


Bugs and feature requests
-------------------------

You can find the bug tracker [here](https://git.nil.im/ObjFW/ObjFW/issues) or
file a new bug [here](https://git.nil.im/ObjFW/ObjFW/issues/new/choose). You
can also [send an e-mail](mailto:js@nil.im).


Support and community
---------------------

If you have any questions about ObjFW or would like to talk to other ObjFW
users, the following venues are available:

* [Discussions repository](https://git.nil.im/ObjFW/discussions) in which
  you can open an issue to start a discussion topic
* [Matrix room](https://matrix.to/#/%23objfw:nil.im)
* [Discord room](https://objfw.nil.im/discord), bridged to the Matrix room above
* [Signal room](https://objfw.nil.im/signal), bridged to the Matrix room above
* [Telegram room](https://t.me/objfw), bridged to the Matrix room above
* [Slack room](https://objfw.nil.im/slack), bridged to the Matrix room above
* IRC channel [#objfw](ircs://irc.libera.chat/#objfw) on `irc.libera.chat`,
  bridged to the Matrix room above

Please don’t hesitate to join any or all of those!


Donating
--------

You can find a list of all possible ways to donate
[here](documentation/donating.md).


Thanks
------

* [Jonathan Neuschäfer](https://github.com/neuschaefer) for reviewing the
  *entirety* (all 84k LoC at the time) of ObjFW’s codebase in 2017!
* [Hill Ma](https://github.com/mahiuchun) for donating an M1 Mac Mini to the
  project in 2022!
