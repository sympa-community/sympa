#include <stdio.h>
#include <ctype.h>
#include <fcntl.h>
#include <sysexits.h>
#include <string.h>
#include <stdlib.h>

static char     qfile[128];
static char     buf[16384];
static int      i, fd;

#ifndef CONFIG
# define CONFIG		"/etc/sympa.conf"
#endif

unsigned char *
readconf(char *file)
{
   FILE			*f;
   unsigned char	buf[16384], *p, *r, *s;

   r = NULL;
   if ((f = fopen(file, "r")) != NULL) {
      while (fgets(buf, sizeof buf, f) != NULL) {
	/* Search for the configword "queuebounce" and a whitespace after it */
	if (strncmp(buf, "queuebounce", 11) == 0 && isspace(buf[11])) {
            /* Strip the ending \n */
            if ((p = (unsigned char *)strrchr((char *)buf, '\n')) != NULL)
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
   return s;
}


/*
** Main loop.
*/
int
main(int argn, char **argv)
{
   unsigned char	*bouncedir;
   unsigned char        *listname;
   unsigned int		priority;
   int			firstfrom = 0;

   /* Usage : bouncequeue list-name */
   if (argn != 2) {
      exit(EX_TEMPFAIL);
   }

   listname = malloc(strlen(argv[1]) + 1);
   if (listname != NULL)
     strcpy(listname, argv[1]);

   if ((bouncedir = readconf(CONFIG)) == NULL)
      exit(EX_TEMPFAIL);
   if (chdir(bouncedir) == -1) {
      exit(EX_TEMPFAIL);
   }
   umask(027);
   sprintf(qfile, "T.%s.%ld.%d", listname, time(NULL), getpid());
   fd = open(qfile, O_CREAT|O_WRONLY, 0600);
   if (fd == -1)
      exit(EX_TEMPFAIL);
   write(fd, "X-Sympa-To: ", 12);
   write(fd, listname, strlen(listname));
   write(fd, "\n", 1);
   while (fgets(buf, sizeof buf, stdin) != NULL) {
      if (firstfrom == 0 && strncmp(buf, "From ", 5) == 0) {
         firstfrom = 1;
         continue;
      }
      write(fd, buf, strlen(buf));
   }
   while ((i = read(fileno(stdin), buf, sizeof buf)) > 0)
   close(fd);
   rename(qfile, qfile + 2);
   sleep(1);
   exit(0);
}







