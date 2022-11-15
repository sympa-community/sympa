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

### xgettext.pl

The xgettext(1) utility specific to Sympa. Typically invoked by automated
processes updating translation catalog.

How to prepare a new source tarball
===================================

Notes:

  * In below, the username associated with the Git commits should be
    "`Sympa authors <devel@sympa.community>`".

  * Currently, commits during steps 3 and 4 are automatically created
    and pushed to `translation` branch on the repository.

  1. Checkout "main" branch.
     ```
     $ git checkout sympa-6.2
     ```

  2. Tidy all sources.
     ```
     $ make tidyall
     ```

     Then commit the changes.

  3. Retrieve latest translations from translate.sympa.community.  Then
     merge it into the source, for example:
     ```
     $ cd (top)/po/sympa
     $ msgcat -o LL.ponew --use-first UPDATED/LL.po LL.po
     $ mv LL.ponew LL.po
     ```

     And optionally, if en_US.po has been updated, update messages in the
     sources according to it.
     ```
     $ cd (top)
     $ support/correct_msgid --domain=sympa
     $ support/correct_msgid --domain=web_help
     ```

     Then commit the changes.

  4. Update translation catalog.
     ```
     $ cd (top)/po/sympa; make clean sympa.pot-update update-po
     $ cd (top)/po/web_help; make clean web_help.pot-update update-po
     ```

     Then commit the changes.

  5. Prepare the new version on the repository.

     Update configure.ac (update version number) and NEWS.md.

     Then commit the changes with message "[-release] Preparing version x.x.x".

  6. Push all of the commits described in above into remote repository.

  7. Cleanup everything.
     ```
     $ cd (top)
     $ make distclean
     $ rm -Rf autom4te.cache/
     ```

     And sync with repository.
     ```
     $ git pull
     $ support/git-set-file-times
     ```

  8. Configure, create and check distribution.
     ```
     $ autoreconf -i
     $ ./configure --enable-fhs --with-confdir=/etc/sympa
     $ make distcheck
     ```

     If something went wrong, fix it, return to 6 above and try again.

  9. Upload generated files to release section:

       - sympa-VERSION.tar.gz
       - sympa-VERSION.tar.gz.md5
       - sympa-VERSION.tar.gz.sha256
       - sympa-VERSION.tar.gz.sha512
 
  10. Tag the remote repository with the new version number.
