#                                               -*- Autoconf -*-
# $Id$

AC_PREREQ([2.59])
AC_INIT([smtpc], [0.1a.4], [sympa-authors@listes.renater.fr])
AM_INIT_AUTOMAKE([foreign -Wall -Werror 1.9 tar-pax])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])
AC_CONFIG_HEADERS([config.h])

# Check options
# If you bundle me in other package, use --disable-smtpc not to build me.
AC_ARG_ENABLE(
    smtpc, [],
    [case "$enableval" in
     yes) smtpc=true;;
     no) smtpc=false;;
     *) smtpc=true;;
     esac],
    [smtpc=true]
)

# Checks for programs.
AC_PROG_CC

if test x$smtpc = xtrue; then

# Checks for libraries.

# Checks for header files.
AC_CHECK_HEADERS([fcntl.h netdb.h stdlib.h string.h sys/socket.h unistd.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_TYPE_SIZE_T
AC_TYPE_SSIZE_T
AC_CHECK_SIZEOF([unsigned int])
AC_CHECK_SIZEOF([unsigned long])

# Checks for library functions.
AC_FUNC_MALLOC
AC_FUNC_REALLOC
AC_CHECK_FUNCS([memset select socket strdup strerror])
AC_FUNC_SNPRINTF
AC_CHECK_FUNC([getaddrinfo], [],
  [AC_CHECK_LIB([socket], [getaddrinfo], [LIBS="-lsocket -lnsl $LIBS"], [],
    [-lnsl])])

fi

AC_CONFIG_FILES([Makefile smtpc.1])
AC_OUTPUT
