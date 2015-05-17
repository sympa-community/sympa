# $Id$

ACLOCAL_AMFLAGS = -I m4

sbin_PROGRAMS = smtpc
smtpc_SOURCES = \
	smtpc.c \
	sockstr.c \
	sockstr.h \
	utf8.c \
	utf8.h
dist_man1_MANS = smtpc.1

CLEANFILES = $(sbin_PROGRAMS) *~ *.bak core.*

smtpc.o: sockstr.h utf8.h

