## git2r, R bindings to the libgit2 library.
## Copyright (C) 2013-2016 The git2r contributors
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License, version 2,
## as published by the Free Software Foundation.
##
## git2r is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License along
## with this program; if not, write to the Free Software Foundation, Inc.,
## 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

##' Generate object files in path
##'
##' @param path The path to directory to generate object files from
##' @param exclude Files to exclude
##' @return Character vector with object files
o_files <- function(path, exclude = NULL) {
    files <- sub("c$", "o",
                 sub("src/", "",
                     list.files(path, pattern = "[.]c$", full.names = TRUE)))

    if (!is.null(exclude))
        files <- files[!(files %in% exclude)]
    files
}

##' Generate build objects
##'
##' @param files The object files
##' @param substitution Any substitutions to apply in OBJECTS
##' @param Makevars The Makevars file
##' @return invisible NULL
build_objects <- function(files, substitution, Makevars) {
    lapply(names(files), function(obj) {
        cat("OBJECTS.", obj, " =", sep="", file = Makevars)
        len <- length(files[[obj]])
        for (i in seq_len(len)) {
            prefix <- ifelse(all(i > 1, (i %% 3) == 1), "    ", " ")
            postfix <- ifelse(all(i > 1, i < len, (i %% 3) == 0), " \\\n", "")
            cat(prefix, files[[obj]][i], postfix, sep="", file = Makevars)
        }
        cat("\n\n", file = Makevars)
    })

    cat("OBJECTS =", file = Makevars)
    len <- length(names(files))
    for (i in seq_len(len)) {
        prefix <- ifelse(all(i > 1, (i %% 3) == 1), "    ", " ")
        postfix <- ifelse(all(i > 1, i < len, (i %% 3) == 0), " \\\n", "")
        cat(prefix, "$(OBJECTS.", names(files)[i], ")", postfix, sep="", file = Makevars)
    }

    if (!is.null(substitution))
        cat(substitution, file = Makevars)
    cat("\n", file = Makevars)

    invisible(NULL)
}

##' Build Makevars.in
##'
##' @return invisible NULL
build_Makevars.in <- function() {
    Makevars <- file("src/Makevars.in", "w")
    on.exit(close(Makevars))

    files <- list(libgit2 = o_files("src/libgit2/src"),
                  libgit2.transports =
                      o_files("src/libgit2/src/transports",
                              c("libgit2/src/transports/auth_negotiate.o",
                                "libgit2/src/transports/winhttp.o")),
                  libgit2.unix = o_files("src/libgit2/src/unix"),
                  libgit2.xdiff = o_files("src/libgit2/src/xdiff"),
                  http_parser = o_files("src/libgit2/deps/http-parser"),
                  root = o_files("src"))

    cat("# Generated by scripts/build_Makevars.r: do not edit by hand\n\n",
        file=Makevars)
    cat("PKG_CFLAGS = @PKG_CFLAGS@\n", file = Makevars)
    cat("PKG_CPPFLAGS = @PKG_CPPFLAGS@\n", file = Makevars)
    cat("PKG_LIBS = @PKG_LIBS@\n", file = Makevars)
    cat("\n", file = Makevars)

    build_objects(files, " @GIT2R_SRC_REGEX@", Makevars)

    invisible(NULL)
}

##' Build Makevars.win
##'
##' @return invisible NULL
build_Makevars.win <- function() {
    Makevars <- file("src/Makevars.win", "w")
    on.exit(close(Makevars))

    files <- list(libgit2 = o_files("src/libgit2/src"),
                  libgit2.hash =
                      o_files("src/libgit2/src/hash",
                              "libgit2/src/hash/hash_win32.o"),
                  libgit2.transports =
                      o_files("src/libgit2/src/transports",
                              c("libgit2/src/transports/auth_negotiate.o",
                                "libgit2/src/transports/http.o")),
                  libgit2.xdiff = o_files("src/libgit2/src/xdiff"),
                  libgit2.win32 = o_files("src/libgit2/src/win32"),
                  http_parser = o_files("src/libgit2/deps/http-parser"),
                  regex =
                      o_files("src/libgit2/deps/regex",
                              c("libgit2/deps/regex/regcomp.o",
                                "libgit2/deps/regex/regexec.o",
                                "libgit2/deps/regex/regex_internal.o")),
                  root = o_files("src"))

    cat("# Generated by scripts/build_Makevars.r: do not edit by hand\n", file=Makevars)
    cat("\n", file = Makevars)

    cat("# Use -lRzlib if R <= 3.1.2 else -lz\n", file = Makevars)
    cat("Z_LIB = $(shell \"${R_HOME}/bin${R_ARCH_BIN}/Rscript\" -e \\\n", file = Makevars)
    cat("    \"cat(ifelse(compareVersion(sprintf('%s.%s', R.version['major'], R.version['minor']), '3.1.2') > 0, '-lz', '-lRzlib'))\")\n",
        file = Makevars)
    cat("\n", file = Makevars)

    cat("# Check for zlib headers and libraries\n", file = Makevars)
    cat("ifeq ($(Z_LIB),-lz)\n", file = Makevars)
    cat("GIT2R_LOCAL_SOFT=$(shell \"${R_HOME}/bin/R\" CMD config LOCAL_SOFT)\n", file = Makevars)
    cat("ifeq ($(wildcard \"${GIT2R_LOCAL_SOFT}/include/zlib.h\"),)\n", file = Makevars)
    cat("ifneq ($(wildcard zlib/include/zlib.h),)\n", file = Makevars)
    cat("GIT2R_ZLIB_LIB = -Lzlib/lib$(R_ARCH)\n", file = Makevars)
    cat("GIT2R_ZLIB_INCLUDE = -Izlib/include\n", file = Makevars)
    cat("endif\n", file = Makevars)
    cat("endif\n", file = Makevars)
    cat("endif\n", file = Makevars)
    cat("\n", file = Makevars)

    cat("PKG_LIBS = $(GIT2R_ZLIB_LIB) -Lopenssl/lib$(R_ARCH) -Llibssh2/lib$(R_ARCH) \\\n", file = Makevars)
    cat("    -L. -lssh2 -lssl -lcrypto -lgdi32 -lws2_32 -lwinhttp \\\n", file = Makevars)
    cat("    -lrpcrt4 -lole32 -lcrypt32 $(Z_LIB)\n", file = Makevars)
    cat("\n", file = Makevars)

    cat("PKG_CFLAGS = -I. $(GIT2R_ZLIB_INCLUDE) -Ilibgit2/src -Ilibgit2/include \\\n", file = Makevars)
    cat("    -Ilibgit2/deps/http-parser -Ilibgit2/deps/regex -Ilibssh2/include \\\n", file = Makevars)
    cat("    -DWIN32 -D_WIN32_WINNT=0x0501 -D__USE_MINGW_ANSI_STDIO=1 -DGIT_WINHTTP \\\n", file = Makevars)
    cat("    -D_FILE_OFFSET_BITS=64 -DGIT_SSH -DGIT_ARCH_$(WIN)\n", file = Makevars)
    cat("\n", file = Makevars)

    build_objects(files, NULL, Makevars)
    cat("\n", file = Makevars)

    cat("all: libwinhttp.dll.a\n", file = Makevars)
    cat("\n", file = Makevars)

    cat("winhttp.def:\n", file = Makevars)
    cat("\tcp libgit2/deps/winhttp/winhttp$(WIN).def.in winhttp.def\n", file = Makevars)
    cat("\n", file = Makevars)

    cat(".PHONY: all\n", file = Makevars)

    invisible(NULL)
}

##' Extract .NAME in .Call(.NAME
##'
##' @param files R files to extract .NAME from
##' @return data.frame with columns filename and .NAME
extract_git2r_calls <- function(files) {
    df <- lapply(files, function(filename) {
        ## Read file
        lines <- readLines(file.path("R", filename))

        ## Trim comments
        comments <- gregexpr("#", lines)
        for (i in seq_len(length(comments))) {
            start <- as.integer(comments[[i]])
            if (start[1] > 0) {
                if (start[1] > 1) {
                    lines[i] <- substr(lines[i], 1, start[1])
                } else {
                    lines[i] <- ""
                }
            }
        }

        ## Trim whitespace
        lines <- sub("^\\s*", "", sub("\\s*$", "", lines))

        ## Collapse to one line
        lines <- paste0(lines, collapse=" ")

        ## Find .Call
        pattern <- "[.]Call[[:space:]]*[(][[:space:]]*[.[:alpha:]\"][^\\),]*"
        calls <- gregexpr(pattern, lines)
        start <- as.integer(calls[[1]])

        if (start[1] > 0) {
            ## Extract .Call
            len <- attr(calls[[1]], "match.length")
            calls <- substr(rep(lines, length(start)), start, start + len - 1)

            ## Trim .Call to extract .NAME
            pattern <- "[.]Call[[:space:]]*[(][[:space:]]*"
            calls <- sub(pattern, "", calls)
            return(data.frame(filename = filename,
                              .NAME = calls,
                              stringsAsFactors = FALSE))
        }

        return(NULL)
    })

    df <- do.call("rbind", df)
    df[order(df$filename),]
}

##' Check that .NAME in .Call(.NAME is prefixed with 'git2r_'
##'
##' Raise an error in case of missing 'git2r_' prefix
##' @param calls data.frame with the name of the C function to call
##' @return invisible NULL
check_git2r_prefix <- function(calls) {
    .NAME <- grep("git2r_", calls$.NAME, value=TRUE, invert=TRUE)

    if (!identical(length(.NAME), 0L)) {
        i <- which(calls$.NAME == .NAME)
        msg <- sprintf("%s in %s\n", calls$.NAME[i], calls$filename[i])
        msg <- c("\n\nMissing 'git2r_' prefix:\n", msg, "\n")
        stop(msg)
    }

    invisible(NULL)
}

##' Check that .NAME is a registered symbol in .Call(.NAME
##'
##' Raise an error in case of .NAME is of the form "git2r_"
##' @param calls data.frame with the name of the C function to call
##' @return invisible NULL
check_git2r_use_registered_symbol <- function(calls) {
    .NAME <- grep("^\"", calls$.NAME)

    if (!identical(length(.NAME), 0L)) {
        msg <- sprintf("%s in %s\n", calls$.NAME[.NAME], calls$filename[.NAME])
        msg <- c("\n\nUse registered symbol instead of:\n", msg, "\n")
        stop(msg)
    }

    invisible(NULL)
}

## Check that all git2r C functions are prefixed with 'git2r_' and
## registered
calls <- extract_git2r_calls(list.files("R", "*.r"))
check_git2r_prefix(calls)
check_git2r_use_registered_symbol(calls)

## Generate Makevars
build_Makevars.in()
build_Makevars.win()
