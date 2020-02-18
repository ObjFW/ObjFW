complete -c ofhttp -s b -l body -r -d 'Specify the file to send as body'
complete -c ofhttp -s c -l continue -d 'Continue download of existing file'
complete -c ofhttp -s f -l force -d 'Force / overwrite existing file'
complete -c ofhttp -s h -l help -d 'Show help'
complete -c ofhttp -s H -l header -x -d 'Add a header (e.g. X-Foo:Bar)'
complete -c ofhttp -s m -l method -x -d 'Set the method of the HTTP request'
complete -c ofhttp -s o -l output -r -d 'Specify output file name'
complete -c ofhttp -s O -l detect-filename \
    -d 'Do a HEAD request to detect the file name'
complete -c ofhttp -s P -l proxy -x -d 'Specify SOCKS5 proxy'
complete -c ofhttp -s q -l quiet -d 'Quiet mode (no output, except errors)'
complete -c ofhttp -s v -l verbose -d 'Verbose mode (print headers)'
complete -c ofhttp -l insecure \
    -d 'Ignore TLS errors and allow insecure redirects'
