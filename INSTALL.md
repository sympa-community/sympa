Reference manual
================
This document is only a quick start.
For detailed installation / setup information, refer to the reference manual :

  * https://www.sympa.org/manual/

Requirements
============

Sympa requires other applications to run :
  * Perl and GCC C compiler. You may have to use Gnu make
  * MTA (Sendmail, Postfix, exim and qmail supported)
  * relational database (MySQL / MariaDB, PostgreSQL, Oracle Database and
    SQLite supported)
  * web server (Apache HTTP Server, nginx or another web server)
  * FastCGI (e.g. mod_fcgid for Apache)
  * many Perl modules : they may be installed by ``sympa_wizard.pl --check``
    described below

Installing Sympa from sources
=============================

(If you get sources from git repository, first run: ``autoreconf -i``)

Create a dedicated user ``sympa``:``sympa`` (and it's home directory) and run 
```
./configure (options); make; make install
```
Then check dependent modules
```
sympa_wizard.pl --check
```
This wizard will propose that you upgrade some CPAN modules.
In this case you'll need to be root.

Some Perl modules require additionnal libraries, for example :
  - XML::LibXML requires libxml2 library and headers
  - Net::SSLeay requires openssl libraries and headers

Setup
=====

1. Sympa setup

   You can edit ``sympa.conf`` manually or run ``sympa_wizard.pl`` that will
   help you create your configuration files.

2. Syslog setup (syslogd)

   Default for Sympa is to log in 'local1' (you can configure this in
   ``sympa.conf``).
   You should add the following line to your ``syslog.conf`` file :
   ```
   local1.*	/var/log/sympa
   ```

   On Solaris (7 & 8) and True64, the '.*' level is not recognized in
   ``syslog.conf```.
   You need to enumerate levels :
   ```
   local1.info,local1.notice,local1.debug /var/log/sympa
   ```

3. Database setup (MySQL)

   Your MySQL version MUST be at least 4.1.1 in order to run correctly with
   Sympa.
   db_xxx parameters in ``sympa.conf`` refer to your local database. 

   You'll have to create dedicated database user ``sympa``,
   creata an empty database and provide access to this user.

   Then create table structure:
   ```
   sympa.pl --health_check
   ```

4. Mail aliases setup (Sendmail)

   Sympa will use a dedicated alias file for its own mail aliases, default is
   ``/etc/mail/sympa_aliases``.
   You have to configure your MTA (Sendmail, Postfix, ...) to use this file.

   You should also create the main Sympa aliases ; they will look like this :
   ```
   sympa: "| /home/sympa/bin/queue sympa@my.domain.org"
   listmaster: "| /home/sympa/bin/queue listmaster@my.domain.org"
   bounce+*: "| /home/sympa/bin/bouncequeue sympa@my.domain.org"
   sympa-request: postmaster
   sympa-owner: postmaster
   ```

   (Later mailing lists aliases will be installed automatically by Sympa)

5. Web setup (Apache)

   You should add these lines to your ``httpd.conf`` file :
   ```
   Alias /static-sympa /home/sympa/static_content 
   ScriptAlias /sympa /home/sympa/bin/wwsympa-wrapper.fcgi

   <IfModule mod_fcgid.c>
     AddHandler fcgid-script .fcgi
   </IfModule>
   ```
   To login with listmaster privileges, you should login on the web
   interface with the email address you declared in ``sympa.conf``. To get an
   initial password just hit the "First login" button.

