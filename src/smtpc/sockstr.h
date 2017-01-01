/* $Id$ */
/*
 * Sympa - SYsteme de Multi-Postage Automatique
 *
 * Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
 * Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
 * 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
 * Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <stdarg.h>
#include <sys/types.h>
#include <unistd.h>

#define SOCKSTR_ERRSIZE (128)
#define SOCKSTR_BUFSIZE (8192)

typedef struct {
    char *nodename;
    char *servname;
    char *path;
    int timeout;

    int _sock;
    int _errnum;
    char _errstr[SOCKSTR_ERRSIZE];
    ssize_t _bufcnt;
    char *_bufptr;
    char _buf[SOCKSTR_BUFSIZE];
} sockstr_t;

extern sockstr_t *sockstr_new(char *, char *, char *);
extern void sockstr_destroy(sockstr_t *);
extern char *sockstr_errstr(sockstr_t *);
extern int sockstr_client_connect(sockstr_t *);
extern ssize_t sockstr_getline(sockstr_t *, char **, size_t *, int);
extern ssize_t sockstr_getstatus(sockstr_t *, char **, size_t *);
extern ssize_t sockstr_vprintf(sockstr_t *, const char *, va_list);
extern ssize_t sockstr_printf(sockstr_t *, const char *, ...);
extern ssize_t sockstr_putdata(sockstr_t *, void *, size_t, char *, int,
			       int);
