# configure.ac - Top-level configure.in for Sympa
# $Id$
#
# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018, 2019, 2020 The Sympa Community. See the AUTHORS.md
# file at the top-level directory of this distribution and at
# <https://github.com/sympa-community/sympa.git>.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

AC_PREREQ(2.60)
AC_INIT(sympa, 6.2.58, sympa-developpers@listes.renater.fr)
AM_INIT_AUTOMAKE([foreign -Wall -Werror 1.9 tar-pax])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])
AM_PO_SUBDIRS
GETTEXT_MACRO_VERSION=0.19

AC_PREFIX_DEFAULT(/home/sympa)

## first initialises parameters to the standard Sympa filesystem organization
# $prefix variable initialisation seems to be tricky
if test "$prefix" = "NONE"; then
   prefix=$ac_default_prefix
fi

## allow user to select FHS-compliant installation
AC_ARG_ENABLE(
	fhs,
	AS_HELP_STRING(
	[--enable-fhs],
	[use standard FHS files and directories locations and naming (default is no)]
	),
	[fhs=$enableval]
)

if test "$fhs" = "yes"; then
    # only define custom variables
    initdir=$sysconfdir/rc.d/init.d
    unitsdir=
    smrshdir=$sysconfdir/smrsh
    piddir=$localstatedir/run/sympa
    lockdir=/var/lock/subsys
    modulesdir=$datadir/sympa/lib
    scriptdir=$datadir/sympa/bin
    defaultdir=$datadir/sympa/default
    execcgidir=$libdir/sympa/cgi
    expldir=$localstatedir/lib/sympa/list_data
    staticdir=$localstatedir/lib/sympa/static_content
    cssdir=$localstatedir/lib/sympa/static_content/css
    picturesdir=$localstatedir/lib/sympa/static_content/pictures
    spooldir=$localstatedir/spool/sympa
    arcdir=$localstatedir/lib/sympa/arc
    bouncedir=$localstatedir/lib/sympa/bounce
    confdir=$sysconfdir/sympa
else
    # redefine default values for some standard variables,
    # but only if no value was given
    if test "$sbindir" = '${exec_prefix}/sbin'; then
       sbindir=$prefix/bin
    fi
    if test "$libexecdir" = '${exec_prefix}/libexec'; then
	libexecdir=$prefix/bin
    fi
    if test "$localstatedir" = '${prefix}/var'; then
	localstatedir=/var
    fi
    if test "$localedir" = '${datarootdir}/locale'; then
	localedir=$prefix/locale
    fi

    # define custom variables
    initdir=/etc/rc.d/init.d
    unitsdir=
    smrshdir=/etc/smrsh
    piddir=$prefix
    lockdir=/var/lock/subsys
    modulesdir=$prefix/bin
    scriptdir=$prefix/bin
    defaultdir=$prefix/default
    execcgidir=$prefix/bin
    expldir=$prefix/list_data
    spooldir=$prefix/spool
    staticdir=$prefix/static_content
    cssdir=$prefix/static_content/css
    picturesdir=$prefix/static_content/pictures
    arcdir=$prefix/arc
    bouncedir=$prefix/bounce
    confdir=/etc/sympa
fi
 
# substitute custom variables
AC_SUBST(initdir)
AC_SUBST(unitsdir)
AC_SUBST(smrshdir)
AC_SUBST(piddir)
AC_SUBST(lockdir)
AC_SUBST(modulesdir)
AC_SUBST(scriptdir)
AC_SUBST(defaultdir)
AC_SUBST(execcgidir)
AC_SUBST(expldir)
AC_SUBST(spooldir)
AC_SUBST(staticdir)
AC_SUBST(cssdir)
AC_SUBST(picturesdir)
AC_SUBST(arcdir)
AC_SUBST(bouncedir)
AC_SUBST(localedir)
AC_SUBST(confdir)
AC_SUBST(docdir)

# allow user to redefine some of them
AC_ARG_WITH(
    confdir,
    AS_HELP_STRING(
	[--with-confdir=DIR],
	[Directory of Sympa main configuration file (sympa.conf) @<:@SYSCONFDIR/sympa@:>@]
    ),
    [
	confdir="$withval"
    ]
)

AC_ARG_WITH(
    etcdir,
    [],
    [AC_MSG_ERROR([obsolete --with-etcdir option used. use --sysconfdir instead.])]
)

AC_ARG_WITH(
    bindir,
    [],
    [AC_MSG_ERROR([obsolete --with-bindir option used. those binaries are now installed in LIBEXECDIR.])]
)

AC_ARG_WITH(
    sbindir,
    [],
    [AC_MSG_ERROR([obsolete --with-sbindir option used. use --sbindir instead.])]
)

AC_ARG_WITH(
    libexecdir,
    [],
    [AC_MSG_ERROR([obsolete --with-libexecdir option used. use --libexecdir instead.])]
)

AC_ARG_WITH(
    cgidir,
    AS_HELP_STRING(
	[--with-cgidir=DIR],
	[CGI scripts @<:@PREFIX/bin@:>@]
    ),
    [execcgidir="$withval"]
)

AC_ARG_WITH(
    datadir,
    [],
    [AC_MSG_ERROR([obsolete --with-datadir option used. use --datadir instead.])]
)

AC_ARG_WITH(
    libdir,
    [],
    [AC_MSG_ERROR([obsolete --with-libdir option used. use --with-modulesdir instead.])]
)

AC_ARG_WITH(
    localedir,
    AS_HELP_STRING(
	[--with-localedir=DIR],
	[Internationalization catalogues directory @<:@PREFIX/locale@:>@]
    ),
    [
     localedir="$withval"
    ]
)

AC_ARG_WITH(
    mandir,
    [],
    [AC_MSG_ERROR([obsolete --with-mandir option used. use --mandir instead.])]
)

AC_ARG_WITH(
    docdir,
    AS_HELP_STRING(
	[--with-docdir=DIR],
	[Documentations]
    ),
    [
	docdir="$withval"
    ]
)

AC_ARG_WITH(
    sampledir,
    [],
    [AC_MSG_ERROR([obsolete --with-sampledir option used. samples are now installed with documentation.])]
)

AC_ARG_WITH(
    expldir,
    AS_HELP_STRING(
	[--with-expldir=DIR],
	[list data directory @<:@PREFIX/list_data@:>@]
    ),
    [expldir="$withval"]
)

AC_ARG_WITH(
    spooldir,
    AS_HELP_STRING(
	[--with-spooldir=DIR],
	[application spool directory @<:@PREFIX/spool@:>@]
    ),
    [spooldir="$withval"]
)

AC_ARG_WITH(
    initdir,
    AS_HELP_STRING(
	[--with-initdir=DIR],
	[install System V init script @<:@SYSCONFDIR/rc.d/init.d@:>@]
    )
AS_HELP_STRING(
        [--without-initdir],
        [do not install System V init script]
    ),
    [test "x$withval" = "xyes" || initdir="$withval"; test "x$withval" = "xno" && initdir=""]
)
AM_CONDITIONAL([SYSV_INIT], [test "x$initdir" != "x"])

AC_ARG_WITH(
    unitsdir,
    AS_HELP_STRING(
	[--with-unitsdir=DIR],
	[install Systemd unit files @<:@no@:>@]
    ),
    [test "x$withval" = "xyes" || unitsdir="$withval"; test "x$withval" = "xno" && unitsdir=""]
)
AM_CONDITIONAL([SYSTEMD_UNITS], [test "x$unitsdir" != "x"])

AC_ARG_WITH(
    smrshdir,
    AS_HELP_STRING(
	[--with-smrshdir=DIR],
	[install symbolic links for Sendmail smrsh @<:@SYSCONFDIR/smrsh@:>@]
    )
AS_HELP_STRING(
        [--without-smrshdir],
        [do not install symbolic links for Sendmail smrsh]
    ),
    [test "x$withval" = "xyes" || smrshdir="$withval"; test "x$withval" = "xno" && smrshdir=""]
)
AM_CONDITIONAL(SMRSH, [test "x$smrshdir" != "x"])

AC_ARG_WITH(
    lockdir,
    AS_HELP_STRING(
	[--with-lockdir=DIR],
	[lock files @<:@/var/lock/subsys@:>@]
    ),
    [lockdir="$withval"]
)

AC_ARG_WITH(
    piddir,
    AS_HELP_STRING(
	[--with-piddir=DIR],
	[.pid files @<:@LOCALSTATEDIR/run@:>@]
    ),
    [piddir="$withval"]
)

AC_ARG_WITH(
    modulesdir,
    AS_HELP_STRING(
	[--with-modulesdir=DIR],
	[Perl modules file installed with Sympa @<:@PREFIX/bin@:>@]
    ),
    [modulesdir="$withval"]
)

AC_ARG_WITH(
    defaultdir,
    AS_HELP_STRING(
	[--with-defaultdir=DIR],
	[default configuration files (scenarios and templates also) @<:@PREFIX/default@:>@]
    ),
    [defaultdir="$withval"]
)

AC_ARG_WITH(
    scriptdir,
    AS_HELP_STRING(
	[--with-scriptdir=DIR],
	[application scripts @<:@PREFIX/bin@:>@]
    ),
    [scriptdir="$withval"]
)

AC_ARG_WITH(
    staticdir,
    AS_HELP_STRING(
	[--with-staticdir=DIR],
	[static data @<:@PREFIX/static_content@:>@]
    ),
    [staticdir="$withval"]
)

AC_ARG_WITH(
    cssdir,
    AS_HELP_STRING(
	[--with-cssdir=DIR],
	[generated css  @<:@PREFIX/static_content/css@:>@]
    ),
    [cssdir="$withval"]
)

AC_ARG_WITH(
    picturesdir,
    AS_HELP_STRING(
	[--with-picturesdir=DIR],
	[subscribers pictures  @<:@PREFIX/static_content/pictures@:>@]
    ),
    [picturesdir="$withval"]
)

CONFIG=$confdir/sympa.conf
AC_SUBST(CONFIG)
WWSCONFIG=$confdir/wwsympa.conf
AC_SUBST(WWSCONFIG)

AC_PROG_CC
# needed for using per-target flags
AM_PROG_CC_C_O
AC_PATH_PROGS([SED], [sed gsed])
#AC_PROG_SED
AC_PROG_LN_S

AC_ARG_WITH(
    [perl],
    AS_HELP_STRING(
	[--with-perl=FULLPATH],
        [set full path to Perl interpreter]
    ),
    [PERL="$withval"]
)
if test -n "$PERL"; then
    # user-supplied value
    AC_MSG_CHECKING([user-supplied Perl interpreter])
    if test -f "$PERL"; then
	:
    else
	AC_MSG_RESULT([non-existing])
	AC_MSG_ERROR([invalid value $PERL for Perl interpreter])
    fi
    if test -x "$PERL"; then
	:
    else
	AC_MSG_RESULT([non-executable])
	AC_MSG_ERROR([invalid value $PERL for Perl interpreter])
    fi
    AC_MSG_RESULT([$PERL])
else
    # check in PATH
    AC_PATH_PROG(PERL, perl)
    if test -z "$PERL"; then
	AC_MSG_ERROR([perl required])
    fi
fi

AC_PATH_PROG(POD2MAN, pod2man)
if test -z "$POD2MAN"; then
    AC_MSG_ERROR([pod2man required])
fi

USER=sympa
AC_ARG_WITH(
    [user],
    AS_HELP_STRING(
	[--with-user=LOGIN],
	[set Sympa user name @<:@sympa@:>@]
    ),
    [USER="$withval"]
)
AC_SUBST(USER)

GROUP=sympa
AC_ARG_WITH(
    [group],
    AS_HELP_STRING(
	[--with-group=LOGIN],
	[set Sympa group name @<:@sympa@:>@]
    ),
    [GROUP="$withval"]
)
AC_SUBST(GROUP)

SENDMAIL_ALIASES=/etc/mail/sympa_aliases
AC_ARG_WITH(
    [aliases_file],
    AS_HELP_STRING(
	[--with-aliases_file=ALIASFILE],
	[aliases file to store Sympa mail aliases @<:@/etc/mail/sympa_aliases@:>@]
    ),
    [SENDMAIL_ALIASES="$withval"]
)
AC_SUBST(SENDMAIL_ALIASES)

AC_ARG_WITH(
    [sendmail_aliases], ,
    AC_MSG_ERROR([--with-sendmail_aliases was deprecated.  Use --with-aliases_file.])
)

VIRTUAL_ALIASES=
AC_ARG_WITH(
    [virtual_aliases], ,
    AC_MSG_ERROR([--with-virtual_aliases was deprecated.  Use --with-aliases_file.])
)
AC_SUBST(VIRTUAL_ALIASES)

MAKEMAP=
AC_ARG_WITH(
    [makemap],
    AS_HELP_STRING(
	[--with-makemap=FULLPATH],
	[path to Sendmail makemap command @<:@AUTO-DETECT@:>@]
    ),
    [MAKEMAP="$withval"]
)
if test -n "$MAKEMAP"; then
    # user-supplied value
    AC_MSG_CHECKING([user-supplied makemap command])
    if test -f "$MAKEMAP"; then
	:
    else
	AC_MSG_RESULT([non-existing])
	AC_MSG_ERROR([invalid value $MAKEMAP for makemap command])
    fi
    if test -x "$MAKEMAP"; then
	:
    else
	AC_MSG_RESULT([non-executable])
	AC_MSG_ERROR([invalid value $MAKEMAP for makemap command])
    fi
    AC_MSG_RESULT([$MAKEMAP])
else
    # default value
    AC_PATH_PROG([MAKEMAP], [makemap], [/usr/bin/makemap])
fi
AC_SUBST(MAKEMAP)

NEWALIASES=
AC_ARG_WITH(
    [newaliases],
    AS_HELP_STRING(
	[--with-newaliases=FULLPATH],
	[path to newaliases command @<:@AUTO-DETECT@:>@]
    ),
    [NEWALIASES="$withval"]
)
if test -n "$NEWALIASES"; then
    # user-supplied value
    AC_MSG_CHECKING([user-supplied newaliases command])
    if test -f "$NEWALIASES"; then
	:
    else
	AC_MSG_RESULT([non-existing])
	AC_MSG_ERROR([invalid value $NEWALIASES for newaliases command])
    fi
    if test -x "$NEWALIASES"; then
	:
    else
	AC_MSG_RESULT([non-executable])
	AC_MSG_ERROR([invalid value $NEWALIASES for newaliases command])
    fi
    AC_MSG_RESULT([$NEWALIASES])
else
    # default value
    AC_PATH_PROG([NEWALIASES], [newaliases], [/usr/bin/newaliases])
fi
AC_SUBST(NEWALIASES)

if test -n "$CAT"; then
    # user-supplied value
    AC_MSG_CHECKING([user-supplied cat command])
    if test -f "$CAT"; then
	:
    else
	AC_MSG_RESULT([non-existing])
	AC_MSG_ERROR([invalid value $CAT for cat command])
    fi
    if test -x "$CAT"; then
	:
    else
	AC_MSG_RESULT([non-executable])
	AC_MSG_ERROR([invalid value $CAT for cat command])
    fi
    AC_MSG_RESULT([$CAT])
else
    # default value
    AC_PATH_PROG([CAT], [cat], [/bin/cat])
fi
AC_SUBST(CAT)

AC_MSG_CHECKING([argument to newaliases command])
NEWALIASES_ARG=
AC_ARG_WITH(
    [newaliases_arg],
    AS_HELP_STRING(
	[--with-newaliases_arg=ARGS],
	[arguments to newaliases command @<:@NONE@:>@]
    ),
    [NEWALIASES_ARG="$withval"]
)
AC_SUBST(NEWALIASES_ARG)
if test -z "$NEWALIASES_ARG"; then
    AC_MSG_RESULT([none])
else
    AC_MSG_RESULT([$NEWALIASES_ARG])
fi

POSTALIAS=
AC_ARG_WITH(
    [postalias],
    AS_HELP_STRING(
	[--with-postalias=FULLPATH],
	[path to Postfix postalias command @<:@AUTO-DETECT@:>@]
    ),
    [POSTALIAS="$withval"]
)
if test -n "$POSTALIAS"; then
    # user-supplied value
    AC_MSG_CHECKING([user-supplied postalias command])
    if test -f "$POSTALIAS"; then
	:
    else
	AC_MSG_RESULT([non-existing])
	AC_MSG_ERROR([invalid value $POSTALIAS for postalias command])
    fi
    if test -x "$POSTALIAS"; then
	:
    else
	AC_MSG_RESULT([non-executable])
	AC_MSG_ERROR([invalid value $POSTALIAS for postalias command])
    fi
    AC_MSG_RESULT([$POSTALIAS])
else
    # default value
    AC_PATH_PROG([POSTALIAS], [postalias], [/usr/sbin/postalias])
fi
AC_SUBST(POSTALIAS)

POSTMAP=
AC_ARG_WITH(
    [postmap],
    AS_HELP_STRING(
	[--with-postmap=FULLPATH],
	[path to Postfix postmap command @<:@AUTO-DETECT@:>@]
    ),
    [POSTMAP="$withval"]
)
if test -n "$POSTMAP"; then
    # user-supplied value
    AC_MSG_CHECKING([user-supplied postmap command])
    if test -f "$POSTMAP"; then
	:
    else
	AC_MSG_RESULT([non-existing])
	AC_MSG_ERROR([invalid value $POSTMAP for postmap command])
    fi
    if test -x "$POSTMAP"; then
	:
    else
	AC_MSG_RESULT([non-executable])
	AC_MSG_ERROR([invalid value $POSTMAP for postmap command])
    fi
    AC_MSG_RESULT([$POSTMAP])
else
    # default value
    AC_PATH_PROG([POSTMAP], [postmap], [/usr/sbin/postmap])
fi
AC_SUBST(POSTMAP)

POSTMAP_ARG=
AC_ARG_WITH(
    [postmap_arg], ,
    AC_MSG_ERROR([--with-postmap_arg was deprecated.  Use --with-newaliases_arg.])
)
AC_SUBST(POSTMAP_ARG)

AC_MSG_CHECKING([whether we install setuid wrappers for web interface])
AC_ARG_ENABLE(
    setuid_fcgi,
    AS_HELP_STRING(
        [--disable-setuid_fcgi],
        [do not install setuid wrappers for web interface]
    ), ,
    [enable_setuid_fcgi="yes"],
)
AC_MSG_RESULT([$enable_setuid_fcgi])
AM_CONDITIONAL(SETUID_FCGI, [test "x$enable_setuid_fcgi" = "xyes"])

AC_MSG_CHECKING([whether we set setuid bit of queue programs])
AC_ARG_ENABLE(
    setuid_queue,
    AS_HELP_STRING(
        [--disable-setuid_queue],
        [do not set setuid bit of queue programs]
    ), ,
    [enable_setuid_queue="yes"],
)
AC_MSG_RESULT([$enable_setuid_queue])
AM_CONDITIONAL(SETUID_QUEUE, [test "x$enable_setuid_queue" = "xyes"])

AC_CONFIG_FILES([
    Makefile
    sympa.conf
    mk-sympa-dist.pl
    default/Makefile
    doc/Makefile
    po/Makefile
    po/sympa/Makefile.in
    po/web_help/Makefile.in
    src/Makefile
    src/bin/Makefile
    src/cgi/Makefile
    src/etc/Makefile
    src/etc/script/Makefile
    src/lib/Makefile
    src/libexec/Makefile
    src/sbin/Makefile
    www/Makefile
])

AC_OUTPUT
