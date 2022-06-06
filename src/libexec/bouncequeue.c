/* $Id$ */
/*
  Sympa - SYsteme de Multi-Postage Automatique

  Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
  Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
  2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
  Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <stdio.h>
#include <ctype.h>
#include <fcntl.h>
#include <sysexits.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <time.h>

static char     buf[16384];
static int      i, fd;

/* For HP-UX */
#ifndef EX_CONFIG
# define EX_CONFIG 78
#endif

#ifndef CONFIG
# define CONFIG		"/etc/sympa/sympa.conf"
#endif

char *
readconf(char *file)
{
   FILE			*f;
   char	buf[16384], *p, *r, *s;

   r = NULL;
   if ((f = fopen(file, "r")) != NULL) {
      while (fgets(buf, sizeof buf, f) != NULL) {
	/* Search for the configword "queuebounce" and a whitespace after it */
	if (strncmp(buf, "queuebounce", 11) == 0 && isspace(buf[11])) {
            /* Strip the ending \n */
            if ((p = strrchr((char *)buf, '\n')) != NULL)
               *p = '\0';
            p = buf + 11;
            while (*p && isspace(*p)) p++;
            if (*p != '\0')
               r = p;
            break;
	}
      }
   fclose(f);
   }
   else {
      printf ("SYMPA internal error : unable to open %s",file);
      exit (-1);
   }

   if (r != NULL) {
      s = malloc(strlen(r) + 1);
      if (s != NULL)
         strcpy(s, r);
   }
   else
      s = SPOOLDIR "/bounce";
   return s;
}


/*
** Main loop.
*/
int
main(int argn, char **argv)
{
   char	*bouncedir, *listname, *qfile;
   int			firstline = 1;

   /* Usage : bouncequeue list-name */
   if (argn != 2) {
      exit(EX_USAGE);
   }
   if (!*(listname = argv[1]))
      exit(EX_USAGE);
   if ((qfile = malloc(strlen(listname) + 43)) == NULL)
      exit(EX_TEMPFAIL);

   if ((bouncedir = readconf(CONFIG)) == NULL)
      exit(EX_CONFIG);
   if (chdir(bouncedir) == -1) {
      exit(EX_NOPERM);
   }
   umask(027);
   snprintf(qfile, strlen(listname) + 43, "T.%s.%ld.%d", listname, time(NULL), getpid());
   fd = open(qfile, O_CREAT|O_WRONLY, 0600);
   if (fd == -1)
      exit(EX_TEMPFAIL);
   write(fd, "X-Sympa-To: ", 12);
   write(fd, listname, strlen(listname));
   write(fd, "\n", 1);
   while (fgets(buf, sizeof buf, stdin) != NULL) {
      if (firstline == 1 && strncmp(buf, "From ", 5) == 0) {
         firstline = 0;
         continue;
      }
      firstline = 0;
      write(fd, buf, strlen(buf));
   }
   while ((i = read(fileno(stdin), buf, sizeof buf)) > 0)
   close(fd);
   rename(qfile, qfile + 2);
   sleep(1);
   exit(0);
}
