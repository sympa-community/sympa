#include <unistd.h>

int main(int argn, char **argv, char **envp) {
    argv[0] = SYMPASOAP;
    execve(SYMPASOAP,argv,envp);
}
