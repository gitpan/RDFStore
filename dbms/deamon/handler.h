/*
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
 *
 * $Id: handler.h,v 1.3 2004/08/19 18:57:36 areggiori Exp $
 */ 

void close_all_dbps();
void parse_request( connection * r);
void init_cmd_table( void );
