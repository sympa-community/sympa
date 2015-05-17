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
 * sockstr.c was originally written by IKEDA Soji <ikeda@conversion.co.jp>
 * as a part of smtpc utility for Sympa project.
 *
 * 2015-05-17 IKEDA Soji: Initial checkin to source repository.
 */

#include "config.h"
#include <errno.h>
#include <fcntl.h>
#include <netdb.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/un.h>
#include "sockstr.h"

/** Constructor
 * Creats new instance of sockstr object.
 * @param[in] nodename Hostname of the server.  Default is "localhost".
 * @param[in] servname Port number or service name.  Default is "smtp".
 * @returns New instance.
 * If error occurred, sets errno and returns NULL.
 */
sockstr_t *sockstr_new(char *nodename, char *servname, char *path)
{
    sockstr_t *self;

    self = (sockstr_t *) malloc(sizeof(sockstr_t));
    if (self == NULL)
	return NULL;

    self->_errstr[0] = '\0';
    self->_sock = -1;
    self->_bufcnt = 0;
    self->_bufptr = self->_buf;
    self->timeout = 300;

    if (path != NULL && *path) {
	self->path = strdup(path);
	if (self->path == NULL) {
	    free(self);
	    return NULL;
	}

	self->nodename = NULL;
	self->servname = NULL;
    } else {
	self->path = NULL;

	if (!nodename || !*nodename)
	    nodename = "localhost";
	if (!servname || !*servname)
	    servname = "25";
	self->nodename = strdup(nodename);
	self->servname = strdup(servname);
	if (self->nodename == NULL || self->servname == NULL) {
	    if (self->nodename != NULL)
		free(self->nodename);
	    if (self->servname != NULL)
		free(self->servname);
	    free(self);
	    return NULL;
	}
    }

    return self;
}

/** Destructor
 * Unallocate memory for the instance.
 * @retuns None.
 */
void sockstr_destroy(sockstr_t * self)
{
    if (self == NULL)
	return;

    if (0 <= self->_sock)
	close(self->_sock);
    if (self->nodename != NULL)
	free(self->nodename);
    if (self->servname != NULL)
	free(self->servname);
    if (self->path != NULL)
	free(self->path);
    free(self);
}

static void sockstr_set_error(sockstr_t * self, int errnum,
			      const char *errstr)
{
    self->_errnum = errnum;
    if (errstr == NULL) {
	char *buf;

	buf = strerror(errnum);
	if (buf == NULL)
	    snprintf(self->_errstr, SOCKSTR_ERRSIZE, "(%d) Error", errnum);
	else
	    snprintf(self->_errstr, SOCKSTR_ERRSIZE, "(%d) %s", errnum,
		     buf);
    } else
	snprintf(self->_errstr, SOCKSTR_ERRSIZE, "(%d) %s", errnum,
		 errstr);
}

/** Last error
 * Gets error by the last operation.
 * @returns String, or if the last operation was success, NULL.
 */
char *sockstr_errstr(sockstr_t * self)
{
    return self->_errstr;
}

static int _connect_socket(sockstr_t * self, int sock,
			   struct sockaddr *ai_addr, socklen_t ai_addrlen,
			   int blocking)
{
    long flags;

    flags = fcntl(sock, F_GETFL, NULL);
    if (flags < 0 || fcntl(sock, F_SETFL, flags | O_NONBLOCK) < 0) {
	sockstr_set_error(self, errno, NULL);
	return -1;
    }

    if (connect(sock, ai_addr, ai_addrlen) < 0) {
	if (errno == EINPROGRESS) {
	    struct timeval tv;
	    fd_set rfd, wfd;
	    int rc, errnum;
	    socklen_t errlen;

	    do {
		tv.tv_sec = self->timeout;
		tv.tv_usec = 0;
		FD_ZERO(&rfd);
		FD_SET(sock, &rfd);
		wfd = rfd;
		rc = select(sock + 1, &rfd, &wfd, NULL, &tv);
	    } while (rc < 0 && errno == EINTR);

	    if (rc == 0) {
		sockstr_set_error(self, ETIMEDOUT, NULL);
		return -1;
	    } else if (FD_ISSET(sock, &rfd) || FD_ISSET(sock, &wfd)) {
		errlen = sizeof(errnum);
		getsockopt(sock, SOL_SOCKET, SO_ERROR,
			   (void *) &errnum, &errlen);
		if (errnum) {
		    sockstr_set_error(self, errnum, NULL);
		    return -1;
		}
	    } else {
		sockstr_set_error(self, errno, NULL);
		return -1;
	    }
	} else {
	    sockstr_set_error(self, errno, NULL);
	    return -1;
	}
    }

    if (blocking) {
	if (fcntl(sock, F_SETFL, flags) < 0) {
	    sockstr_set_error(self, errno, NULL);
	    return -1;
	}
    }
    return 0;
}

int socktcp_connect(sockstr_t * self)
{
    struct addrinfo hints, *ai0, *ai;
    int errnum;
    int sock = -1;

    if (0 <= self->_sock) {
	sockstr_set_error(self, EISCONN, NULL);
	return -1;
    }

    memset(&hints, 0, sizeof(hints));
    hints.ai_family = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    errnum = getaddrinfo(self->nodename, self->servname, &hints, &ai0);
    if (errnum) {
	sockstr_set_error(self, errnum, gai_strerror(errnum));
	return -1;
    }

    for (ai = ai0; ai != NULL; ai = ai->ai_next) {
	sock = socket(ai->ai_family, ai->ai_socktype, ai->ai_protocol);
	if (sock < 0) {
	    sockstr_set_error(self, errno, NULL);
	    continue;
	}

	if (_connect_socket(self, sock, ai->ai_addr, ai->ai_addrlen, 0) ==
	    0)
	    break;
	close(sock);
	sock = -1;
    }
    freeaddrinfo(ai0);

    if (sock < 0)
	return -1;

    self->_sock = sock;
    return 0;
}

int sockunix_connect(sockstr_t * self)
{
    struct sockaddr_un sun;
    size_t sunlen;
    int sock = -1;

    if (0 <= self->_sock) {
	sockstr_set_error(self, EISCONN, NULL);
	return -1;
    }
    if (self->path == NULL || self->path[0] == '\0') {
	sockstr_set_error(self, EINVAL, NULL);
	return -1;
    }

    sunlen = strlen(self->path);
    if (sizeof(sun.sun_path) < sunlen + 1) {
	sockstr_set_error(self, ENAMETOOLONG, NULL);
	return -1;
    }

    memset(&sun, 0, sizeof(sun));
    sun.sun_family = PF_UNIX;
    memcpy(sun.sun_path, self->path, sunlen + 1);
    /* I don't know any platforms need to set .sun_len member. */

    sock = socket(AF_UNIX, SOCK_STREAM, 0);
    if (sock < 0) {
	sockstr_set_error(self, errno, NULL);
	return -1;
    }

    if (_connect_socket
	(self, sock, (struct sockaddr *) &sun, sizeof(sun), 0) < 0) {
	close(sock);
	return -1;
    }

    self->_sock = sock;
    return 0;
}

/** Connect
 * Connects to the host.
 * @returns 1 if success, otherwise 0.
 * Description of error can be got by sockstr_errstr().
 */
int sockstr_connect(sockstr_t * self)
{
    if (self->path != NULL)
	return sockunix_connect(self);
    else
	return socktcp_connect(self);
}

static ssize_t sockstr_read(sockstr_t * self, char *buf, size_t count)
{
    int cnt;

    while (self->_bufcnt <= 0) {
	self->_bufcnt = read(self->_sock, self->_buf, sizeof(self->_buf));
	if (self->_bufcnt < 0) {
	    if (errno == EAGAIN || errno == EWOULDBLOCK) {
		int rc;
		struct timeval tv;
		fd_set wfd;

		do {
		    tv.tv_sec = self->timeout;
		    tv.tv_usec = 0;
		    FD_ZERO(&wfd);
		    FD_SET(self->_sock, &wfd);
		    rc = select(self->_sock + 1, NULL, &wfd, NULL, &tv);
		} while (rc < 0 && errno == EINTR);

		if (rc < 0)
		    return -1;
		else if (rc == 0) {
		    errno = ETIMEDOUT;
		    return -1;
		}
	    } else if (errno != EINTR)
		return -1;
	} else if (self->_bufcnt == 0)
	    return 0;
	else
	    self->_bufptr = self->_buf;
    }

    cnt = count;
    if (self->_bufcnt < count)
	cnt = self->_bufcnt;
    memcpy(buf, self->_bufptr, cnt);
    self->_bufptr += cnt;
    self->_bufcnt -= cnt;
    return cnt;
}

#define SOCKSTR_MIN_BUFSIZ (4)
#define SOCKSTR_DEFAULT_BUFSIZ (128)

/** Read one line
 * Read one line termined by a newline (LF) from peer.
 * @param[in,out] lineptr Pointer to buffer provided by user.
 * @param[in,out] n Pointer to allocated size of buffer.
 * @param[in] omitnul If true value is specified, ignores NUL octets (\0) in
 * input.
 * @returns Size of read data, 0 if socket is no longer readalbe
 * or -1 on failure.
 * lineptr and n may be changed.
 */
ssize_t sockstr_getline(sockstr_t * self, char **lineptr, size_t * n,
			int omitnul)
{
    ssize_t rs;
    char chr, *p, *newbuf;
    size_t len, newsiz;

    if (self->_sock < 0 || lineptr == NULL || n == NULL) {
	sockstr_set_error(self, EINVAL, NULL);
	return -1;
    }

    p = *lineptr;
    while (1) {
	rs = sockstr_read(self, &chr, 1);
	if (rs == 1) {
	    len = p - *lineptr;
	    if (*lineptr == NULL || *n < len + 2) {
		if (*lineptr == NULL || *n < SOCKSTR_MIN_BUFSIZ)
		    newsiz = SOCKSTR_DEFAULT_BUFSIZ;
		else
		    newsiz = *n << 1;
		if (*lineptr == NULL)
		    newbuf = malloc(newsiz);
		else
		    newbuf = realloc(*lineptr, newsiz);
		if (newbuf == NULL) {
		    sockstr_set_error(self, errno, NULL);
		    return -1;
		}
		*lineptr = newbuf;
		*n = newsiz;
		p = *lineptr + len;
	    }

	    if (!omitnul || chr != '\0')
		*p++ = chr;

	    if (chr == '\n')
		break;
	} else if (rs == 0) {	/* Disconnected. */
	    if (p == *lineptr) {	/* EOF */
		sockstr_set_error(self, ECONNRESET, NULL);
		return 0;
	    }
	    break;
	} else {
	    sockstr_set_error(self, errno, NULL);
	    return -1;
	}
    }

    *p = '\0';
    return p - *lineptr;
}

/* Get status line(s)
 * Read (one or more) status line(s) from peer.
 * @param[in,out] lineptr Pointer to buffer provided by user.
 * @oaram[in,out] n Pointer to allocated size of buffer.
 * @returns Size of read data, 0 if socket is no longer readalbe
 * or -1 on failure.
 * lineptr and n may be changed.
 * NUL octets (\0) in input are ignored.
 */
ssize_t sockstr_getstatus(sockstr_t * self, char **lineptr, size_t * n)
{
    ssize_t rs;
    char *buf = NULL, *newbuf;
    size_t bufsiz = 0, newsiz, len = 0;

    if (self->_sock < 0 || lineptr == NULL || n == NULL) {
	sockstr_set_error(self, EINVAL, NULL);
	return -1;
    }

    while (1) {
	rs = sockstr_getline(self, &buf, &bufsiz, 1);
	if (rs < 0) {
	    if (buf != NULL)
		free(buf);
	    return -1;
	} else if (rs == 0) {	/* Disconnected. */
	    if (len == 0) {	/* EOF */
		sockstr_set_error(self, ECONNRESET, NULL);
		if (buf != NULL)
		    free(buf);
		return 0;
	    }
	    break;
	} else {
	    if (*lineptr == NULL || *n < len + rs + 1) {
		if (*lineptr == NULL || *n < SOCKSTR_DEFAULT_BUFSIZ)
		    newsiz = SOCKSTR_DEFAULT_BUFSIZ;
		else
		    newsiz = *n;
		while (newsiz < len + rs + 1)
		    newsiz <<= 1;
		if (*lineptr == NULL)
		    newbuf = malloc(newsiz);
		else
		    newbuf = realloc(*lineptr, newsiz);
		if (newbuf == NULL) {
		    sockstr_set_error(self, errno, NULL);
		    if (buf != NULL)
			free(buf);
		    return -1;
		}
		*n = newsiz;
		*lineptr = newbuf;
	    }
	    memcpy(*lineptr + len, buf, rs + 1);
	    len += rs;

	    if (3 <= rs &&
		'2' <= buf[0] && buf[0] <= '5' &&
		'0' <= buf[1] && buf[1] <= '9' &&
		'0' <= buf[2] && buf[2] <= '9') {
		if (buf[3] != '-')
		    break;
	    } else {
		sockstr_set_error(self, EINVAL, NULL);
		if (buf != NULL)
		    free(buf);
		return -1;
	    }
	}
    }

    if (buf != NULL)
	free(buf);
    return len;
}

static ssize_t sockstr_write(sockstr_t * self, void *buf, size_t count)
{
    size_t leftlen = count;
    ssize_t rs;
    char *p = buf;

    while (leftlen > 0) {
	rs = write(self->_sock, p, leftlen);
	if (rs < 0) {
	    if (errno == EAGAIN || errno == EWOULDBLOCK) {
		int rc;
		struct timeval tv;
		fd_set rfd;

		do {
		    tv.tv_sec = self->timeout;
		    tv.tv_usec = 0;
		    FD_ZERO(&rfd);
		    FD_SET(self->_sock, &rfd);
		    rc = select(self->_sock + 1, &rfd, NULL, NULL, &tv);
		} while (rc < 0 && errno == EINTR);

		if (rc < 0)
		    return -1;
		else if (rc == 0) {
		    errno = ETIMEDOUT;
		    return -1;
		}
	    } else if (errno != EINTR)
		return -1;
	} else {
	    leftlen -= rs;
	    p += rs;
	}
    }
    return count;
}

/** Write formatted string
 * Formats string according to format and write to peer.
 * @param[in] format Format.
 * @param[in] ap Arguments fed to vsnprintf(3).
 * @returns Number of octets written.
 */
ssize_t sockstr_vprintf(sockstr_t * self, const char *format, va_list ap)
{
    int rc;
    ssize_t rs;
    char *buf, *newbuf;
    va_list ap_again;

    buf = malloc(SOCKSTR_DEFAULT_BUFSIZ);
    if (buf == NULL) {
	sockstr_set_error(self, errno, NULL);
	return -1;
    }

    va_copy(ap_again, ap);
    rc = vsnprintf(buf, SOCKSTR_DEFAULT_BUFSIZ, format, ap);
    if (rc < 0) {
	sockstr_set_error(self, errno, NULL);
	va_end(ap_again);
	free(buf);
	return -1;
    } else if (SOCKSTR_DEFAULT_BUFSIZ < rc + 1) {
	newbuf = realloc(buf, rc + 1);
	if (newbuf == NULL) {
	    sockstr_set_error(self, errno, NULL);
	    va_end(ap_again);
	    free(buf);
	    return -1;
	}
	buf = newbuf;
	rc = vsnprintf(buf, rc + 1, format, ap_again);
	if (rc < 0) {
	    sockstr_set_error(self, errno, NULL);
	    va_end(ap_again);
	    free(buf);
	    return -1;
	}
    }
    va_end(ap_again);

    rs = sockstr_write(self, buf, rc);
    if (rs < 0)
	sockstr_set_error(self, errno, NULL);
    free(buf);
    return rs;
}

/** @todo doc
 *
 */
ssize_t sockstr_printf(sockstr_t * self, const char *format, ...)
{
    va_list ap;
    ssize_t rs;

    va_start(ap, format);
    rs = sockstr_vprintf(self, format, ap);
    va_end(ap);
    return rs;
}

/** Write data to peer
 * Writes data to peer.
 * @param[in] buf Buffer including data.
 * @param[in] count Size of data.
 * @param[in] delim Delimiter appended to output.
 * @param[in] fixnewline Whether newlines will be canonicalized or not.
 * @param[in] fixdot Fix lines beginning with dot (.).
 * @returns Number of octets written.
 */
ssize_t sockstr_putdata(sockstr_t * self, void *buf, size_t count,
			char *delim, int fixnewline, int fixdot)
{
    char *p, *q, *end;
    ssize_t rs, len, linelen;

    p = q = buf;
    end = buf + count;
    len = 0;
    while (p < end) {
	if (fixdot && *p == '.') {
	    rs = sockstr_write(self, ".", 1);
	    if (rs < 0) {
		sockstr_set_error(self, errno, NULL);
		return -1;
	    } else
		len += rs;
	}

	while (q < end)
	    if (*(q++) == '\n')
		break;

	if (fixnewline) {
	    if (p + 1 == q && q[-1] == '\n' ||
		q[-1] == '\r' ||
		p + 1 < q && q[-2] != '\r' && q[-1] == '\n')
		linelen = q - p - 1;
	    else if (q[-1] != '\n')
		linelen = q - p;
	    else
		linelen = q - p - 2;
	} else
	    linelen = q - p;

	rs = sockstr_write(self, p, linelen);
	if (rs < 0) {
	    sockstr_set_error(self, errno, NULL);
	    return -1;
	} else
	    len += rs;

	if (fixnewline) {
	    rs = sockstr_write(self, "\r\n", 2);
	    if (rs < 0) {
		sockstr_set_error(self, errno, NULL);
		return -1;
	    } else
		len += rs;
	}

	p = q;
    }

    if (delim != NULL && *delim != '\0') {
	rs = sockstr_write(self, delim, strlen(delim));
	if (rs < 0) {
	    sockstr_set_error(self, errno, NULL);
	    return -1;
	} else
	    len += rs;
    }

    return len;
}
