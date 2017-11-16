/* This file is part of Sympa, see top-level README.md file for details */

#include <unistd.h>

int main(int argn, char **argv, char **envp) {
    setreuid(geteuid(),geteuid());
    setregid(getegid(),getegid());
    argv[0] = SYMPASOAP;
    return execve(SYMPASOAP,argv,envp);
}
