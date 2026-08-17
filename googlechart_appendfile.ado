*! googlechart_appendfile v0.1.2  2026-08-16
*! v0.1.2 2026-08-16: normalize paths to backslashes for cmd.exe `type' on
*!   Windows so a forward-slash export() path appends correctly.
*! Close an open file handle, shell-append another file's contents
*! byte-for-byte, then reopen the same handle in append mode.
*!
*! Used by googlechart_writehtml to embed the JSON data payload and the
*! engine JS into the output HTML without going through Stata's `file
*! write' parser, which would otherwise mishandle the embedded `"'
*! sequences inside minified JS and long lines that exceed Stata's
*! macro-length limits.
*!
*! Forked from sparkta2_appendfile so the googlechart package has no
*! external dependency.  INTERNAL helper -- not meant to be called
*! directly by users.

program define googlechart_appendfile
    version 17.0
    syntax , FH(name) PATH(string) OUTPATH(string)

    file close `fh'

    local _os = lower("`c(os)'")
    if strpos("`_os'", "win") {
        * cmd.exe `type' is reliable only with backslash separators; a
        * forward-slash source path (e.g. an export() the user wrote with /)
        * can be misread.  Normalize both paths to backslashes for the shell.
        local path    : subinstr local path    "/" "\", all
        local outpath : subinstr local outpath "/" "\", all
        shell type "`path'" >> "`outpath'"
    }
    else {
        shell cat "`path'" >> "`outpath'"
    }

    file open `fh' using `"`outpath'"', write text append
end
