/*
 * verge - determine if first version is greater or equal to the second version
 *
 * "Because too much minimalism can be sub-minimal." :-)
 *
 * This JSON parser was co-developed in 2022 by:
 *
 *	@xexyl
 *	https://xexyl.net		Cody Boone Ferguson
 *	https://ioccc.xexyl.net
 * and:
 *	chongo (Landon Curt Noll, http://www.isthe.com/chongo/index.html) /\oo/\
 *
 * "Because sometimes even the IOCCC Judges need some help." :-)
 *
 * "Share and Enjoy!"
 *     --  Sirius Cybernetics Corporation Complaints Division, JSON spec department. :-)
 */


#if !defined(INCLUDE_VERGE_H)
#    define  INCLUDE_VERGE_H


/*
 * dbg - info, debug, warning, error, and usage message facility
 */
#include "../dbg/dbg.h"

/*
 * util - common utility functions for the IOCCC toolkit
 */
#include "util.h"



/*
 * globals
 */

/*
 * externals
 */

/*
 * function prototypes
 */
static size_t allocate_vers(char *str, intmax_t **pvers);


#endif /* INCLUDE_VERGE_H */
