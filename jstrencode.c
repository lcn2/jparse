/*
 * jstrencode - tool to encode JSON decoded strings
 *
 * "JSON: when a minimal design falls below a critical minimum." :-)
 *
 * This JSON parser and tool were co-developed in 2022 by:
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


/* special comments for the seqcexit tool */
/* exit code out of numerical order - ignore in sequencing - ooo */
/* exit code change of order - use new value in sequencing - coo */


#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <locale.h>

/*
 * jstrencode - tool to JSON encode JSON decoded strings
 */
#include "jstrencode.h"


/*
 * definitions
 */
#define REQUIRED_ARGS (0)	/* number of required arguments on the command line */

/*
 * usage message
 *
 * Use the usage() function to print the usage_msg([0-9]?)+ strings.
 */
static const char * const usage_msg =
    "usage: %s [-h] [-v level] [-q] [-V] [-t] [-n] [-N] [-Q] [-e] [-E level] [string ...]\n"
    "\n"
    "\t-h\t\tprint help message and exit\n"
    "\t-v level\tset verbosity level (def level: %d)\n"
    "\t-q\t\tquiet mode: silence msg(), warn(), warnp() if -v 0 (def: not quiet)\n"
    "\t-V\t\tprint version string and exit\n"
    "\t-t\t\tperform tests of JSON encode/decode functionality\n"
    "\t-n\t\tdo not output newline after encode output\n"
    "\t-N\t\tignore all newline characters\n"
    "\t-Q\t\tenclose output in double quotes (def: do not)\n"
    "\t-e\t\tenclose each encoded string with escaped double quotes (def: do not)\n"
    "\t-E level\tentertainment mode\n"
    "\n"
    "\t[string ...]\tencode strings on command line (def: read stdin)\n"
    "\t\t\tNOTE: - means read from stdin\n"
    "\n"
    "Exit codes:\n"
    "     0   encode successful\n"
    "     1   encode unsuccessful\n"
    "     2   -h and help string printed or -V and version string printed\n"
    "     3   invalid command line, invalid option or option missing an argument\n"
    " >= 10   internal error\n"
    "\n"
    "%s version: %s\n"
    "jparse UTF-8 version: %s\n"
    "jparse library version: %s";


/*
 * forward declarations
 */
static void usage(int exitcode, char const *prog, char const *str) __attribute__((noreturn));
static struct jstring *jstrencode_stream(FILE *in_stream, bool ignore_nl);
static struct jstring *add_encoded_string(char *string, size_t bufsiz);

/*
 * encoded string list
 */
static struct jstring *json_encoded_strings = NULL;


/*
 * add_encoded_string	- allocate and add a JSON encoded string to the json_encoded_strings list
 *
 * given:
 *	string	    - string to add (char *)
 *	bufsiz	    - buffer size
 *
 * returns:
 *	pointer to a newly allocated struct jstring *, added to the
 *	json_encoded_strings list or NULL if allocation failed
 *
 * NOTE: it is ASSUMED that the string is allocated so one should NOT pass a
 * char * that is not allocated on the stack.
 */
static struct jstring *
add_encoded_string(char *string, size_t bufsiz)
{
    struct jstring *jstr = NULL; /* for jstring list */
    struct jstring *jstr_next = NULL; /* to get last in list */

    /*
     * firewall
     */
    if (string == NULL) {
	err(10, __func__, "string is NULL");
	not_reached();
    }

    jstr = alloc_jstr(string, bufsiz);
    if (jstr == NULL) {
	warn(__func__, "failed to allocate struct jstring * for list");

	if (string != NULL) {
	    free(string);
	    string = NULL;
	}

	return NULL;
    }

    /*
     * add allocated jstring struct to list
     */

    /*
     * find end of list
     */
    for (jstr_next = json_encoded_strings; jstr_next != NULL && jstr_next->next != NULL; jstr_next = jstr_next->next)
	;;

    /*
     * add to end of list
     */
    if (jstr_next == NULL){
	json_encoded_strings = jstr;
    } else {
	jstr_next->next = jstr;
    }

    return jstr;
}


/*
 * dup_without_nl - duplicate a buffer and remove all newlines
 *
 * given:
 *	input	    original input buffer
 *	inputlen    pointer to the length of the input buffer
 *
 * returns:
 *	malloced buffer without any newlines
 *	NULL ==> malloc error, or NULL argument
 *
 * NOTE: If newlines were removed in the copy, then *inputlen will be updated
 *	 to account for the new length.
 */
static char *
dup_without_nl(char *input, size_t *inputlen)
{
    char *dup_input = NULL;	/* duplicate of input */
    size_t i;
    size_t j;

    /*
     * firewall
     */
    if (input == NULL) {
	warn(__func__, "input is NULL");
	return NULL;
    }
    if (inputlen == NULL) {
	warn(__func__, "inputlen is NULL");
	return NULL;
    }

    /*
     * copy input removing all newlines
     */
    dup_input = malloc(*inputlen + 1);	/* + 1 for guard NUL byte */
    if (dup_input == NULL) {
	warn(__func__, "malloc of input failed");
	return NULL;
    }
    for (i=0, j=0; i < *inputlen; ++i) {
	if (input[i] != '\n') {
	    dup_input[j++] = input[i];
	}
    }
    dup_input[j] = '\0';    /* paranoia */

    /*
     * update inputlen if we removed newlines
     */
    if (j != i) {
	*inputlen = j;
    }

    /*
     * return success
     */
    return dup_input;
}


/*
 * jstrencode_stream - encode an open file stream into a char *
 *
 * given:
 *	in_stream	open file stream to encode
 *	ignore_nl	true ==> ignore all newline characters
 *
 * returns:
 *	allocated struct jstring * ==> encoding was successful,
 *	NULL ==> error in encoding, or NULL stream, or read error
 *
 * NOTE: this function adds the allocated struct jstring * to the list of
 * encoded JSON strings.
 */
static struct jstring *
jstrencode_stream(FILE *in_stream, bool ignore_nl)
{
    char *input = NULL;		/* argument to process */
    size_t inputlen;		/* length of input buffer */
    size_t bufsiz;		/* length of the buffer */
    char *buf = NULL;		/* encode buffer */
    struct jstring *jstr = NULL;    /* encoded string added to list */
    char *dup_input = NULL;	/* duplicate of input w/o newlines */

    /*
     * firewall
     */
    if (in_stream == NULL) {
	warn(__func__, "in_stream is NULL");
	return NULL;
    }

    /*
     * read all of the input stream
     */
    dbg(DBG_LOW, "about to decode all data on input stream");
    input = read_all(in_stream, &inputlen);
    if (input == NULL) {
	warn(__func__, "error while reading data from input stream");
	return NULL;
    }
    dbg(DBG_MED, "stream read length: %ju", (uintmax_t)inputlen);

    /*
     * if -N, remove all newlines from data
     */
    if (ignore_nl) {

	/*
	 * copy input removing all newlines, update inputlen if needed
	 */
	dup_input = dup_without_nl(input, &inputlen);
	if (dup_input == NULL) {
	    err(11, __func__, "dup_without_nl failed");
	    not_reached();
	}

	/*
	 * replace input with the duplicate w/o newline input if needed
	 */
	free(input);
	input = dup_input;
    }

    /*
     * encode data read from input stream
     */
    buf = json_encode(input, inputlen, &bufsiz);
    if (buf == NULL) {
	/* free input */
	if (input != NULL) {
	    free(input);
	    input = NULL;
	}

	warn(__func__, "error while encoding stdin buffer");
	return NULL;
    }

    /*
     * free input
     */
    if (input != NULL) {
	free(input);
	input = NULL;
    }

    jstr = add_encoded_string(buf, bufsiz);
    if (jstr == NULL) {
	warn(__func__, "failed to allocate jstring of size %ju", bufsiz);
	return NULL;
    }

    /*
     * return struct added to list
     */
    return jstr;

}


int
main(int argc, char **argv)
{
    char const *program = NULL;	/* our name */
    extern char *optarg;	/* option argument */
    extern int optind;		/* argv index of the next arg */
    char *input;		/* argument to process */
    size_t inputlen;		/* length of input buffer */
    char *buf;			/* encode buffer */
    size_t bufsiz;		/* length of the buffer */
    size_t outputlen;		/* length of write of encode buffer */
    int entertainment = 0;	/* have some fun :-) */
    bool success = true;	/* true ==> decoding OK, false ==> error while decoding */
    bool nloutput = true;	/* true ==> output newline after JSON encode */
    bool ignore_nl = false;	/* true ==> ignore all newlines when decoding */
    bool write_quote = false;	/* true ==> output enclosing quotes */
    bool esc_quotes = false;	/* true ==> escape quotes */
    int ret;			/* libc return code */
    int i;
    struct jstring *jstr = NULL;    /* encoded string */
    char *dup_input = NULL;	/* duplicate of arg string */

    /*
     * set locale
     */
    if (setlocale(LC_ALL, "") == NULL) {
	err(12, __func__, "failed to set locale");
	not_reached();
    }

    /*
     * parse args
     */
    program = argv[0];
    while ((i = getopt(argc, argv, ":hv:qVtnNQeE:")) != -1) {
	switch (i) {
	case 'h':		/* -h - print help to stderr and exit 2 */
	    usage(2, program, ""); /*ooo*/
	    not_reached();
	    break;
	case 'v':		/* -v verbosity */
	    /*
	     * parse verbosity
	     */
	    verbosity_level = parse_verbosity(optarg);
	    if (verbosity_level < 0) {
		usage(3, program, "invalid -v verbosity"); /*ooo*/
		not_reached();
	    }
	    break;
	case 'q':
	    msg_warn_silent = true;
	    break;
	case 'V':		/* -V - print version and exit 2 */
	    print("%s version: %s\n", JSTRENCODE_BASENAME, JSTRENCODE_VERSION);
	    print("jparse UTF-8 version: %s\n", JPARSE_UTF8_VERSION);
	    print("jparse library version: %s\n", JPARSE_LIBRARY_VERSION);
	    exit(2); /*ooo*/
	    not_reached();
	    break;
	case 'E':
	    /*
	     * parse entertainment level
	     */
	    entertainment = parse_entertainment(optarg);
	    if (entertainment < 0) {
		usage(3, program, "invalid -E level"); /*ooo*/
		not_reached();
	    }
	    jdecencchk(entertainment); /* :-) */
	    exit(0); /*ooo*/
	    not_reached();
	    break;
	case 't':		/* -t - validate the contents of the byte2asciistr[] table */
	    print("%s: Beginning chkbyte2asciistr test of the byte2asciistr table...\n", program);
	    chkbyte2asciistr();
	    print("%s: ... passed byte2asciistr table test\n", program);
	    print("%s: Beginning jdecencchk...\n", program);
	    jdecencchk(entertainment);
	    print("%s: ... passed jdecencchk\n", program);
	    exit(0); /*ooo*/
	    not_reached();
	    break;
	case 'n':
	    nloutput = false;
	    break;
	case 'N':
	    ignore_nl = true;
	    break;
	case 'Q':
	    write_quote = true;
	    break;
	case 'e':
	    esc_quotes = true;
	    break;
	case ':':   /* option requires an argument */
	case '?':   /* illegal option */
	default:    /* anything else but should not actually happen */
	    check_invalid_option(program, i, optopt);
	    usage(3, program, ""); /*ooo*/
	    not_reached();
	    break;
	}
    }
    dbg(DBG_LOW, "enclose in quotes: %s", booltostr(write_quote));
    dbg(DBG_LOW, "newline output: %s", booltostr(nloutput));
    dbg(DBG_LOW, "silence warnings: %s", booltostr(msg_warn_silent));
    dbg(DBG_LOW, "escaped quotes: %s", booltostr(esc_quotes));

    /*
     * case: process arguments on command line
     */
    if (argc - optind > 0) {
	/*
	 * process each argument in order
	 */
	for (i=optind; i < argc; ++i) {

	    /*
	     * obtain argument string
	     */
	    input = argv[i];

	    if (!strcmp(input, "-")) {

		/*
		 * encode stdin
		 *
		 * NOTE: the function jstrencode_stream() adds the allocated
		 * struct jstring * to the list of encoded JSON strings
		 */
		jstr = jstrencode_stream(stdin, ignore_nl);
		if (jstr != NULL) {
		    dbg(DBG_MED, "encode length: %ju", jstr->bufsiz);
		} else {
		    warn(__func__, "failed to encode string from stdin");
		    success = false;
		}

	    } else {

		/*
		 * obtain arg
		 */
		inputlen = strlen(input);
		dbg(DBG_LOW, "processing arg: %d: <%s>", i-optind, input);
		dbg(DBG_MED, "arg length: %ju", (uintmax_t)inputlen);

		/*
		 * If -N, and newlines in arg, remove them
		 */
		if (ignore_nl) {

		    /*
		     * copy input removing all newlines, update inputlen if needed
		     */
		    dup_input = dup_without_nl(input, &inputlen);
		    if (dup_input == NULL) {
			err(13, __func__, "dup_without_nl failed");
			not_reached();
		    }

		    /*
		     * replace input with the duplicate w/o newline input if needed
		     */
		    input = dup_input;
		    dbg(DBG_VHIGH, "-N and arg is now: %d: <%s>", i-optind, input);
		    dbg(DBG_VHIGH, "-N and arg length is now: %ju", (uintmax_t)inputlen);
		}

		/*
		 * encode arg
		 */
		buf = json_encode_str(input, &bufsiz);
		if (buf == NULL) {
		    warn(__func__, "error while encoding processing arg: %d", i-optind);
		    success = false;

		/*
		 * append encoded buffer to encoded JSON strings list
		 */
		} else {
		    dbg(DBG_MED, "encode length: %ju", bufsiz);
		    jstr = add_encoded_string(buf, bufsiz);
		    if (jstr == NULL) {
			warn(__func__, "error adding encoded string to list");
			success = false;
		    } else {
			dbg(DBG_MED, "added string of size %ju to encoded strings list", bufsiz);
		    }
		}

		/*
		 * free duplicated arg if -N
		 */
		if (ignore_nl && input != NULL) {
		    free(input);
		    input = NULL;
		}
	    }
	}

    /*
     * case: process data on stdin
     */
    } else {

	/*
	 * NOTE: the function jstrencode_stream() adds the allocated
	 * struct jstring * to the list of encoded JSON strings
	 */
	jstr = jstrencode_stream(stdin, ignore_nl);

	if (jstr != NULL) {
	    dbg(DBG_MED, "encode length: %ju", jstr->bufsiz);
	} else {
		warn(__func__, "error while encoding processing stdin");
		success = false;
	    }
	}

    /*
     * write starting quote if requested
     */
    if (write_quote) {
	errno = 0;		/* pre-clear errno for warnp() */
	ret = fputc('"', stdout);
	if (ret != '"') {
	    warnp(__func__, "fputc for starting quote returned error");
	    success = false;
	}
    }

    /*
     * now write each processed arg to stdout
     */
    for (jstr = json_encoded_strings; jstr != NULL; jstr = jstr->next) {
	dbg(DBG_MED, "processing encoded JSON string of size: %ju", jstr->bufsiz);
	/*
	 * write starting escaped quote if requested
	 */
	if (esc_quotes) {
	    fprint(stdout, "%s", "\\\"");
	}
	buf = jstr->jstr;
	bufsiz = (uintmax_t)jstr->bufsiz;
	dbg(DBG_MED, "bufsiz: %ju", bufsiz);
	errno = 0;		/* pre-clear errno for warnp() */
	outputlen = fwrite(buf, 1, bufsiz, stdout);
	if (outputlen != bufsiz) {
	    warnp(__func__, "error: wrote %ju bytes out of expected %jd bytes",
			    (uintmax_t)outputlen, (uintmax_t)bufsiz);
	    success = false;
	}

	/*
	 * write ending escaped quote if requested
	 */
	if (esc_quotes) {
	    fprint(stdout, "%s", "\\\"");
	}
    }


    /*
     * write ending quote if requested
     */
    if (write_quote) {
	errno = 0;		/* pre-clear errno for warnp() */
	ret = fputc('"', stdout);
	if (ret != '"') {
	    warnp(__func__, "fputc for ending quote returned error");
	    success = false;
	}
    }

    /*
     * unless -n, output newline
     */
    if (nloutput == true) {
	errno = 0;		/* pre-clear errno for warnp() */
	ret = putchar('\n');
	if (ret != '\n') {
	    warnp(__func__, "error while writing final newline");
	    success = false;
	}
    }

    /*
     * free list of encoded strings
     */
    free_jstring_list(json_encoded_strings);

    /*
     * All Done!!! All Done!!! -- Jessica Noll, Age 2
     */
    if (success == false) {
	exit(1); /*ooo*/
    }
    exit(0); /*ooo*/
}


/*
 * usage - print usage to stderr
 *
 * Example:
 *      usage(3, program, "wrong number of arguments");
 *
 * given:
 *	exitcode        value to exit with
 *	prog		our program name
 *	str		top level usage message
 *
 * NOTE: We warn with extra newlines to help internal fault messages stand out.
 *       Normally one should NOT include newlines in warn messages.
 *
 * This function does not return.
 */
static void
usage(int exitcode, char const *prog, char const *str)
{
    /*
     * firewall
     */
    if (str == NULL) {
	str = "((NULL str))";
	warn(__func__, "\nin usage(): str was NULL, forcing it to be: %s\n", str);
    }
    if (prog == NULL) {
	prog = JSTRENCODE_BASENAME;
	warn(__func__, "\nin usage(): prog was NULL, forcing it to be: %s\n", prog);
    }

    /*
     * print the formatted usage stream
     */
    if (*str != '\0') {
	fprintf_usage(DO_NOT_EXIT, stderr, "%s\n", str);
    }

    fprintf_usage(exitcode, stderr, usage_msg, prog, DBG_DEFAULT, JSTRENCODE_BASENAME, JSTRENCODE_VERSION, JPARSE_LIBRARY_VERSION);
    exit(exitcode); /*ooo*/
    not_reached();
}
