
#include <unistd.h>
#include <stdio.h>

int main(int argc, char *argv[])
{
	setuid(0);
	execle(NEWALIASES, NEWALIASES, NEWALIASES_ARG, NULL);
	perror("Exec of "NEWALIASES NEWALIASES_ARG" failed!");
	exit(1);
}
