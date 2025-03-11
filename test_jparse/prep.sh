#!/usr/bin/env bash
#
# prep.sh - prep for a release - actions for make prep and make release
#
# Copyright (c) 2022-2025 by Cody Boone Ferguson and Landon Curt Noll. All
# rights reserved.
#
# Permission to use, copy, modify, and distribute this software and
# its documentation for any purpose and without fee is hereby granted,
# provided that the above copyright, this permission notice and text
# this comment, and the disclaimer below appear in all of the following:
#
#       supporting documentation
#       source copies
#       source works derived from this source
#       binaries derived from this source or from derived source
#
# THE AUTHORS DISCLAIM ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING
# ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
# AUTHORS BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY
# DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
# CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE OR JSON.
#
# This JSON parser, library and tools were co-developed in 2022-2025 by Cody Boone
# Ferguson and Landon Curt Noll:
#
#  @xexyl
#	https://xexyl.net		Cody Boone Ferguson
#	https://ioccc.xexyl.net
# and:
#	chongo (Landon Curt Noll, http://www.isthe.com/chongo/index.html) /\oo/\
#
# "Because sometimes even the IOCCC Judges need some help." :-)
#
# "Share and Enjoy!"
#     --  Sirius Cybernetics Corporation Complaints Division, JSON spec department. :-)
#



# setup
#
export FAILURE_SUMMARY=
export SKIPPED_SUMMARY=
export LOGFILE=
export PREP_VERSION="2.0.0 2025-02-28"
export NOTICE_COUNT="0"
export USAGE="usage: $0 [-h] [-v level] [-V] [-e] [-o] [-m make] [-M Makefile] [-l logfile]

    -h              print help and exit
    -v level        flag ignored
    -V              print version and exit

    -e		    exit on first make action error (def: exit only at end)
    -o		    do NOT use backup files, fail if bison or flex cannot be used (def: use)
    -m make	    make command (def: make)
    -M Makefile	    path to Makefile (def: ./Makefile)
    -l logfile      write details of actions to logfile (def: send to stdout)

Exit codes:
     0   all OK
     1   -h and help string printed or -V and version string printed
     2	 command line error
     3	 Makefile not a readable file
     4	 could not make writable log file
 >= 10   some make action exited non-zero

prep.sh version: $PREP_VERSION"

export MAKE="make"
export MAKEFILE="./Makefile"
export V_FLAG="0"
export E_FLAG=
export EXIT_CODE="0"
export O_FLAG=

# parse args
#
while getopts :hv:Veom:M:l: flag; do
    case "$flag" in
    h)	echo "$USAGE" 1>&2
	exit 1
	;;
    v)	V_FLAG="$OPTARG";
	;;
    V)	echo "$PREP_VERSION"
	exit 1
	;;
    m)	export MAKE="$OPTARG";
	;;
    M)	MAKEFILE="$OPTARG";
	;;
    e)	E_FLAG="-e"
	;;
    o)	O_FLAG="-o"
	;;
    l)	LOGFILE="$OPTARG"
	;;
    \?) echo "$0: ERROR: invalid option: -$OPTARG" 1>&2
	echo 1>&2
	echo "$USAGE" 1>&2
	exit 2
	;;
    :)	echo "$0: ERROR: option -$OPTARG requires an argument" 1>&2
	echo 1>&2
	echo "$USAGE" 1>&2
	exit 2
	;;
    *)
	;;
    esac
done

# check args
#
shift $(( OPTIND - 1 ));
if [[ $# -ne 0 ]]; then
    echo "$0: ERROR: expected 0 arguments, found $#" 1>&2
    exit 2
fi

# firewall
#
if [[ ! -e $MAKEFILE ]]; then
    echo "$0: ERROR: Makefile not found: $MAKEFILE" 1>&2
    exit 3
fi
if [[ ! -f $MAKEFILE ]]; then
    echo "$0: ERROR: Makefile not a regular file: $MAKEFILE" 1>&2
    exit 3
fi
if [[ ! -r $MAKEFILE ]]; then
    echo "$0: ERROR: Makefile not a readable file: $MAKEFILE" 1>&2
    exit 3
fi

# if -l logfile was specified, remove it and recreate it to start out empty
#
if [[ -n "$LOGFILE" ]]; then
    rm -f "$LOGFILE"
    touch "$LOGFILE"
    if [[ ! -f "${LOGFILE}" ]]; then
	echo "$0: ERROR: couldn't create log file" 1>&2
	exit 4
    fi
    if [[ ! -w "${LOGFILE}" ]]; then
	echo "$0: ERROR: log file not writable" 1>&2
	exit 4
    fi
fi

# Determine the name of the jparse_bug_report.sh log file
#
# NOTE: this log file does not have an underscore in the name because we want to
# distinguish it from this script which does have an underscore in it.
#
BUG_REPORT_LOGFILE="bug-report.$(/bin/date +%Y%m%d.%H%M%S).txt"
export BUG_REPORT_LOGFILE

# write_echo - write a message to either the log file or both the log file and
# stdout
#
write_echo()
{
    local MSG="$*"

    if [[ -n "$LOGFILE" ]]; then
	if [[ "$MSG" != "OK" ]]; then
	    echo "$MSG" | tee -a -- "$LOGFILE"
	else
	    echo "$MSG"
	fi
    else
	echo "$MSG" 1>&2
    fi
}

# write_echo_n - write a message to either the log file or both the log file and
# stdout but without a trailing newline
write_echo_n()
{
    local MSG="$*"

    if [[ -n "$LOGFILE" ]]; then
	echo -n "$MSG" | tee -a -- "$LOGFILE"
    else
	echo -n "$MSG" 1>&2
    fi
}

# write_logfile - write a message to the log file, if we have one, otherwise to stderr
#
write_logfile()
{
    local MSG="$*"

    if [[ -n "$LOGFILE" ]]; then
	echo "$MSG" >> "$LOGFILE"
    else
	echo "$MSG" 1>&2
    fi
}

# exec_command - invoke command redirecting output only to the log file or to
# both stdout and the log file
exec_command()
{
    local COMMAND=$*
    if [[ -n "$LOGFILE" ]]; then
	# SC2086 (info): Double quote to prevent globbing and word splitting.
	# https://www.shellcheck.net/wiki/SC2086
	# shellcheck disable=SC2086
	command ${COMMAND} >> "$LOGFILE" 2>&1
	return $?
    else
	# SC2086 (info): Double quote to prevent globbing and word splitting.
	# https://www.shellcheck.net/wiki/SC2086
	# shellcheck disable=SC2086
	command ${COMMAND} 2>&1
	return $?
    fi

}

# make action
#
# usage:
#	make_action code rule
#
#	code - exit code if rule fails
#	rule - Makefile rule to call
#
make_action() {

    # parse args
    #
    if [[ $# -ne 2 ]]; then
	echo "$0: ERROR: function expects 2 args, found $#" 1>&2
	exit 9
    fi
    local CODE="$1"
    local RULE="$2"

    # announce pre-action
    #
    if [[ -z "$LOGFILE" ]]; then
	write_echo "=-=-= START: $MAKE $RULE =-=-="
	write_echo "$MAKE" -f "$MAKEFILE" "$RULE"
    else
	write_echo_n "make_action $CODE $RULE "
    fi

    # if certain rules check for necessary tools and if they do not exist or
    # they fail, skip the rule.
    if [[ "$RULE" = shellcheck ]]; then
	if ! ./test_jparse/is_available.sh shellcheck; then
	    if [[ -z "$LOGFILE" ]]; then
		write_echo
		write_echo "=-=-= SKIPPED: $MAKE $RULE =-=-="
		write_echo
	    else
		write_echo "SKIPPED"
	    fi
	SKIPPED_SUMMARY="$SKIPPED_SUMMARY
	make_action $CODE $RULE: the shellcheck tool cannot be found or is unreliable on your system.
	We cannot use the shellcheck tool.
	Please consider installing or updating shellcheck tool from:

	    https://github.com/koalaman/shellcheck.net

	or if needed, filing a bug report with those who publish shellcheck.

	Please do NOT file a bug report with us as we do not maintain shellcheck."

	    return
	fi
    elif [[ "$RULE" = picky ]]; then
	if ! ./test_jparse/is_available.sh picky; then
	    if [[ -z "$LOGFILE" ]]; then
		write_echo
		write_echo "=-=-= SKIPPED: $MAKE $RULE =-=-="
		write_echo
	    else
		write_echo "SKIPPED"
	    fi
	SKIPPED_SUMMARY="$SKIPPED_SUMMARY
	make_action $CODE $RULE: the picky tool cannot be found or is unreliable on your system.
	We cannot use the picky tool.
	Please consider installing or updating picky tool from:

	    https://github.com/lcn2/picky.git

	Please do NOT file a bug report with us as we do not maintain picky."

	    return
	fi
    elif [[ "$RULE" = depend ]]; then
	if ! ./test_jparse/is_available.sh independ; then
	    if [[ -z "$LOGFILE" ]]; then
		write_echo
		write_echo "=-=-= SKIPPED: $MAKE $RULE =-=-="
		write_echo
	    else
		write_echo "SKIPPED"
	    fi
	SKIPPED_SUMMARY="$SKIPPED_SUMMARY
	make_action $CODE $RULE: the independ tool cannot be found or is unreliable on your system.
	We cannot use the independ tool.
	Please consider installing or updating independ tool from:

	    https://github.com/lcn2/independ.git

	Please do NOT file a bug report with us as we do not maintain independ."


	    return
	fi
    elif [[ "$RULE" = seqcexit ]]; then
	if ! ./test_jparse/is_available.sh seqcexit; then
	    if [[ -z "$LOGFILE" ]]; then
		write_echo
		write_echo "=-=-= SKIPPED: $MAKE $RULE =-=-="
		write_echo
	    else
		write_echo "SKIPPED"
	    fi
	SKIPPED_SUMMARY="$SKIPPED_SUMMARY
	make_action $CODE $RULE: the seqcexit tool cannot be found or is unreliable on your system.
	We cannot use the seqcexit tool.
	Please consider installing or updating seqcexit tool from:

	    https://github.com/lcn2/seqcexit.git

	Please do NOT file a bug report with us as we do not maintain seqcexit."


	    return
	fi
    elif [[ "$RULE" = check_man ]]; then
	if ! ./test_jparse/is_available.sh checknr; then
	    if [[ -z "$LOGFILE" ]]; then
		write_echo
		write_echo "=-=-= SKIPPED: $MAKE $RULE =-=-="
		write_echo
	    else
		write_echo "SKIPPED"
	    fi
	SKIPPED_SUMMARY="$SKIPPED_SUMMARY
	make_action $CODE $RULE: the checknr tool cannot be found or is unreliable on your system.
	We cannot use the checknr tool.
	Please consider installing or updating checknr tool from:

	    https://github.com/lcn2/checknr.git

	Please do NOT file a bug report with us as we do not maintain picky."

	    return
	fi

    fi

    # perform action
    #
    exec_command "$MAKE" -f "$MAKEFILE" VERBOSITY="$V_FLAG" "$RULE"
    status="$?"
    if [[ $status -ne 0 ]]; then

	# process a make action failure
	#
	EXIT_CODE="$CODE"

	FAILURE_SUMMARY="$FAILURE_SUMMARY
	make_action $EXIT_CODE: $MAKE -f $MAKEFILE VERBOSITY=$V_FLAG $RULE: non-zero exit code: $status"
	if [[ -z "$LOGFILE" ]]; then
	    write_echo "$0: Warning: EXIT_CODE is now: $EXIT_CODE" 1>&2
	fi
	if [[ -n $E_FLAG ]]; then
	    if [[ -z "$LOGFILE" ]]; then
		write_echo
		write_echo "$0: ERROR: $MAKE -f $MAKEFILE VERBOSITY=$V_FLAG $RULE exit status: $status" 1>&2
		write_echo
		write_echo "=-=-= FAIL: $MAKE $RULE =-=-="
		write_echo
	    else
		write_echo "ERROR exit code $status"
	    fi
	    exit "$EXIT_CODE"
	else
	    if [[ -z "$LOGFILE" ]]; then
		write_echo
		write_echo "$0: Warning: $MAKE -f $MAKEFILE VERBOSITY=$V_FLAG $RULE exit status: $status" 1>&2
		write_echo
		write_echo "=-=-= FAIL: $MAKE $RULE =-=-="
		write_echo
	    else
		write_echo "ERROR exit code $status"
	    fi
	fi

    # announce post-action
    #
    else
	if [[ -z "$LOGFILE" ]]; then
	    write_echo
	    write_echo "=-=-= PASS: $MAKE $RULE =-=-="
	    write_echo
	else
	    write_echo "OK"
	fi
    fi
    return 0;
}

# make bug report
#
# usage:
#	make_jparse_bug_report code
#
#	code - exit code if script fails
#
make_jparse_bug_report() {

    # parse args
    #
    if [[ $# -ne 1 ]]; then
	echo "$0: ERROR: function expects 1 arg, found $#" 1>&2
	exit 9
    fi
    local CODE="$1"

    # announce pre-action
    #
    if [[ -z "$LOGFILE" ]]; then
	write_echo "=-=-= START: $MAKE bug_report-txl VERBOSITY=$V_FLAG -L $BUG_REPORT_LOGFILE =-=-="
    else
	write_echo_n "make_action $CODE bug_report-txl VERBOSITY=$V_FLAG -L $BUG_REPORT_LOGFILE "
    fi

    # perform action
    #
    exec_command "./jparse_bug_report.sh" -t -x -l VERBOSITY="$V_FLAG" -L "$BUG_REPORT_LOGFILE"
    status="$?"

    # Finally we report on the exit status of the jparse_bug_report.sh
    #
    if [[ $status -ne 0 ]]; then

	# process a jparse_bug_report.sh failure (i.e. error or actual issue
	# detected, NOT ONLY a warning)
	#
	EXIT_CODE="$CODE"

	FAILURE_SUMMARY="$FAILURE_SUMMARY
	$MAKE bug_report-txl $EXIT_CODE: ./jparse_bug_report-txl -v $V_FLAG -L $BUG_REPORT_LOGFILE: non-zero exit code: $status"
	if [[ -z "$LOGFILE" ]]; then
	    write_echo "$0: Warning: EXIT_CODE is now: $EXIT_CODE" 1>&2
	fi
	if [[ -n $E_FLAG ]]; then
	    if [[ -z "$LOGFILE" ]]; then
		write_echo
		write_echo "$0: Warning: ./jparse_bug_report-txl -v $V_FLAG -L $BUG_REPORT_LOGFILE exit status: $status" 1>&2
		write_echo
		write_echo "=-=-= FAIL: ./jparse_bug_report-txl -v $V_FLAG -L $BUG_REPORT_LOGFILE =-=-="
		write_echo
	    else
		write_echo "ERROR exit code $status"
	    fi
	    exit "$EXIT_CODE"
	else
	    if [[ -z "$LOGFILE" ]]; then
		write_echo
		write_echo "$0: Warning: ./jparse_bug_report-txl -v $V_FLAG -L $BUG_REPORT_LOGFILE exit status: $status" 1>&2
		write_echo
		write_echo "=-=-= FAIL: $MAKE $RULE =-=-="
		write_echo
	    else
		write_echo "ERROR exit code $status"
	    fi
	fi
    # announce post-action
    #
    else
	if [[ -z "$LOGFILE" ]]; then
	    write_echo
	    write_echo "=-=-= PASS: ./jparse_bug_report-txl -v $V_FLAG -L $BUG_REPORT_LOGFILE =-=-="
	    write_echo
	else
	    write_echo "OK"
	fi
    fi
    return 0;
}


# perform make actions
#
if [[ -z "$LOGFILE" ]]; then
    write_echo "=-=-=-=-= START: $0 =-=-=-=-="
    write_echo
fi
make_action 10 clobber
make_action 11 all
make_action 12 depend
make_action 13 all
if [[ -n $O_FLAG ]]; then
    make_action 14 parser-o
else
    make_action 15 parser
fi
make_action 16 all
make_action 17 load_json_ref
make_action 18 use_json_ref
make_action 19 clean_generated_obj
make_action 20 all
make_jparse_bug_report 21
make_action 22 shellcheck
make_action 23 seqcexit
make_action 24 picky
make_action 25 tags
make_action 26 check_man
make_action 27 all
make_action 28 test

# If we have a logfile, count the number of Notice: messages in the logfile
#
LOGFILE_NOTICE_COUNT=0
export NOTICE_COUNT
if [[ -n "$LOGFILE" ]]; then
    LOGFILE_NOTICE_COUNT="$(grep -cE "[[:space:]]+Notice:[[:space:]]" "$LOGFILE")"
    if [[ $LOGFILE_NOTICE_COUNT -gt 0 ]]; then
	write_logfile
	write_logfile "=-=-= Summary of prep.sh notices follow:"
	write_logfile
	NOTICE_SET=$(grep -E "[[:space:]]+Notice:[[:space:]]" "$LOGFILE")
	write_logfile "$NOTICE_SET"
	write_logfile
	write_logfile "=-=-= End of of prep.sh notice summary"
    fi
fi

# If the bug report log still exists, get how many notices were
# issued. We will use this at the final report of the script.
#
if [[ -e "$BUG_REPORT_LOGFILE" ]]; then
    NOTICE_COUNT="$(grep -cE "[[:space:]]+Notice:[[:space:]]" "$BUG_REPORT_LOGFILE")"

    # Next we summarize Notices and Warnings directly the logfile
    #
    write_logfile "=-=-= jparse_bug_report.sh generated $NOTICE_COUNT notices in $BUG_REPORT_LOGFILE"
    if [[ $NOTICE_COUNT -gt 0 ]]; then
	write_logfile
	write_logfile "=-=-= Summary of make_jparse_bug_report notices follow:"
	write_logfile
	NOTICE_SET=$(grep -E "[[:space:]]+Notice:[[:space:]]" "$BUG_REPORT_LOGFILE")
	write_logfile "$NOTICE_SET"
	write_logfile
	write_logfile "=-=-= End of of make_jparse_bug_report notice summary"
    fi
fi

# Add any logfile notice count to the bug report log notice count.
#
((NOTICE_COUNT=NOTICE_COUNT+LOGFILE_NOTICE_COUNT))

if [[ $EXIT_CODE -eq 0 ]]; then
    if [[ -z "$LOGFILE" ]]; then
	write_echo "=-=-=-=-= PASS: $0 =-=-=-=-="
	write_echo
	if [[ $NOTICE_COUNT -gt 0 ]]; then
	    if [[ $NOTICE_COUNT -eq 1 ]]; then
		write_echo "jparse_bug_report.sh issued $NOTICE_COUNT notice."
	    else
		write_echo "jparse_bug_report.sh issued $NOTICE_COUNT notices."
	    fi
	fi
	if [[ -n "$SKIPPED_SUMMARY" ]]; then
	    write_echo "One or more tests were skipped:"
	    write_echo "$SKIPPED_SUMMARY"
	fi
    else
	if [[ $NOTICE_COUNT -gt 0 ]]; then
	    if [[ $NOTICE_COUNT -eq 1 ]]; then
		write_echo "jparse_bug_report.sh issued $NOTICE_COUNT notice."
	    else
		write_echo "All tests PASSED; $NOTICE_COUNT notices issued."
	    fi
	fi
	if [[ -n "$SKIPPED_SUMMARY" ]]; then
	    write_echo "One or more tests were skipped:"
	    write_echo "$SKIPPED_SUMMARY"
	fi
	if [[ $NOTICE_COUNT -eq 0 && -z "$SKIPPED_SUMMARY" ]]; then
	    write_echo "All tests PASSED."
	fi
    fi
    # We have logged notices, no errors so we can remove the bug report log file now.
    rm -f "$BUG_REPORT_LOGFILE"
else
    if [[ -z "$LOGFILE" ]]; then
	write_echo "=-=-=-=-= FAIL: $0 =-=-=-=-="
	write_echo
	write_echo "=-=-=-=-= Will exit: $EXIT_CODE =-=-=-=-="
	write_echo
	if [[ -n "$FAILURE_SUMMARY" ]]; then
	    write_echo "One or more tests failed:"
	    write_echo "$FAILURE_SUMMARY"
	fi
	write_echo ""
	if [[ $NOTICE_COUNT -gt 0 ]]; then
	    if [[ $NOTICE_COUNT -eq 1 ]]; then
		write_echo "jparse_bug_report.sh issued $NOTICE_COUNT notice."
	    else
		write_echo "jparse_bug_report.sh issued $NOTICE_COUNT notices."
	    fi
	fi
	if [[ -e test_jparse/jparse_test.log ]]; then
	    write_echo ""
	    write_echo "See test_jparse/jparse_test.log for more details."
	fi
    else
	if [[ -n "$FAILURE_SUMMARY" ]]; then
	    write_echo "One or more tests failed:"
	    write_echo "$FAILURE_SUMMARY"
	    write_echo ""
	fi
	if [[ $NOTICE_COUNT -gt 0 ]]; then
	    if [[ $NOTICE_COUNT -eq 1 ]]; then
		write_echo "One or more tests failed; $NOTICE_COUNT notice issued."
	    else
		write_echo "One or more tests failed; $NOTICE_COUNT notices issued."
	    fi
	else
	    write_echo "One or more tests failed."
	fi
	if [[ -e test_jparse/jparse_test.log ]]; then
	    write_echo ""
	    write_echo "See test_jparse/jparse_test.log for more details."
	fi
    fi
fi

# Note at the very end if we find a non-empty Makefile.local containing non-comments
#
# Because this is just a potential warning, we do not perform this as an action.
#
export NOT_A_COMMENT="test_jparse/not_a_comment.sh"
if [[ ! -e $NOT_A_COMMENT ]]; then
    write_echo "Warning: executable not found: $NOT_A_COMMENT"
elif [[ ! -f $NOT_A_COMMENT ]]; then
    write_echo "Warning: not a file: $NOT_A_COMMENT"
elif [[ ! -x $NOT_A_COMMENT ]]; then
    write_echo "Warning: not an executable file: $NOT_A_COMMENT"
else
    # SC2046 (warning): Quote this to prevent word splitting.
    #
    # The paths printed by find will not word split.
    #
    # https://www.shellcheck.net/wiki/SC2046
    # shellcheck disable=SC2046
    if ! "$NOT_A_COMMENT" $(find . -name 'Makefile.local' -print 2>/dev/null) >/dev/null 2>&1; then
	write_echo ""
	write_echo "Notice: Found non-comments in some Makefile.local file(s)."
	write_echo "Notice: Be sure that these Makefile.local file(s) will not skew the results above."
	write_logfile
	write_logfile "=-=-= output from test_jparse/not_a_comment.sh -v 1 follows:"
	write_logfile
	# SC2046 (warning): Quote this to prevent word splitting.
	#
	# The paths printed by find will not word split.
	#
	# https://www.shellcheck.net/wiki/SC2046
	# shellcheck disable=SC2046
	FOUND=$("$NOT_A_COMMENT" -v 1 $(find . -name 'Makefile.local' -print 2>/dev/null) 2>&1)
	write_logfile "$FOUND"
	write_logfile
	write_logfile "=-=-= End of output from test_jparse/not_a_comment.sh -v 1"
    fi
fi



# All Done!!! All Done!!! -- Jessica Noll, Age 2
#
exit "$EXIT_CODE"
