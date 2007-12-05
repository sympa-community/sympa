#include <unistd.h>

int main(int argn, char **argv, char **envp) {
    argv[0] = WWSYMPA;
    execve(WWSYMPA,argv,envp);
}
