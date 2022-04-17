Files to support service management
===================================

SysVinit
--------

  * sympa

    Generic init script for the system derived from System V.

Systemd
-------

  * sympa-archive.service
  * sympa-bounce.service
  * sympa-outgoing.service
  * sympa-task.service
  * sympa.service

    Units for Sympa services.  Copy these files into Systemd system directory.

  * sympa-tmpfiles.conf

    Definition of ephemeral directory.

  * wwsympa-multiwatch.service
  * wwsympa-multiwatch.socket
  * sympasoap-multiwatch.service
  * sympasoap-multiwatch.socket

    Units for WWSympa and SympaSOAP, using multiwatch.  Copy these files as
    `wwsympa.service`, `wwsympa.socket` and so on into Systemd system
    directory.

  * wwsympa-spawn-fcgi.service
  * sympasoap-spawn-fcgi.service

    Units for WWSympa and SympaSOAP, using spawn-fcgi.  Copy these files as
    `wwsympa.service`, `wwsympa.socket` and so on into Systemd system
    directory.


