complete -c objfw-config -l all -d 'Outputs all flags + libs'
complete -c objfw-config -l arc -d 'Outputs the required OBJCFLAGS to use ARC'
complete -c objfw-config -l cflags -d 'Outputs the required CFLAGS'
complete -c objfw-config -l cppflags -d 'Outputs the required CPPFLAGS'
complete -c objfw-config -l cxxflags -d 'Outputs the required CXXFLAGS'
complete -c objfw-config -l framework-libs \
    -d 'Outputs the required LIBS, preferring frameworks'
complete -c objfw-config -l help -d 'Print help'
complete -c objfw-config -l ldflags -d 'Outputs the required LDFLAGS'
complete -c objfw-config -l libs -d 'Outputs the required LIBS'
complete -c objfw-config -l lib-cflags \
    -d 'Outputs CFLAGS for building a library'
complete -c objfw-config -l lib-ldflags \
    -d 'Outputs LDFLAGS for building a library'
complete -c objfw-config -l lib-prefix -d 'Outputs the prefix for libraries'
complete -c objfw-config -l lib-suffix -d 'Outputs the suffix for libraries'
complete -c objfw-config -l objc -d 'Outputs the OBJC used to compile ObjFW'
complete -c objfw-config -l objcflags -d 'Outputs the required OBJCFLAGS'
complete -c objfw-config -l package -x \
    -d 'Additionally outputs the flags for the specified package'
complete -c objfw-config -l packages-dir \
    -d 'Outputs the directory where flags for packages are stored'
complete -c objfw-config -l plugin-cflags \
    -d 'Outputs CFLAGS for building a plugin'
complete -c objfw-config -l plugin-ldflags \
    -d 'Outputs LDFLAGS for building a plugin'
complete -c objfw-config -l plugin-suffix -d 'Outputs the suffix for plugins'
complete -c objfw-config -l prog-suffix -d 'Outputs the suffix for binaries'
complete -c objfw-config -l reexport -d 'Outputs LDFLAGS to reexport ObjFW'
complete -c objfw-config -l rpath -d 'Outputs LDFLAGS for using rpath'
complete -c objfw-config -l static-libs \
    -d 'Outputs the required LIBS to link ObjFW statically'
complete -c objfw-config -l version -d 'Outputs the installed version'
