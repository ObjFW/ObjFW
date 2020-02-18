complete -c objfw-compile -s o -x -d 'Specify the output name (not file name!)'
complete -c objfw-compile -l arc -d 'Use automatic reference counting'
complete -c objfw-compile -l lib -x -d \
    'Compile a library (with the specified version) instead of an application'
complete -c objfw-compile -l plugin \
    -d 'Compile a plugin instead of an application'
complete -c objfw-compile -l package -x -d 'Use the specified package'
complete -c objfw-compile -l builddir -r \
    -d 'Place built objects into the specified directory'
complete -c objfw-compile -s D -x -d 'Pass the specified define to the compiler'
complete -c objfw-compile -o framework -x \
    -d 'Pass the specified -framework argument to the linker (macOS / iOS only)'
# -f* cannot be represented.
complete -c objfw-compile -s F -x \
    -d 'Pass the specified -F flag to the linker (macOS / iOS only)'
# -g* cannot be represented.
complete -c objfw-compile -s I -x \
    -d 'Pass the specified -I flag to the compiler'
complete -c objfw-compile -s l -x -d 'Pass the specified -l flag to the linker'
complete -c objfw-compile -s L -x -d 'Pass the specified -L flag to the linker'
# -m* cannot be represented.
# -O* cannot be represented.
complete -c objfw-compile -o pthread \
    -d 'Pass -pthread to the compiler and linker'
# -std=* cannot be represented.
# -Wl,* cannot be represented.
# -W* cannot be represented.
complete -c objfw-compile -l help -d 'Show this help'
