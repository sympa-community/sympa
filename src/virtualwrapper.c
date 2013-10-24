/* virtualwrapper.c
 
  Sympa - SYsteme de Multi-Postage Automatique
  Copyright (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
  Copyright (c) 1997,1998, 1999 Institut Pasteur & Christophe Wolfhugel
 
  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. */

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
	extern char **environ;
	char *arg[3];

	environ[0] = NULL;
	arg[0] = POSTMAP;
	arg[1] = POSTMAP_ARG;
	arg[2] = NULL;
	if (*arg[1] == '\0') {
	  arg[1] = NULL;
	}
	setuid(0);
	execv(arg[0], arg);
	perror("Exec of "POSTMAP POSTMAP_ARG" failed!");
	exit(1);
}
