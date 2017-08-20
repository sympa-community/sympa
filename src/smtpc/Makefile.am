# $Id$

ACLOCAL_AMFLAGS = -I m4

bin_PROGRAMS = smtpc
smtpc_SOURCES = \
	smtpc.c \
	sockstr.c \
	sockstr.h \
	utf8.c \
	utf8.h
dist_doc_DATA = smtpc.1.md

EXTRA_DIST = configure.gnu
CLEANFILES = $(bin_PROGRAMS) *~ *.bak core.*

smtpc.o: sockstr.h utf8.h

