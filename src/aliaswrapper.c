
#include <unistd.h>
#include <stdio.h>

int main(int argc, char *argv[])
{
	setuid(0);
	execle(NEWALIASES, NEWALIASES, NULL, NULL);
	perror("Exec of "NEWALIASES" failed!");
	exit(1);
}
