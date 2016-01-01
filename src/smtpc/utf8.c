/* $Id$ */
/*
 * Sympa - SYsteme de Multi-Postage Automatique
 *
 * Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
 * Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
 * 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
 * Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016 GIP RENATER
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
 * utf8_check was originally taken from UTF8.xs in Unicode-UTF8 module by
 * Christian Hansen distributed under Perl 5 License:
 * <http://search.cpan.org/dist/Unicode-UTF8>.
 *
 * Copyright 2011-2012 by Christian Hansen.
 */

#include "config.h"
#include <sys/types.h>
#include <unistd.h>

#if SIZEOF_UNSIGNED_INT >= 4
typedef unsigned int unichar_t;
#elif SIZEOF_UNSIGNED_LONG >= 4
typedef unsigned long unichar_t;
#else
#error "Integral types on your system are too short"
#endif

static const unsigned char utf8_sequence_len[0x100] = {
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,	/* 0x00-0x0F */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,	/* 0x10-0x1F */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,	/* 0x20-0x2F */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,	/* 0x30-0x3F */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,	/* 0x40-0x4F */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,	/* 0x50-0x5F */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,	/* 0x60-0x6F */
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,	/* 0x70-0x7F */
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* 0x80-0x8F */
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* 0x90-0x9F */
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* 0xA0-0xAF */
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* 0xB0-0xBF */
    0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,	/* 0xC0-0xCF */
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,	/* 0xD0-0xDF */
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,	/* 0xE0-0xEF */
    4, 4, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* 0xF0-0xFF */
};

/** Check string
 * Check if the string consists of valid UTF-8 sequence.
 * @param[in] s Buffer.
 * @param[in] len Length of buffer.
 * @returns If the buffer contains only ASCII characters, -1.
 * Else if the buffer contains non-ASCII sequence not forming valid UTF-8,
 * index of the first position such sequence appears.
 * Otherwise, length of the buffer.
 */
ssize_t utf8_check(const unsigned char *s, const size_t len)
{
    const unsigned char *p = s;
    const unsigned char *e = s + len;
    const unsigned char *e4 = e - 4;
    unichar_t v;

    int is_asciionly = 1;	/* Added to check if non-ASCII is included. */

    while (p < e4) {
	while (p < e4 && *p < 0x80)
	    p++;

      check:
	switch (utf8_sequence_len[*p]) {
	case 0:
	    goto done;
	case 1:
	    p += 1;
	    break;
	case 2:
	    /* 110xxxxx 10xxxxxx */
	    if ((p[1] & 0xC0) != 0x80)
		goto done;
	    p += 2;
	    is_asciionly = 0;
	    break;
	case 3:
	    v = ((unichar_t) p[0] << 16)
		| ((unichar_t) p[1] << 8)
		| ((unichar_t) p[2]);
	    /* 1110xxxx 10xxxxxx 10xxxxxx */
	    if ((v & 0x00F0C0C0) != 0x00E08080 ||
		/* Non-shortest form */
		v < 0x00E0A080 ||
		/* Surrogates U+D800..U+DFFF */
		(v & 0x00EFA080) == 0x00EDA080 ||
		/* Non-characters U+FDD0..U+FDEF, U+FFFE..U+FFFF */
		(v >= 0x00EFB790 && (v <= 0x00EFB7AF || v >= 0x00EFBFBE)))
		goto done;
	    p += 3;
	    is_asciionly = 0;
	    break;
	case 4:
	    v = ((unichar_t) p[0] << 24)
		| ((unichar_t) p[1] << 16)
		| ((unichar_t) p[2] << 8)
		| ((unichar_t) p[3]);
	    /* 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx */
	    if ((v & 0xF8C0C0C0) != 0xF0808080 ||
		/* Non-shortest form */
		v < 0xF0908080 ||
		/* Greater than U+10FFFF */
		v > 0xF48FBFBF ||
		/* Non-characters U+nFFFE..U+nFFFF on plane 1-16 */
		(v & 0x000FBFBE) == 0x000FBFBE)
		goto done;
	    p += 4;
	    is_asciionly = 0;
	    break;
	}
    }
    if (p < e && p + utf8_sequence_len[*p] <= e)
	goto check;
  done:
    if (p == e && is_asciionly)
	return -1;
    else
	return p - s;
}
