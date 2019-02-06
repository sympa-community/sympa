Support scripts for maintenance of Sympa package
================================================

### correct_msgid

Corrects texts to be translated in source code according to changes in en_US
translation catalog (en_US.po).

### git-set-file-times

Sets mtime and atime of files to the latest commit time in git.

Initially taken from repository of rsync
https://git.samba.org/?p=rsync.git;a=history;f=support/git-set-file-times
at 2009-01-13, and made modifications.

### pod2md

Converts POD data to Markdown format.  This may be used as a replacement of
pod2man(1).  To generate Markdown texts of all available PODs, run:
```
make POD2MAN="POD2MDOUTPUT=directory pod2md"
```
then, generated texts will be saved in _directory_.

