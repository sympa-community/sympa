%define name    sympa
%define version 6.0a.13
%define release 1

Name:     %{name}
Version:  %{version}
Release:  %{release}
Summary:  Sympa is a powerful multilingual List Manager
Summary(fr): Sympa est un gestionnaire de listes électroniques
License:  GPL
Group:    System Environment/Daemons
URL:      http://www.sympa.org/
Source:   http://www.sympa.org/distribution/%{name}-%{version}.tar.gz
Requires: smtpdaemon
Requires: perl >= 0:5.005
Requires: perl-MailTools >= 1.14
Requires: perl-MIME-Base64   >= 1.0
Requires: perl-IO-stringy    >= 1.0
Requires: perl-MIME-tools    >= 5.209
Requires: perl-CGI    >= 2.52
Requires: perl-DBI    >= 1.06
Requires: perl-DB_File    >= 1.73
Requires: perl-ldap >= 0.10
Requires: perl-CipherSaber >= 0.50
Requires: perl-FCGI    >= 0.48
Requires: perl-Digest-MD5
Requires: perl-Convert-ASN1
Requires: perl-HTML-Parser
Requires: perl-HTML-Tagset
Requires: perl-IO-Socket-SSL
Requires: perl-URI
Requires: perl-libwww-perl
Requires: MHonArc >= 2.4.6
Requires: webserver
Requires: openssl >= 0.9.5a
Prereq: /usr/sbin/useradd
Prereq: /usr/sbin/groupadd
BuildRoot: %{_tmppath}/%{name}-%{version}

%description
Sympa is scalable and highly customizable mailing list manager. It can cope
with big lists (200,000 subscribers) and comes with a complete (user and admin)
Web interface. It is internationalized, and supports the us, fr, de, es, it,
fi, and chinese locales. A scripting language allows you to extend the behavior
of commands. Sympa can be linked to an LDAP directory or an RDBMS to create
dynamic mailing lists. Sympa provides S/MIME-based authentication and
encryption.

%prep
%setup -q

%build
./configure \
    --prefix=%{_prefix} \
    --sysconfdir=%{_sysconfdir} \
    --localstatedir=%{_localstatedir}
make

%install
rm -rf %{buildroot}
make install DESTDIR=%{buildroot}

%clean
rm -rf %{buildroot}

%pre
# Create "sympa" group if it does not exists
if ! getent group sympa > /dev/null 2>&1; then
  /usr/sbin/groupadd sympa
fi

# Create "sympa" user if it does not exists
if ! getent user sympa > /dev/null 2>&1; then
  /usr/sbin/useradd -r -g sympa \
      -d %{_localstatedir}/lib/sympa \
      -c "system user for sympa" \
      -s "/bin/bash"
fi

%files
%defattr(-,root,root)
%doc README README.charset NEWS COPYING AUTHORS doc/sample
%attr(-,sympa,sympa) %{_localstatedir}/lib/sympa
%attr(-,sympa,sympa) %{_localstatedir}/spool/sympa
%{_sbindir}/*
%{_libdir}/sympa
%{_mandir}/man8/*
%{_datadir}/sympa
%{_datadir}/locale/*/*/*
%config(noreplace) %{_sysconfdir}/sympa.conf
