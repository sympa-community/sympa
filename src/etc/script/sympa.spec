%define name sympa
%define version --VERSION--
%define release 5--SUFFIX--
%define home_s --HOMEDIR--

Summary:  Sympa is a powerful multilingual List Manager - LDAP and SQL features.
Summary(fr): Sympa est un gestionnaire de listes électroniques. 
Name:  %{name}
Version:  %{version}
Release:  %{release}
Copyright:  GPL
Group: --APPGROUP--
Source:  http://listes.cru.fr/sympa/distribution/%{name}-%{version}.tar.--ZIPEXT--
URL: http://listes.cru.fr/sympa/
Requires: perl >= 5.00403
Requires: perl-MailTools >= 1.14
Requires: perl-MIME-Base64   >= 1.0
Requires: perl-IO-stringy    >= 1.0
Requires: perl-Msgcat        >= 1.03
Requires: perl-MIME-tools    >= 5.209
Requires: perl-CGI    >= 2.52
Requires: perl-DBI    >= 1.06
Requires: perl-DB_File    >= 1.0
Requires: perl-perl-ldap >= 0.10
## Also requires a DBD for the DBMS 
## (perl-DBD-Pg or Perl- Msql-Mysql-modules)
Requires: perl-FCGI    >= 0.48
Requires: MHonArc >= 2.4.6
Requires: apache
Requires: openssl >= 0.9.5a
Prereq: /usr/sbin/useradd
Prereq: /usr/sbin/groupadd
BuildRoot: %{_tmppath}/%{name}-%{version}
Prefix: %{_prefix}

%description
Sympa is scalable and highly customizable mailing list manager. It can cope with big lists
(100,000 subscribers) and comes with a complete (user and admin) Web interface. It is
internationalized, and supports the us, fr, de, es, it, fi, and chinese locales. A scripting
language allows you to extend the behavior of commands. Sympa can be linked to an
LDAP directory or an RDBMS to create dynamic mailing lists. Sympa provides
S/MIME-based authentication and encryption.

Documentation is available under HTML and Latex (source) formats. 


%prep
rm -rf $RPM_BUILD_ROOT

%setup -q

%build

make DIR=%{home_s} sources languages

%install
rm -rf $RPM_BUILD_ROOT

make INITDIR=/etc/rc.d/init.d HOST=MYHOST DIR=%{home_s} DESTDIR=$RPM_BUILD_ROOT MANDIR=%{man_dir} install

## Setting Runlevels
for I in 0 1 2 6; do
        mkdir -p $RPM_BUILD_ROOT/etc/rc.d/rc$I.d
        ln -s /etc/rc.d/init.d/%{name} $RPM_BUILD_ROOT/etc/rc.d/rc$I.d/K25%{name}
done
for I in 3 5; do
        mkdir -p $RPM_BUILD_ROOT/etc/rc.d/rc$I.d
        ln -s /etc/rc.d/init.d/%{name} $RPM_BUILD_ROOT/etc/rc.d/rc$I.d/S95%{name}
done

#echo "See README and INSTALL in %{prefix}/doc/%{name}-%{version}" > $RPM_BUILD_ROOT%{home_s}/README.first

%pre
# Try to add user and group 'sympa'
home_s_pw=`cat /etc/passwd|grep "^sympa:" \
           | sed -e "s=^sympa:[^:]*:[^:]*:[^:]*:[^:]*:\([^:]*\):.*=\1="`
if [ "x${home_s_pw}" = "x" ]; then
  /usr/sbin/groupadd -f sympa || :
  /usr/sbin/useradd -s /bin/false -d %{home_s} -m -g sympa -c "Sympa mailing list" sympa || :
elif [ "${home_s_pw}" != "%{home_s}" ]; then
  echo "user sympa already exist with a home different from %{home_s}"
  exit 0
fi

# Setup log facility for Sympa
if [ -f /etc/syslog.conf ] ;then
  if [ `grep -c sympa /etc/syslog.conf` -eq 0 ] ;then
    typeset -i cntlog
    cntlog=0
    while [ `grep -c local${cntlog} /etc/syslog.conf` -gt 0 ];do cntlog=${cntlog}+1;done
    if [ ${cntlog} -le 9 ];then
      echo "# added by %{name}-%{version} rpm $(date)" >> /etc/syslog.conf
      echo "local${cntlog}.*       /var/log/%{name}" >> /etc/syslog.conf
    fi    
  fi
fi

# try to add some sample entries in /etc/aliases for sympa
for a_file in /etc/aliases /etc/postfix/aliases; do
  if [ -f ${a_file} ]; then
    if [ `grep -c sympa ${a_file}` -eq 0 ]; then
      cp -f ${a_file} ${a_file}.rpmorig
      echo >> ${a_file}
      echo "# added by %{name}-%{version} rpm "$(date) >> ${a_file}
      if [ `grep -c listmaster ${a_file}` -eq 0 ]; then
        echo "# listmaster:     root" >> ${a_file}
      fi
      echo "# sympa: \"|%{home_s}/bin/queue 0 sympa\"" >> ${a_file}
      echo "# sympa-request:  listmaster@${HOSTNAME}" >> ${a_file}
      echo "# sympa-owner:    listmaster@${HOSTNAME}" >> ${a_file}
      echo "" >> ${a_file}
#     /usr/bin/newaliases
    fi  
  fi
done  

# eventually, add queue to sendmail security shell
if [ -d /etc/smrsh ]; then
  if [ ! -e /etc/smrsh/queue ]; then
    ln -s %{home_s}/bin/queue /etc/smrsh/queue
  fi
fi

%post
perl -pi -e "s|MYHOST|${HOSTNAME}|g" /etc/sympa.conf /etc/wwsympa.conf

%postun
if [ ! -d %{home_s} ]; then
  /usr/sbin/userdel sympa
  /usr/sbin/groupdel sympa  
fi
if [ $1 = 0 -a -d /etc/smrsh ]; then
  if [ -L /etc/smrsh/queue ]; then
    rm -f /etc/smrsh/queue
  fi
fi


%files

%defattr(0755,sympa,sympa)
%dir %{home_s}
%dir %{home_s}/bin
%dir %{home_s}/bin/Marc
%dir %{home_s}/bin/etc
%dir %{home_s}/sample
%dir %{home_s}/expl
%dir %{home_s}/spool
%dir %{home_s}/nls
%dir %{home_s}/etc

%defattr(0744,sympa,sympa)
%dir %{home_s}/spool/*

%defattr(-,sympa,sympa)
%{home_s}/sample/*
%{home_s}/bin/Marc/*
%{home_s}/bin/etc/*
%{home_s}/expl/*

%attr(0755,root,root)%dir /home/httpd/icons
%attr(0644,root,root) /home/httpd/icons/*

%defattr(-,sympa,sympa)
%{home_s}/bin/*.pm
%{home_s}/bin/*.pl
%{home_s}/bin/create_db.*
%{home_s}/bin/wwsympa.fcgi

%attr(4755,sympa,sympa) %{home_s}/bin/queue
%attr(4755,sympa,sympa) %{home_s}/bin/bouncequeue
%attr(4755,sympa,sympa) %{home_s}/bin/aliaswrapper


%{home_s}/nls/*.cat

%defattr(0600,sympa,sympa)
%config(noreplace) /etc/sympa.conf 
%config(noreplace) /etc/wwsympa.conf
%defattr(0755,root,root)
%config(noreplace) /etc/rc.d/init.d/%{name}
%config /etc/rc.d/rc*/*

%defattr(-,root,root)
%doc INSTALL LICENSE README RELEASE_NOTES
%doc doc/*

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Thu Jun  5 2001 Olivier Salaun <olivier.salaun@cru.fr> 3.2
- perl-CGI.pm becomes perl-CGI

* Thu Feb  8 2001 Olivier Salaun <olivier.salaun@cru.fr> 3.1b.3
- Requires MHOnArc 2.4.6

* Tue Nov 21 2000 Olivier Salaun <olivier.salaun@cru.fr> 3.0b
- Requires perl-DB_File and perl-perl-ldap
- Set sympa user shell to /bin/false 
- Directories (etc expl spool) now created by sympa

* Wed Sep 06 2000 Olivier Salaun <olivier.salaun@cru.fr> 3.0a
- No more nls/ in docs
- generalize %{home_s}
- use DESTDIR
- changed the description ; french version abandoned
- sample conf files now installed by Makefile
- no more patches (Openssl, Mhonarc)
- set correct right in %files
- use $RPM_SOURCE_DIR
- install SYSV init script
- openssl-devel NOT required

* Wed Aug 30 2000 Geoffrey Lee <snailtalk@mandrakesoft.com> 2.7.3-5mdk
- requires apache because of wwsympa.
- buildrequires apache to fix building for machines without apache (sic).

* Fri Aug 18 2000 Geoffrey Lee <snailtalk@mandrakesoft.com> 2.7.3-4mdk
- rebuild to enable openssl.
- add requires and buildrequires for {openssl,openssl-devel}
- copy the wwsympa configuration file on postun if none is present in /etc.

* Thu Aug 17 2000 Geoffrey Lee <snailtalk@mandrakesoft.com> 2.7.3-3mdk
- rebuild to fix some more annoying bugs.

* Mon Aug 14 2000 Geoffrey Lee <snailtalk@mandrakesoft.com> 2.7.3-2mdk
- rebuild for sympa disaster

* Tue Aug 01 2000 Geoffrey Lee <snailtalk@mandrakesoft.com> 2.7.3-1mdk
- big shiny new version and got this ugly fucking piece of shit to package
- rebuild for BM

* Tue Apr 18 2000 Jerome Dumonteil <jd@mandrakesoft.com>
- change group
* Fri Mar 31 2000 Jerome Dumonteil <jd@mandrakesoft.com>
- change group
- modif postun
* Wed Dec 29 1999 Jerome Dumonteil <jd@mandrakesoft.com>
- version 2.4
* Fri Dec 17 1999 Jerome Dumonteil <jd@mandrakesoft.com>
- added link /etc/smrsh/queue
- added link for /home/sympa/expl/helpfile
* Thu Dec 09 1999 Jerome Dumonteil <jd@mandrakesoft.com>
- remove backup files from sources
- strip binary
* Mon Dec  6 1999 Jerome Dumonteil <jd@mandrakesoft.com>
- added prereq info.
- little cleanup.
* Fri Dec  3 1999 Jerome Dumonteil <jd@mandrakesoft.com>
- first version of rpm.

