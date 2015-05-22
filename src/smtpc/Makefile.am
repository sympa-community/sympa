# $Id$

ACLOCAL_AMFLAGS = -I m4

bin_PROGRAMS = smtpc
smtpc_SOURCES = \
	smtpc.c \
	sockstr.c \
	sockstr.h \
	utf8.c \
	utf8.h
man1_MANS = smtpc.1

EXTRA_DIST = configure.gnu smtpc.1.in
CLEANFILES = $(bin_PROGRAMS) *~ *.bak core.*

smtpc.o: sockstr.h utf8.h

