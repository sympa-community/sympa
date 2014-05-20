#include <unistd.h>

int main(int argn, char **argv, char **envp) {
    setreuid(geteuid(),geteuid());
    setregid(getegid(),getegid());
    argv[0] = SYMPASOAP;
    return execve(SYMPASOAP,argv,envp);
}
