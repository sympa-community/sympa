%SMTPC(1)

# NAME

smtpc - SMTP / LMTP client

# SYNOPSIS

`smtpc` `--esmtp` _host_`:`_port_ `-f` _envelope_@_sen.der_
[ _options_... ] [ `--` ] _recipient_@_add.ress_ ...

`smtpc` `--lmtp` _host_`:`_port_ `-f` _envelope_@_sen.der_
[ _options_... ] [ `--` ] _recipient_@_add.ress_ ...

`smtpc` `--lmtp` _path_ `-f` _envelope_@_sen.der_
[ _options_... ] [ `--` ] _recipient_@_add.ress_ ...

# DESCRIPTION

**smtpc** is an email client.
It reads a message from standard input and submits it to email server through
socket.

## Options

Any options not listed here are silently ignored.

* `--dump`

    Show dialog in the session.

* `--esmtp` _host_[:_port_]

    Uses TCP socket and ESMTP protocol to submit message.
    Either this option or `--lmtp` option is required.

    If _host_ is the IPv6 address, it must be enclosed in [...]
    to avoid confusion with colon separating _host_ and _port_,
    e.g. "`[::1]`", "`[::1]:587`".
    If _port_ is omitted, "25" is used.

* `-f` _envelope_@_sen.der_, `-f`_envelope_@_sen.der_

    Specifies envelope sender.
    This option is required.

    To specify "null envelope sender", use a separate empty argument or "`<>`".

* `--iam` _host.name_

    Specifies host name or IP address literal used in EHLO or LHLO request.
    Default is "`localhost`".

* `--lmtp` _host_[:_port_], `--lmtp` _path_

    Uses TCP or Unix domain socket and LMTP protocol to submit message.
    Either this option or `--esmtp` option is required.

    If _port_ is omitted, "24" is used.
    _path_ must be full path to socket file.

* `-N` _dsn_, `-N`_dsn_

    Controls delivery status notification.
    _dsn_ may be single word "`NEVER`" or one or more of words "`SUCCESS`",
    "`FAILURE`" and "`DELAY`" separated by comma.

    If this option is not given, delivery status notification will be controlled
    by server.

* `--smtputf8`

    Enables support for SMTPUTF8 extension.
    **smtpc** detects valid UTF-8 sequence in envelope and message header,
    then requests this extension as necessity.

* `-V` _envid_, `-V`_envid_

    Specifies envelope ID.

* `--verbose`

    Output the last response from the server to standard output.

* `--`

    Terminates options.
    Remainder of command line arguments are considered to be recipient
    addresses, even if any of them begin with "`-`".

* _recipient_@_add.ress_ ...

    Recipients to whom the message would be delivered.
    At least one recipient is required.

## Exit status

* `0`

    Message was successfully submitted.

* `253`

    Message was rejected by server.

* `254`

    The server returns malformed or illegal response.

* `255`

    Network error occurred.

## SMTP extensions

**smtpc** supports following extensions.

* **8-bit MIME Transport** (RFC 6152)

    **smtpc** requests this extension if message contains octets with high bit.

* **Delivery Status Notification** (RFC 3461)

    **smtpc** issues ORCPT parameters.
    See also `-N` and `-V` options.

* **Internationalized Email** (RFC 6531)

    Experimentally supported.
    See `--smtputf8` option.

* **Message Size Declaration** (RFC 1870)

    Estimated size of the message is informed to the server.

# LIMITATIONS

**smtpc** provides the feature of SMTP / LMTP client submitting messages
to particular server.
It will never provide extensive features such as message queuing, retry after
temporary failure, routing using MX DNS record and so on.
Once the server rejects delivery, **smtpc** exits and message is discarded.

# KNOWN BUGS

  * If NUL octets (\\0) are included in messages, they are transmitted to the
    server.

# SEE ALSO

sendmail(1)

# HISTORY

**smtpc** was initially written for Sympa project by
IKEDA Soji <ikeda@conversion.co.jp>.

