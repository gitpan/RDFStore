/*
  *
  *     Copyright (c) 2000-2004 Alberto Reggiori <areggiori@webweaving.org>
  *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
  *
  * NOTICE
  *
  * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
  * file you should have received together with this source code. If you did not get a
  * a copy of such a license agreement you can pick up one at:
  *
  *     http://rdfstore.sourceforge.net/LICENSE
  *
  * $Id: fraenkel_compress.h,v 1.2 2004/08/19 18:57:43 areggiori Exp $
  */

#ifndef _FRAENKEL_COMPRESS_H
#define _FRAENKEL_COMRPESS_H

unsigned int 
compress_fraenkel ( 
	unsigned char * in, 
	unsigned char * out,
	unsigned int insize
	); 

unsigned int 
expand_fraenkel ( 
	unsigned char * in, 
	unsigned char * out,
	unsigned int insize
	); 
#endif

