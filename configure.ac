# configure.in - Top-level configure.in for Sympa
# RCS Identication ; $Revision$ ; $Date$ 
#
# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
# Copyright (c) 1997,1998, 1999 Institut Pasteur & Christophe Wolfhugel
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

AC_PREREQ(2.59)
AC_INIT(sympa, 6.0a.6, sympa-authors@cru.fr)
AM_INIT_AUTOMAKE

# Setup the VERSION variable
AC_SUBST(VERSION,AC_PACKAGE_VERSION)

AC_PREFIX_DEFAULT(/home/sympa)

## Directories setup
## for main config files

## location of main config files
CONFDIR='/etc'
AC_ARG_WITH(confdir, [  --with-confdir=DIR     Sympa main configuration files in DIR  (default /etc)], [CONFDIR="$withval"])
AC_SUBST(CONFDIR)

## location of CGIs
CGIDIR='${prefix}/bin'
AC_ARG_WITH(cgidir, [  --with-cgidir=DIR     CGIs in DIR  (default ${prefix}/bin)], [CGIDIR="$withval"])
AC_SUBST(CGIDIR)

## location of user executables
BINDIR='${prefix}/bin'
AC_ARG_WITH(bindir, [  --with-bindir=DIR     user executables in DIR (default ${prefix}/bin). queue and bouncequeue programs will be installed in this directory. If sendmail is configured to use smrsh (check the mailer prog definition in your sendmail.cf), this should point to /etc/smrsh. This is probably the case if you are using Linux], [BINDIR="$withval"])
AC_SUBST(BINDIR)

## location of system admin executables
SBINDIR='${prefix}/bin'
AC_ARG_WITH(sbindir, [  --with-sbindir=DIR     system admin executables in DIR (default ${prefix}/bin)], [SBINDIR="$withval"])
AC_SUBST(SBINDIR)

## location of program executables
LIBEXECDIR='${prefix}/bin'
AC_ARG_WITH(libexecdir, [  --with-libexecdir=DIR     program executables in DIR (default ${prefix}/bin)], [LIBEXECDIR="$withval"])
AC_SUBST(LIBEXECDIR)

## location of Perl modules
LIBDIR='${prefix}/bin'
AC_ARG_WITH(libdir, [  --with-libdir=DIR     Perl modules in DIR (default ${prefix}/bin)], [LIBDIR="$withval"])
AC_SUBST(LIBDIR)

## location of default *read-only* data files
DATADIR='${prefix}/bin/etc'
AC_ARG_WITH(datadir, [  --with-datadir=DIR     default *read-only* data files in DIR (default ${prefix}/bin/etc)], [DATADIR="$withval"])
AC_SUBST(DATADIR)

## location of modifiable data files
EXPLDIR='${prefix}/expl'
AC_ARG_WITH(expldir, [  --with-expldir=DIR     modifiable data files in DIR (default ${prefix}/expl)], [EXPLDIR="$withval"])
AC_SUBST(EXPLDIR)

## location of documentation
MANDIR='/usr/local/man'
AC_ARG_WITH(mandir, [  --with-mandir=DIR     documentation in DIR (default /usr/local/man)], [MANDIR="$withval"])
AC_SUBST(MANDIR)

## SYS V init scripts directory
INITDIR=/etc/rc.d/init.d
AC_ARG_WITH(initdir, [  --with-initdir=DIR     install System V init script in DIR  (default /etc/rc.d/init.d)], [INITDIR="$withval"])
AC_SUBST(INITDIR)

## Lock directory
LOCKDIR=/var/lock/subsys
AC_ARG_WITH(lockdir, [  --with-lockdir=DIR     create lock files in DIR  (default /var/lock/subsys)], [LOCKDIR="$withval"])
AC_SUBST(LOCKDIR)

## directory for storing .pid files
PIDDIR='${prefix}'
AC_ARG_WITH(piddir, [  --with-piddir=DIR     create .pid files in DIR  (default ${prefix})], [PIDDIR="$withval"])
AC_SUBST(PIDDIR)

## directory for Config directories populated by the user
ETCDIR='${prefix}/etc'
AC_ARG_WITH(etcdir, [  --with-etcdir=DIR     Config directories populated by the user are in DIR  (default ${prefix}/etc)], [ETCDIR="$withval"])
AC_SUBST(ETCDIR)

## directory for language files
LOCALEDIR='${prefix}/locale'
AC_ARG_WITH(localedir, [  --with-localedir=DIR     create language files in DIR  (default ${prefix}/locale)], [LOCALEDIR="$withval"])
AC_SUBST(LOCALEDIR)

## directory for Documentation files
DOCDIR='${prefix}/doc'
AC_ARG_WITH(docdir, [  --with-docdir=DIR     create documentation files in DIR  (default ${prefix}/doc)], [DOCDIR="$withval"])
AC_SUBST(DOCDIR)

## directory for script files
SCRIPTDIR='${prefix}/bin'
AC_ARG_WITH(scriptdir, [  --with-scriptdir=DIR     create script files in DIR  (default ${prefix}/bin)], [SCRIPTDIR="$withval"])
AC_SUBST(SCRIPTDIR)

## directory for sample files
SAMPLEDIR='${prefix}/sample'
AC_ARG_WITH(sampledir, [  --with-sampledir=DIR     create sample files in DIR  (default ${prefix}/sample)], [SAMPLEDIR="$withval"])
AC_SUBST(SAMPLEDIR)

## directory for sample files
SPOOLDIR='${prefix}/spool'
AC_ARG_WITH(spooldir, [  --with-spooldir=DIR     spool directory is DIR  (default ${prefix}/spool)], [SPOOLDIR="$withval"])
AC_SUBST(SPOOLDIR)

## to run wwsympa.fcgi without setuidperl
AC_ARG_ENABLE(
    [secure],
    AS_HELP_STRING(
	[--enable-secure],
	[install wwsympa to be run in a secure mode, without suidperl (default disabled)]
    )
)
AC_SUBST(enable_secure)

dnl Checks for programs.
AC_PROG_CC
AC_PROG_MAKE_SET
AC_AIX

AC_PATH_PROG(PERL, perl, /usr/bin/perl)
AC_ARG_WITH(
    [perl],
    AS_HELP_STRING(
	[--with-perl=FULLPATH],
	[set full path to Perl interpreter (default /usr/bin/perl)]
    ),
    [PERL="$withval"]
)
AC_SUBST(PERL)

AC_PATH_PROG(SUIDPERL, suidperl, /usr/bin/suidperl)
AC_SUBST(SUIDPERL)

AC_PATH_PROG(SUDO, sudo, /usr/bin/sudo)
AC_SUBST(SUDO)

AC_PATH_PROG(MHONARC, mhonarc, /usr/bin/mhonarc)
AC_ARG_WITH(
    [mhonarc],
    AS_HELP_STRING(
	[--with-mhonarc=FULLPATH],
	[set full path to MhOnArc mail archiving system (default /usr/bin/mhonarc)]
    ),
    [MHONARC="$withval"]
)
AC_SUBST(MHONARC)

AC_PATH_PROG(OPENSSL, openssl, /usr/local/ssl/bin)
AC_ARG_WITH(
    [openssl],
    AS_HELP_STRING(
	[--with-openssl=FULLPATH],
	[set path to OpenSSL (default /usr/local/ssl/bin/openssl)]
    ),
    [OPENSSL="$withval"]
)
AC_SUBST(OPENSSL)

AC_PATH_PROG(CVS2CL, cvs2cl.pl, /usr/local/bin)
AC_SUBST(CVS2CL)

AC_PATH_PROG(MSGFMT, msgfmt, /usr/bin/msgfmt)
AC_SUBST(MSGFMT)

USER=sympa
AC_ARG_WITH(
    [user],
    AS_HELP_STRING(
	[--with-user=LOGIN],
	[set sympa user name (default sympa)]
    ),
    [USER="$withval"]
)
AC_SUBST(USER)

GROUP=sympa
AC_ARG_WITH(
    [group],
    AS_HELP_STRING(
	[--with-group=LOGIN],
	[set sympa group name (default sympa)]
    ),
    [GROUP="$withval"]
)
AC_SUBST(GROUP)

SENDMAIL_ALIASES=/etc/mail/sympa_aliases
AC_ARG_WITH(
    [sendmail_aliases],
    AS_HELP_STRING(
	[--with-sendmail_aliases=ALIASFILE],
	[set aliases file to be used by Sympa (default /etc/mail/sympa_aliases)]
    ),
    [SENDMAIL_ALIASES="$withval"]
)
AC_SUBST(SENDMAIL_ALIASES)

VIRTUAL_ALIASES=/etc/mail/sympa_virtual
AC_ARG_WITH(
    [virtual_aliases],
    AS_HELP_STRING(
	[--with-virtual_aliases=ALIASFILE],
	[ set postfix virtual file to be used by Sympa (default /etc/mail/sympa_virtual)]
    ),
    [VIRTUAL_ALIASES="$withval"]
)
AC_SUBST(VIRTUAL_ALIASES)

NEWALIASES=/usr/bin/newaliases
AC_ARG_WITH(
    [newaliases],
    AS_HELP_STRING(
	[--with-newaliases=FULLPATH],
	[set path to newaliases command (default /usr/bin/newaliases)]
    ),
    [NEWALIASES="$withval"]
)
AC_SUBST(NEWALIASES)

NEWALIASES_ARG=
AC_ARG_WITH(
    [newaliases_arg],
    AS_HELP_STRING(
	[--with-newaliases_arg=ARGS],
	[set arguments to newaliases command (default NONE)]
    ),
    [NEWALIASES_ARG="$withval"]
)
AC_SUBST(NEWALIASES_ARG)

POSTMAP=/usr/sbin/postmap
AC_ARG_WITH(
    [postmap],
    AS_HELP_STRING(
	[--with-postmap=FULLPATH],
	[set path to postfix postmap command (default /usr/sbin/postmap)]
    ),
    [POSTMAP="$withval"]
)
AC_SUBST(POSTMAP)

POSTMAP_ARG=${VIRTUAL_ALIASES}
AC_ARG_WITH(
    [postmap_arg],
    AS_HELP_STRING(
	[--with-postmap_arg=ARGS],
	[set arguments to postfix postmap command (default [same as virtual_aliases])]
    ),
    [POSTMAP_ARG="$withval"]
)
AC_SUBST(POSTMAP_ARG)

AC_CONFIG_FILES([
    Makefile
    src/etc/sample/Makefile
    src/etc/script/Makefile
    src/Makefile
    soap/Makefile
    doc/man8/Makefile
    doc/Makefile
    web_tt2/Makefile
    wwsympa/Makefile
    mail_tt2/Makefile
])
AC_OUTPUT
