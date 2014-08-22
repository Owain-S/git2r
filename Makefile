# Determine package name and version from DESCRIPTION file
PKG_VERSION=$(shell grep -i ^version DESCRIPTION | cut -d : -d \  -f 2)
PKG_NAME=$(shell grep -i ^package DESCRIPTION | cut -d : -d \  -f 2)

# Roxygen version to check before generating documentation
ROXYGEN_VERSION=4.0.1

# Name of built package
PKG_TAR=$(PKG_NAME)_$(PKG_VERSION).tar.gz

all: readme
readme: $(patsubst %.Rmd, %.md, $(wildcard *.Rmd))

%md: %Rmd
	Rscript -e "library(knitr); knit('README.Rmd', quiet = TRUE)"
	sed   's/```r/```coffee/' README.md > README2.md
	rm README.md
	mv README2.md README.md

# Build documentation with roxygen
# 1) Check version of roxygen2 before building documentation
# 2) Remove old doc
# 3) Generate documentation
roxygen:
	Rscript -e "library(roxygen2); stopifnot(packageVersion('roxygen2') == '$(ROXYGEN_VERSION)')"
	rm -f man/*.Rd
	cd .. && Rscript -e "library(roxygen2); roxygenize('$(PKG_NAME)')"

# Build and check package
check: clean
	cd .. && R CMD build --no-build-vignettes $(PKG_NAME)
	cd .. && R CMD check --no-manual --no-vignettes --no-build-vignettes $(PKG_TAR)

# Build and check package with valgrind
check_valgrind: clean
	cd .. && R CMD build --no-build-vignettes $(PKG_NAME)
	cd .. && R CMD check --as-cran --no-manual --no-vignettes --no-build-vignettes --use-valgrind $(PKG_TAR)

# Run all tests with valgrind
test_objects = $(wildcard tests/*.R)
valgrind:
	$(foreach var,$(test_objects),R -d "valgrind --tool=memcheck --leak-check=full" --vanilla < $(var);)

# Sync git2r with changes in the libgit2 C-library
#
# 1) clone or pull libgit2 to parent directory from
# https://github.com/libgit/libgit.git
#
# 2) run 'make sync_libgit2'. It first removes files and then copy
# files from libgit2 directory. Next it runs an R script to build
# Makevars.in and Makevars.win based on source files. Finally it runs
# a patch command to change some lines in the source code to pass
# 'R CMD check git2r'
#
# 3) Build and check updated package 'make check'
sync_libgit2:
	-rm -f src/http-parser/*
	-rm -f src/regex/*
	-rm -f src/libgit2/include/*.h
	-rm -f src/libgit2/include/git2/*.h
	-rm -f src/libgit2/include/git2/sys/*.h
	-rm -f src/libgit2/*.c
	-rm -f src/libgit2/*.h
	-rm -f src/libgit2/hash/*.c
	-rm -f src/libgit2/hash/*.h
	-rm -f src/libgit2/transports/*.c
	-rm -f src/libgit2/transports/*.h
	-rm -f src/libgit2/unix/*.c
	-rm -f src/libgit2/unix/*.h
	-rm -f src/libgit2/win32/*.c
	-rm -f src/libgit2/win32/*.h
	-rm -f src/libgit2/xdiff/*.c
	-rm -f src/libgit2/xdiff/*.h
	-rm -f inst/AUTHORS_libgit2
	-rm -f inst/NOTICE
	-cp -f ../libgit2/deps/http-parser/* src/http-parser
	-cp -f ../libgit2/deps/regex/* src/regex
	-cp -f ../libgit2/include/*.h src/libgit2/include
	-cp -f ../libgit2/include/git2/*.h src/libgit2/include/git2
	-cp -f ../libgit2/include/git2/sys/*.h src/libgit2/include/git2/sys
	-cp -f ../libgit2/src/*.c src/libgit2
	-cp -f ../libgit2/src/*.h src/libgit2
	-cp -f ../libgit2/src/hash/*.c src/libgit2/hash
	-cp -f ../libgit2/src/hash/*.h src/libgit2/hash
	-cp -f ../libgit2/src/transports/*.c src/libgit2/transports
	-cp -f ../libgit2/src/transports/*.h src/libgit2/transports
	-cp -f ../libgit2/src/unix/*.c src/libgit2/unix
	-cp -f ../libgit2/src/unix/*.h src/libgit2/unix
	-cp -f ../libgit2/src/win32/*.c src/libgit2/win32
	-cp -f ../libgit2/src/win32/*.h src/libgit2/win32
	-cp -f ../libgit2/src/xdiff/*.c src/libgit2/xdiff
	-cp -f ../libgit2/src/xdiff/*.h src/libgit2/xdiff
	-cp -f ../libgit2/AUTHORS inst/AUTHORS_libgit2
	-cp -f ../libgit2/COPYING inst/NOTICE
	cd src/libgit2 && patch -i ../../misc/cache-pass-R-CMD-check-git2r.patch
	cd src/libgit2 && patch -p0 < ../../misc/diff_print-pass-R-CMD-check-git2r.patch
	cd src/libgit2 && patch -i ../../misc/util-pass-R-CMD-check-git2r.patch
	cd src/regex && patch -i ../../misc/regcomp-pass-R-CMD-check-git2r.patch
	cd src/libgit2/win32 && patch -i ../../../misc/posix-pass-R-CMD-check-git2r.patch
	Rscript misc/build_Makevars.r

Makevars:
	Rscript misc/build_Makevars.r

configure: configure.ac
	autoconf ./configure.ac > ./configure
	chmod +x ./configure

clean:
	-rm -f config.log
	-rm -f config.status
	-rm -rf autom4te.cache
	-rm -f src/Makevars
	-rm -f src/*.o
	-rm -f src/*.so
	-rm -f src/libgit2/*.o
	-rm -f src/libgit2/hash/*.o
	-rm -f src/libgit2/transports/*.o
	-rm -f src/libgit2/unix/*.o
	-rm -f src/libgit2/win32/*.o
	-rm -f src/libgit2/xdiff/*.o
	-rm -f src/http-parser/*.o

.PHONY: all readme doc sync_libgit2 Makevars check clean
