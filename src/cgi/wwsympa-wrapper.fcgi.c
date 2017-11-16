/* This file is part of Sympa, see top-level README.md file for details */

#include <unistd.h>

int main(int argn, char **argv, char **envp) {
    setreuid(geteuid(),geteuid()); // Added to fix the segfault
    setregid(getegid(),getegid()); // Added to fix the segfault
    argv[0] = WWSYMPA;
    return execve(WWSYMPA,argv,envp);
}
