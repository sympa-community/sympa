/* $Id$ */
/*
 * Sympa - SYsteme de Multi-Postage Automatique
 *
 * Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
 * Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
 * 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
 * Copyright (c) 2011, 2012, 2013, 2014, 2015 GIP RENATER
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/*
 * smtpc was originally written by IKEDA Soji <ikeda@conversion.co.jp>
 * for Sympa project.
 *
 * 2015-05-17 IKEDA Soji: Initial checkin to source repository.
 */

#include "config.h"
#include <signal.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <sysexits.h>
#include "sockstr.h"
#include "utf8.h"

#define SMTPC_BUFSIZ (8192)

#define SMTPC_ERR_SOCKET (-1)
#define SMTPC_ERR_PROTOCOL (-2)
#define SMTPC_ERR_SUBMISSION (-3)
#define SMTPC_ERR_UNKNOWN (-4)

#define SMTPC_7BIT (0)
#define SMTPC_8BIT (1)
#define SMTPC_UTF8 (2)

#define SMTPC_PROTO_ESMTP (1)
#define SMTPC_PROTO_LMTP (1 << 1)

#define SMTPC_EXT_8BITMIME (1)
#define SMTPC_EXT_AUTH (1 << 1)
#define SMTPC_EXT_DSN (1 << 2)
#define SMTPC_EXT_PIPELINING (1 << 3)
#define SMTPC_EXT_SIZE (1 << 4)
#define SMTPC_EXT_SMTPUTF8 (1 << 5)
#define SMTPC_EXT_STARTTLS (1 << 6)

#define SMTPC_NOTIFY_NEVER (1)
#define SMTPC_NOTIFY_SUCCESS (1 << 1)
#define SMTPC_NOTIFY_FAILURE (1 << 2)
#define SMTPC_NOTIFY_DELAY (1 << 3)

static char buf[SMTPC_BUFSIZ];
static sockstr_t *sockstr;

static struct {
    int dump;
    int verbose;
    unsigned int protocol;
    char *myname;
    char *nodename;
    char *servname;
    char *path;
    char *sender;
    unsigned int notify;
    char *envid;
    int smtputf8;
} options = {
0, 0, 0, NULL, NULL, NULL, NULL, NULL, 0, NULL, 0};

static struct {
    char **recips;
    int recipnum;
    char *buf;
    size_t buflen;
    size_t size;
    int envfeature;
    int headfeature;
    int bodyfeature;
} message = {
NULL, 0, NULL, 0, 0, 0, 0};

static struct {
    char *buf;
    size_t buflen;
    unsigned long extensions;
} server = {
NULL, 0, 0};

static char *encode_xtext(unsigned char *str)
{
    unsigned char *p;
    char *encbuf, *q;
    size_t enclen = 0;

    p = str;
    while (*p != '\0') {
	if (*p == '+' || *p == '=')
	    enclen += 3;
	else if (33 <= *p && *p <= 126)
	    enclen++;
	else
	    enclen += 3;
	p++;
    }

    encbuf = malloc(enclen + 1);
    if (encbuf == NULL)
	return NULL;

    p = str;
    q = encbuf;
    while (*p != '\0') {
	if (*p == '+' || *p == '=')
	    q += sprintf(q, "+%02X", (unsigned int) *p);
	else if (33 <= *p && *p <= 126)
	    *q++ = *p;
	else
	    q += sprintf(q, "+%02X", (unsigned int) *p);
	p++;
    }
    *q = '\0';

    return encbuf;
}

static int parse_options(int *argcptr, char ***argvptr)
{
    int argc = *argcptr;
    char **argv = *argvptr;

    size_t i;
    char *arg, *p;

    options.dump = 0;
    options.verbose = 0;
    options.protocol = 0;
    options.myname = "localhost";
    options.nodename = NULL;
    options.servname = "25";
    options.sender = NULL;
    options.notify = 0;
    options.envid = NULL;
    options.smtputf8 = 0;

    for (i = 1; i < argc && argv[i] != NULL; i++) {
	arg = argv[i];

	if (arg[0] != '-')
	    break;
	else if (arg[0] == '-' && arg[1] == '-') {
	    if (arg[2] == '\0') {
		i++;
		break;
	    } else if (strcmp(arg, "--dump") == 0)
		options.dump++;
	    else if (strcmp(arg, "--esmtp") == 0 && i + 1 < argc) {
		if (options.protocol != 0) {
		    fprintf(stderr, "Multiple servers are specified\n");
		    return -1;
		}
		options.protocol = SMTPC_PROTO_ESMTP;
		arg = argv[++i];
		if (arg[0] == '[') {
		    p = options.nodename = arg + 1;
		    while (*p != '\0' && *p != ']')
			p++;
		    if (*p == ']' && options.nodename < p)
			*p++ = '\0';
		    else {
			fprintf(stderr, "Malformed host \"%s\"\n", arg);
			return -1;
		    }

		    if (*p == ':' && ++p != '\0')
			options.servname = p;
		    else if (*p != '\0') {
			fprintf(stderr, "Malformed port \"%s\"\n", p);
			return -1;
		    }
		} else {
		    p = options.nodename = arg;
		    while (*p != '\0' && *p != ':')
			p++;
		    if (*p == ':' && options.nodename < p)
			*p++ = '\0';

		    if (*p != '\0')
			options.servname = p;
		}
	    } else if (strcmp(arg, "--iam") == 0 && i + 1 < argc)
		options.myname = argv[++i];
	    else if (strcmp(arg, "--lmtp") == 0 && i + 1 < argc) {
		if (options.protocol != 0) {
		    fprintf(stderr, "Multiple servers are specified\n");
		    return -1;
		}
		options.protocol = SMTPC_PROTO_LMTP;
		options.path = argv[++i];
	    } else if (strcmp(arg, "--smtputf8") == 0)
		options.smtputf8 = 1;
	    else if (strcmp(arg, "--verbose") == 0)
		options.verbose++;
	}

	switch (arg[1]) {
	case 'f':
	    if (options.sender != NULL) {
		fprintf(stderr, "Multiple senders are specified\n");
		return -1;
	    }
	    if (arg[2] == '\0' && i + 1 < argc)
		options.sender = argv[++i];
	    else if (arg[2] != '\0')
		options.sender = arg + 2;
	    else
		goto parse_options_novalue;

	    if (strcmp(options.sender, "<>") == 0)
		options.sender += 2;

	    break;

	case 'N':
	    if (arg[2] == '\0' && i + 1 < argc)
		p = argv[++i];
	    else if (arg[2] != '\0')
		p = arg + 2;
	    else
		goto parse_options_novalue;

	    while (*p != '\0') {
		char word[29], *wp;

		wp = word;
		while (*p == '\t' || *p == ' ' || *p == ',')
		    p++;
		if (*p == '\0')
		    break;

		while (*p != '\0' && *p != '\t' && *p != ' ' && *p != ','
		       && wp - word + 1 < sizeof(word))
		    if ('a' <= *p && *p <= 'z')
			*wp++ = *p++ + ('A' - 'a');
		    else
			*wp++ = *p++;
		*wp = '\0';

		if (strcmp(word, "NEVER") == 0) {
		    options.notify |= SMTPC_NOTIFY_NEVER;
		} else if (strcmp(word, "SUCCESS") == 0)
		    options.notify |= SMTPC_NOTIFY_SUCCESS;
		else if (strcmp(word, "FAILURE") == 0)
		    options.notify |= SMTPC_NOTIFY_FAILURE;
		else if (strcmp(word, "DELAY") == 0)
		    options.notify |= SMTPC_NOTIFY_DELAY;
		else {
		    fprintf(stderr, "Unknown NOTIFY keyword \"%s\"\n",
			    word);
		    return -1;
		}

		if (options.notify & SMTPC_NOTIFY_NEVER &&
		    options.notify & ~SMTPC_NOTIFY_NEVER) {
		    fprintf(stderr,
			    "NEVER keyword must not appear with other keywords\n");
		    return -1;
		}
	    }
	    break;

	case 'V':
	    if (arg[2] == '\0' && i + 1 < argc)
		options.envid = argv[++i];
	    else if (arg[2] != '\0')
		options.envid = arg + 2;
	    else
		goto parse_options_novalue;

	    p = options.envid;
	    while (*p != '\0')
		if (32 <= *p && *p <= 126)
		    p++;
		else {
		    fprintf(stderr,
			    "ENVID contains illegal character \\x%02X\n",
			    *p);
		    return -1;
		}

	    break;

	default:
	    break;

	  parse_options_novalue:
	    fprintf(stderr, "No value for option \"%s\"\n", arg);
	    return -1;
	}
    }

    if ((options.protocol & (SMTPC_PROTO_ESMTP | SMTPC_PROTO_LMTP)) == 0) {
	fprintf(stderr, "Either --esmtp or --lmtp option must be given\n");
	return -1;
    }
    if (options.protocol & SMTPC_PROTO_ESMTP && options.nodename == NULL
	|| options.protocol & SMTPC_PROTO_LMTP && options.path == NULL) {
	fprintf(stderr, "Nodename nor path is not specified\n");
	return -1;
    }
    if (options.sender == NULL) {
	fprintf(stderr, "Envelope sender is not specified\n");
	return -1;
    }

    *argcptr -= i;
    *argvptr += i;

    return 0;
}

static int check_utf8_address(char *addrbuf)
{
    size_t len;
    ssize_t rs;

    len = strlen(addrbuf);
    if (len == 0)
	return SMTPC_7BIT;

    rs = utf8_check((unsigned char *) addrbuf, len);
    if (rs < 0)
	return SMTPC_7BIT;
    else if (rs < len)
	return SMTPC_8BIT;
    else
	return SMTPC_UTF8;
}

static int read_envelope(char *sender, size_t recipnum, char **recips)
{
    char **pp, **end;

    if (recipnum <= 0) {
	fprintf(stderr, "No recipients are specified\n");
	return -1;
    }

    message.recipnum = recipnum;
    message.recips = recips;

    /*
     * Check feature of sender.
     */
    message.envfeature = check_utf8_address(sender);

    /*
     * Check feature of recipients.
     */
    end = recips + recipnum;
    for (pp = recips;
	 message.envfeature != SMTPC_8BIT && pp < end && *pp != NULL; pp++)
	switch (check_utf8_address(*pp)) {
	case SMTPC_8BIT:
	    message.envfeature = SMTPC_8BIT;
	    break;
	case SMTPC_UTF8:
	    message.envfeature = SMTPC_UTF8;
	    break;
	default:
	    break;
	}

    return 0;
}

static ssize_t read_message(void)
{
    size_t cr;
    ssize_t rs;
    char *newbuf, *p, *end;

    while (1) {
	rs = fread(buf, 1, SMTPC_BUFSIZ, stdin);
	if (rs == 0)
	    break;

	if (message.buf == NULL) {
	    message.buf = malloc(rs + 1);
	    if (message.buf == NULL)
		return -1;
	} else {
	    newbuf = realloc(message.buf, message.buflen + rs + 1);
	    if (newbuf == NULL)
		return -1;
	    message.buf = newbuf;
	}
	memcpy(message.buf + message.buflen, buf, rs);
	message.buflen += rs;
	message.buf[message.buflen] = '\0';

	if (rs < SMTPC_BUFSIZ)
	    break;
    }
    if (feof(stdin)) {
	if (fclose(stdin) != 0)
	    return -1;
    } else {
	fclose(stdin);
	return -1;
    }

    /*
     * Check message features:
     * - Feature of message header.
     * - Feature of message body.
     * - Estimated size of the message considering newlines.
     */

    cr = 0;
    message.headfeature = SMTPC_7BIT;
    message.bodyfeature = SMTPC_7BIT;
    if (0 < message.buflen) {
	end = message.buf + message.buflen;

	for (p = message.buf; p < end; p++)
	    if (*p == '\n') {
		if (p == message.buf || p[-1] != '\r')
		    cr++;

		if (p[1] == '\n' || p[1] == '\r' && p[2] == '\n') {
		    p++;
		    break;
		}
	    }
	rs = utf8_check((unsigned char *) message.buf, p - message.buf);
	if (rs < 0)
	    message.headfeature = SMTPC_7BIT;
	else if (rs < p - message.buf)
	    message.headfeature = SMTPC_8BIT;
	else
	    message.headfeature = SMTPC_UTF8;

	for (; p < end; p++)
	    if (*p & 0x80) {
		message.bodyfeature = SMTPC_8BIT;
		p++;
		break;
	    } else if (*p == '\n' && p[-1] != '\r')
		cr++;
	for (; p < end; p++)
	    if (*p == '\n' && p[-1] != '\r')
		cr++;

	if (end[-1] == '\r')
	    cr++;
	else if (end[-1] != '\n')
	    cr += 2;
    } else
	cr = 2;
    message.size = message.buflen + cr;

    return message.buflen;
}

static int dialog(int timeout, const char *format, ...)
{
    va_list ap;
    ssize_t rs;

    sockstr->timeout = timeout;

    if (format != NULL && *format != '\0') {
	if (options.dump) {
	    fprintf(stderr, "C: ");
	    va_start(ap, format);
	    vfprintf(stderr, format, ap);
	    va_end(ap);
	}
	va_start(ap, format);
	rs = sockstr_vprintf(sockstr, format, ap);
	va_end(ap);
	if (rs < 0)
	    return -1;
    }

    rs = sockstr_getstatus(sockstr, &server.buf, &server.buflen);
    if (rs <= 0)
	return -1;

    if (options.dump)
	fprintf(stderr, "%s", server.buf);
    return server.buf[0];
}

static int datasend(int timeout)
{
    ssize_t rs;

    sockstr->timeout = timeout;

    if (options.dump)
	fprintf(stderr, "C: (MESSAGE)\r\nC: .\r\n");
    if (sockstr_putdata
	(sockstr, message.buf, message.buflen, ".\r\n", 1, 1) < 0)
	return -1;

    rs = sockstr_getstatus(sockstr, &server.buf, &server.buflen);
    if (rs <= 0)
	return -1;

    if (options.dump)
	fprintf(stderr, "%s", server.buf);
    return server.buf[0];
}

static void parse_extensions(void)
{
    char *p = server.buf;
    unsigned long extensions = 0L;
    char word[512], *wp;

    while (*p != '\n' && *p != '\0')
	p++;
    if (*p == '\n')
	p++;
    while (*p != '\0') {
	if (p[0] && p[1] && p[2] && p[3]) {
	    p += 4;
	    while (*p == '\t' || *p == ' ' || *p == '-')
		p++;
	    if (*p == '\0')
		break;

	    wp = word;
	    while (wp - word + 1 < sizeof(word) &&
		   (*p == '-' || '0' <= *p && *p <= '9' ||
		    'A' <= *p && *p <= 'Z' || 'a' <= *p && *p <= 'z'))
		if ('a' <= *p && *p <= 'z')
		    *wp++ = *p++ + ('A' - 'a');
		else
		    *wp++ = *p++;
	    *wp = '\0';
	    if (strcmp(word, "8BITMIME") == 0)
		extensions |= SMTPC_EXT_8BITMIME;
	    else if (strcmp(word, "AUTH") == 0)
		extensions |= SMTPC_EXT_AUTH;
	    else if (strcmp(word, "DSN") == 0)
		extensions |= SMTPC_EXT_DSN;
	    else if (strcmp(word, "PIPELINING") == 0)
		extensions |= SMTPC_EXT_PIPELINING;
	    else if (strcmp(word, "SIZE") == 0)
		extensions |= SMTPC_EXT_SIZE;
	    else if (strcmp(word, "SMTPUTF8") == 0)
		extensions |= SMTPC_EXT_SMTPUTF8;
	    else if (strcmp(word, "STARTTLS") == 0)
		extensions |= SMTPC_EXT_STARTTLS;
	}

	while (*p != '\n' && *p != '\0')
	    p++;
	if (*p == '\n')
	    p++;
    }

    server.extensions = extensions;
}

static ssize_t transaction(void)
{
    ssize_t sent = 0;
    char *hello;
    char *ext_8bitmime, ext_envid[108], ext_notify[37], ext_size[27],
	*ext_smtputf8;
    int i;

    ext_8bitmime = "";
    *ext_envid = '\0';
    *ext_notify = '\0';
    *ext_size = '\0';
    ext_smtputf8 = "";

    if (options.protocol & SMTPC_PROTO_ESMTP)
	hello = "EHLO";
    else if (options.protocol & SMTPC_PROTO_LMTP)
	hello = "LHLO";
    else
	return SMTPC_ERR_UNKNOWN;
    switch (dialog(300, "%s %s\r\n", hello, options.myname)) {
    case '2':
	break;
    case '4':
    case '5':
	return 0;
    case -1:
	return SMTPC_ERR_SOCKET;
    default:
	return SMTPC_ERR_PROTOCOL;
    }
    parse_extensions();

    if (server.extensions & SMTPC_EXT_8BITMIME &&
	(message.headfeature != SMTPC_7BIT
	 || message.bodyfeature != SMTPC_7BIT))
	ext_8bitmime = " BODY=8BITMIME";

    if (server.extensions & SMTPC_EXT_DSN) {
	if (options.envid != NULL && options.envid[0] != '\0') {
	    char *encbuf;

	    encbuf = encode_xtext((unsigned char *) options.envid);
	    if (encbuf == NULL) {
		perror("transaction");
		return SMTPC_ERR_UNKNOWN;
	    }
	    snprintf(ext_envid, sizeof(ext_envid), " ENVID=%s", encbuf);
	    free(encbuf);
	}

	if (options.notify) {
	    unsigned int mask;

	    for (mask = 1; mask < (1 << 4); mask <<= 1) {
		if (options.notify & mask) {
		    if (*ext_notify == '\0')
			strcat(ext_notify, " NOTIFY=");
		    else
			strcat(ext_notify, ",");

		    switch (mask) {
		    case SMTPC_NOTIFY_NEVER:
			strcat(ext_notify, "NEVER");
			break;
		    case SMTPC_NOTIFY_SUCCESS:
			strcat(ext_notify, "SUCCESS");
			break;
		    case SMTPC_NOTIFY_FAILURE:
			strcat(ext_notify, "FAILURE");
			break;
		    case SMTPC_NOTIFY_DELAY:
			strcat(ext_notify, "DELAY");
			break;
		    }
		}
	    }			/* for (mask ...) */
	}			/* if (options.notify & mask) */
    }

    if (server.extensions & SMTPC_EXT_SIZE)
	snprintf(ext_size, sizeof(ext_size), " SIZE=%lu",
		 (unsigned long) message.size);

    if (server.extensions & SMTPC_EXT_SMTPUTF8 &&
	options.smtputf8 &&
	(message.envfeature == SMTPC_UTF8
	 && message.headfeature != SMTPC_8BIT
	 || message.envfeature != SMTPC_8BIT
	 && message.headfeature == SMTPC_UTF8))
	ext_smtputf8 = " SMTPUTF8";

    switch (dialog(300, "MAIL FROM:<%s>%s%s%s%s\r\n", options.sender,
		   ext_8bitmime, ext_envid, ext_size, ext_smtputf8)) {
    case '2':
	break;
    case '4':
    case '5':
	return 0;
    case -1:
	return SMTPC_ERR_SOCKET;
    default:
	return SMTPC_ERR_PROTOCOL;
    }

    for (i = 0; i < message.recipnum; i++)
	switch (dialog
		(300, "RCPT TO:<%s>%s\r\n", message.recips[i],
		 ext_notify)) {
	case '2':
	    sent++;
	    break;
	case '4':
	case '5':
	    return 0;
	case -1:
	    return SMTPC_ERR_SOCKET;
	default:
	    return SMTPC_ERR_PROTOCOL;
	}

    switch (dialog(120, "DATA\r\n")) {
    case '3':
	break;
    case '4':
    case '5':
	return 0;
    case -1:
	return SMTPC_ERR_SOCKET;
    default:
	return SMTPC_ERR_PROTOCOL;
    }

    switch (datasend(600)) {
    case '2':
	return sent;
    case '5':
	return 0;
    case -1:
	return SMTPC_ERR_SOCKET;
    default:
	return SMTPC_ERR_PROTOCOL;
    }
}

static ssize_t session()
{
    ssize_t rs;

    switch (dialog(300, NULL)) {
    case '2':
	break;
    case '4':
    case '5':
	return SMTPC_ERR_SUBMISSION;
    case -1:
	return SMTPC_ERR_SOCKET;
    default:
	return SMTPC_ERR_PROTOCOL;
    }

    rs = transaction();
    if (rs == 0)
	return SMTPC_ERR_SUBMISSION;
    return rs;
}

int main(int argc, char *argv[])
{
    ssize_t rs;

    if (parse_options(&argc, &argv) < 0)
	exit(EX_USAGE);
    if (read_envelope(options.sender, argc, argv) < 0)
	exit(EX_USAGE);
    if (read_message() < 0) {
	perror("read_message");
	if (message.buf != NULL)
	    free(message.buf);
	exit(EX_OSERR);
    }

    if (options.protocol & SMTPC_PROTO_ESMTP)
	sockstr = sockstr_new(options.nodename, options.servname, NULL);
    else if (options.protocol & SMTPC_PROTO_LMTP)
	sockstr = sockstr_new(NULL, NULL, options.path);
    else
	sockstr = NULL;
    if (sockstr == NULL) {
	perror("sockstr_new");
	if (message.buf != NULL)
	    free(message.buf);
	exit(EX_OSERR);
    }
    sockstr->timeout = 300;

    signal(SIGPIPE, SIG_IGN);

    if (sockstr_client_connect(sockstr) < 0) {
	fprintf(stderr, "error: %s\n", sockstr_errstr(sockstr));
	sockstr_destroy(sockstr);
	if (message.buf != NULL)
	    free(message.buf);
	exit(EX_IOERR);
    }

    rs = session();
    if (message.buf != NULL)
	free(message.buf);

    if (options.verbose && server.buf != NULL && 0 < server.buflen)
	fputs(server.buf, stdout);

    if (rs < 0) {
	switch (rs) {
	case SMTPC_ERR_SOCKET:
	    fprintf(stderr, "Socket error: %s\n", sockstr_errstr(sockstr));
	    break;
	case SMTPC_ERR_PROTOCOL:
	    fprintf(stderr, "Unexpected response: %s", server.buf);
	    break;
	case SMTPC_ERR_SUBMISSION:
	    dialog(10, "QUIT\r\n");
	    break;
	default:
	    fprintf(stderr, "Unknown error %ld\n", (long) rs);
	    break;
	}

	sockstr_destroy(sockstr);
	if (server.buf != NULL)
	    free(server.buf);
	exit(rs);
    }

    /* entirely or partially sent */
    dialog(10, "QUIT\r\n");
    sockstr_destroy(sockstr);
    free(server.buf);
    exit(EX_OK);
}
