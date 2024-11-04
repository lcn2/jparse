# jparse -  JSON parser, library and tools written in C


`jparse` is a JSON parser (a stand-alone tool and a library) written in C with
the help of `flex(1)` and `bison(1)`. The library, and the additional tools,
were co-developed in 2022 by:

*@xexyl* (**Cody Boone Ferguson**, [https://xexyl.net](https://xexyl.net),
[https://ioccc.xexyl.net](https://ioccc.xexyl.net))

and:

*chongo* (**Landon Curt Noll**, [http://www.isthe.com/chongo/index.html](http://www.isthe.com/chongo/index.htm)) /\oo/\

in support of the **IOCCC** ([International Obfuscated C Code
Contest](https://www.ioccc.org)), originally in the [mkiocccentry
repo](https://github.com/ioccc-src/mkiocccentry), but we provide it here so that
anyone may use it.

As a stand-alone tool, `jparse` itself is less useful, except for validating JSON
documents/strings, and to see how it works. The library is much more useful
because you can integrate it into your own applications and work with the parsed
tree(s). More details (beyond the man page) on the library will be documented at
a later date, depending on need, although we do give a fair bit of information below.

We also have some additional tools, some of which will be documented later and
some of which are documented below, namely `jstrdecode` and `jstrencode`.

We recommend that you read the
[json_README.md](https://github.com/xexyl/jparse/blob/master/json_README.md)
document to better understand the JSON terms used in this repo.

# Table of Contents

- [Dependencies](#dependencies)
- [Compiling](#compiling)
- [Installing](#installing)
- [Uninstalling](#uninstalling)
- [jparse stand-alone tool](#jparse-tool)
- [jparse library](#jparse-library)
- [jstrdecode: a tool to decode JSON encoded strings](#jstrdecode)
- [jstrencode: a tool to encode JSON decoded strings](#jstrencode)
- [Testing suite](#test-suite)
- [Reporting bugs](#reporting-bugs)
- [See also](#see-also)
- [History](#history)


<div id="dependencies"></div>

# Dependencies

In order to compile and use `jparse` (the applications and the library) you will
need to download, compile and install the [dbg
repo](https://github.com/lcn2/dbg) and the [dyn_array
repo](https://github.com/lcn2/dyn_array).

To clone, make and install these dependencies:

```sh
git clone https://github.com/lcn2/dbg
cd dbg && make all
# then as root or via sudo:
make install

git clone https://github.com/lcn2/dyn_array
cd dyn_array
make all
# then as root or via sudo:
make install
```

The default `PREFIX` to the install rules is `/usr/local` but if you need to
change this, say due to a system policy, you can do so with the `PREFIX`
variable. For instance if you need or want to install the libraries to
`/usr/lib` and the binaries to `/usr/bin` etc. you can do instead:

```sh
make PREFIX=/usr install
```

Of course, you can specify a different `PREFIX` than `/usr` if you wish.
Remember if you do this though, that if you uninstall them, you will have to
specify the same `PREFIX`.

If there are any issues with compiling or installing either of these, then
please open an issue in the respective repo.


<div id="compiling"></div>

# Compiling

The parser uses both `flex(1)` and `bison(1)` but we determine if you have a
recent enough version of each, and if you do not we use the backup files (the
ones we generate when a `flex(1)` or `bison(1)` file is changed).

Either way, to compile you need only run:


```sh
make all
```

<div id="installing"></div>

# Installing

If you wish to install this, which is **highly** recommended, especially if you
want to use the library, you can do as root or via sudo:

```sh
make install
```

We also support the `PREFIX` standard so if you need to install the binaries to
`/usr/bin`, library to `/usr/lib`, the header files to `/usr/include/jparse` and
the man pages to `/usr/share/man/man[138]`, then do:

```sh
make PREFIX=/usr install
```

Of course, you can specify a different `PREFIX` than `/usr` if you wish.


<div id="uninstalling"></div>

# Uninstalling

If you wish to deobfuscate your system a bit :-), you can uninstall the programs,
library and header files by running as root or by sudo:

```sh
make uninstall
```

If you installed to a different `PREFIX` than the default then you must specify
that same `PREFIX`. For instance if you installed with the `PREFIX` of `/usr`
then you must do instead:

```
make PREFIX=/usr uninstall
```


<div id="jparse-tool"></div>

# jparse stand-alone tool

As a tool by itself `jparse` takes a block of memory from either a file (stdin
or a text file) or a string (via `-s` option) and parses it as JSON, reporting
if it is validly formed JSON or not.

<div id="jparse-synopsis"></div>

## jparse synopsis


```sh
jparse [-h] [-v level] [-J level] [-q] [-V] [-s] -- arg
```

The `-v` option increases the overall verbosity level whereas the `-J` option
increases the verbosity of the JSON parser. The `-q` option suppresses some of
the output.

If `-s` is passed the arg is expected to be a string; otherwise it is expected
to be a file.

The options `-V` and `-h` show the version of the parser and the help or usage
string, respectively.


<div id="jparse-exit-codes"></div>

## jparse exit codes

If the JSON is valid the exit status of `jparse` is 0. Different non-zero values
are for different error conditions, or help or version string printed.

<div id="jparse-examples"></div>

## jparse examples

Parse the JSON string `{ "test_mode" : false }`:

```sh
jparse -s '{ "test_mode" : false }'
```

Parse input from stdin (send EOF, usually ctrl-d or ^D, to parse):

```sh
jparse -
[]
^D
```

Parse just a negative number:

```sh
jparse -s -- -5
```

Parse .info.json file:

```sh
jparse .info.json
```

<div id="jparse-library"></div>

# jparse library

As a library, `jparse` is much more useful as it allows one to parse JSON in
their application and then interact with the parsed tree.

In order to use the library, you will need to `#include` the necessary header
files and then link in the libraries, the dependencies and the `jparse` library
itself.

<div id="jparse-library-example"></div>

## jparse library example

For a relatively simple example program that uses the library, take a look at
[jparse_main.c](https://github.com/xexyl/jparse/blob/master/jparse_main.c). As
we already gave details on how to use it, we will not do that here. It is,
however, a nice example program to give you a basic idea of how to use the
library, especially as it is commented nicely.

As you will see, in the case of this tool, we include
[jparse_main.h](https://github.com/xexyl/jparse/blob/master/jparse_main.h),
which includes the two most useful header files,
[jparse.h](https://github.com/xexyl/jparse/blob/master/jparse.h) and
[util.h](https://github.com/xexyl/jparse/blob/master/util.h), the former of
which is required (in actuality, `jparse.h` includes it, but it does not hurt to
include it anyway due to inclusion guards).

We must also link in the libraries.

We explain these details next.


<div id="jparse-header-files"></div>

## jparse header files

As far as using them, there are two ways to go about it. If you install the
library, which again we recommend, you can include them like:

```c
#include <jparse/jparse.h>
#include <jparse/util.h>
```

or you can instead do:

```c
#include <jparse.h>
#include <util.h>
```

and add to your Makefile or compiler line the option
`-I/usr/local/include/jparse`. Naturally the easiest way is the first but the
code in this repo uses the repo's copy, for obvious reasons.


<div id="linking-jparse">

## Linking in the jparse library

In order to use the library you will have to link the static libraries (the
`jparse(3)` library as well as the `dbg` and `dyn_array` libraries) into your
program.

To do this you should pass to the compiler `-ljparse -ldbg -ldyn_array`. For
instance to compile
[json_main.c](https://github.com/xexyl/jparse/blob/master/jparse_main.c), with
the `#include` lines changed to:

```c
#include <jparse/jparse.h>
#include <jparse/util.h>
```

we can compile it like:

```sh
cc jparse_main.c -o jparse -ljparse -ldbg -ldyn_array
```

and expect to find `jparse` in the current working directory.

If you need an example for a Makefile, take a look at the
[Makefile](https://github.com/xexyl/jparse/blob/master/Makefile)'s
`jparse_main.o` and `jparse` rules, to give you an idea.


Once your code has been compiled and linked into an executable, you should be
good to go, although it naturally will obfuscate your code a bit! :-)


<div id="jparse-api-overview"></div>

## jparse API overview

To get an overview of the API, try from the repo directory:

```sh
man ./man/man3/jparse.3
```

or if installed:

```sh
man 3 jparse
```

which gives more information about the most important functions.


<div id="re-entrancy"></div>
<div id="reentrancy"></div>

## Re-entrancy

Although the scanner and parser are both re-entrant, only one parse at one time
in a process has been tested. The testing of more than one parse at the same
time might be done at a later time but that will likely only happen if a tool
requires it.

If it's not clear this means that having more than one parse active in the same
process at the same time is not tested so even though it should be okay there
might be some issues that have yet to be discovered.



<div id="jstrdecode"></div>

# jstrdecode: a tool to decode JSON encoded strings

This tool converts data into JSON decoded strings according to the so-called
[JSON data interchange syntax - ECMA-404](https://www.ecma-international.org/publications-and-standards/standards/ecma-404/).


<div id="jstrdecode-synopsis"></div>

## jstrdecode synopsis


```sh
jstrdecode [-h] [-v level] [-q] [-V] [-t] [-n] [-N] [-Q] [-e] [-E level] [string ...]
```

The `-v` option increases the overall verbosity level. Unlike the `jparse`
utility, no JSON parsing functions are called, so there is no `-J level` option.
The `-q` option suppresses some of the output, although this might not be all
that noticeable.

The options `-V` and `-h` show the version of the parser and the help or usage
string, respectively.

Use `-Q` if you do not want to decode double quotes that enclose the
concatenation of the args.

Use `-e` to not output double quotes that enclose each arg.

If you use `-N` it ignores all newlines. This does not mean that the JSON allows
for unescaped newlines but rather newlines on the command line are ignored, as
if the args are concatenated.

`-E` is kind of undocumented but kind of documented: play with it to see what it
does, should you wish!  :-)

Running it with `-t` performs some sanity checks on JSON encode/decode
functionality and this is not usually needed, although the test suite does do
this.

If no string is given on the command line it expects you to type something on
`stdin`, ending it with EOF.


<div id="jstrdecode-exit-codes"></div>

## jstrdecode exit codes

If the decoding is successful the exit status of `jstrdecode` is 0, otherwise 1.
Different non-zero values are for different error conditions, or help or version
string printed.


<div id="jstrdecode-examples"></div>

## jstrdecode examples

Decode an empty string (`""`):


```sh
jstrdecode '""'
```

This will show:

```
\"\"
```

Decode `"\"`

```sh
jstrdecode '"\"'
```

That will show:

```
\"\\\"
```

If you need to ignore newlines in input, use the `-N` option. For example, here
is the same command with and without the `-N` option:

```sh
$ echo '"\"' | jstrdecode -N
\"\\\"

$ echo '"\"' | jstrdecode
\"\\\"\n
```

Something to note is that this command will not convert an emoji or Unicode
character to its `\uxxxx` form. In fact, for reasons we do not comprehend, this
is perfectly valid JSON:

```json
{ "🔥" "🐉" }
```


For more information and examples, see the man page:

```sh
man ./man/man1/jstrdecode.1
```

from the repo directory, or if installed:

```sh
man jstrdecode
```


**NOTE**: After doing a `make all`, this tool may be found as: `./jstrdecode`.
If you run `make install` (as root or via sudo) you can just do: `jstrdecode`.


<div id="jstrencode"></div>

# jstrencode: a tool to encode JSON decoded strings


This tool converts JSON decoded strings to their original data according to the so-called
[JSON data interchange syntax - ECMA-404](https://www.ecma-international.org/publications-and-standards/standards/ecma-404/).


<div id="jstrencode-synopsis"></div>

## jstrencode synopsis


```sh
 jstrencode [-h] [-v level] [-q] [-V] [-t] [-n] [-N] [-Q] [-e] [-E level] [string ...]
```


The `-v` option increases the overall verbosity level. Unlike the `jparse`
utility, no JSON parsing functions are called, so there is no `-J level` option.
The `-q` option suppresses some of the output, although this might not be all that
noticeable.

The options `-V` and `-h` show the version of the parser and the help or usage
string, respectively.

Use of `-Q` will enclose output in double quotes whereas the use of `-e`
will enclose each encoded string with escaped double quotes.

If you use `-N` it ignores all newlines. This does not mean that the JSON allows
for unescaped newlines but rather newlines on the command line are ignored, as
if the args are concatenated. Use of this option allows for:

```sh
$ echo foo bar | jstrencode
```

to not show:

```
Warning: json_encode: found non-\-escaped char: 0x0a
Warning: jstrencode_stream: error while encoding stdin buffer
Warning: main: error while encoding processing stdin
```

Instead you might see:

```sh
$ printf "foo\nbar" | jstrencode -N
foobar
```

`-E` is kind of undocumented but kind of documented: play with it to see what it
does, should you wish!  :-)

Running it with `-t` performs some sanity checks on JSON encode/decode
functionality and this is not usually needed, although the test suite does do
this.

If no string is given on the command line it expects you to type something on
`stdin`, ending it with EOF.


<div id="jstrencode-exit-codes"></div>

## jstrencode exit codes

If the encoding is successful the exit status of `jstrencode` is 0, otherwise 1.
Different non-zero values are for different error conditions, or help or version
string printed.


<div id="jstrencode-examples"></div>

## jstrencode examples

Encode `\"\"`:


```sh
jstrencode '\"\"'
```

This will show:

```
""
```

Encode a negative number:

```sh
jstrencode -- -5
```

This will show:

```
-5
```

Palaeontologists might like to try `U+1F996` and `U+F995`:

```sh
jstrencode "\uD83E\uDD96\uD83E\uDD95"
```

which will show a T-Rex and a Sauropod (includes Brontosaurus, Diplodocus,
Brachiosaurus):

```
🦖🦕
```

whereas fantasy lovers might like to try `U+1F409`, `U+1FA84` and `U+1F9D9`:

```sh
jstrencode "\uD83D\uDC09\uD83E\uDE84\uD83E\uDDD9"
```

which will show a dragon, a wand and a mage:

```
🐉🪄🧙
```

whereas volcanologists might like to try `U+1F30B`:

```sh
jstrencode "\uD83C\uDF0B"
```

which will show a volcano:


```
🌋
```

whereas alcoholics :-) might like to try `U+1F37B`:

```sh
jstrencode "\uD83C\uDF7B"
```

which will show clinking beer mugs:

```
🍻
```

assuming, in all cases, your system supports displaying such emojis.

Of course you may also use this program to encode diacritics and characters from
other languages.


For more information and examples, see the man page:

```sh
man ./man/man1/jstrencode.1
```

from the repo directory, or if installed:

```sh
man jstrencode
```

**NOTE**: After doing a `make all`, this tool may be found as: `./jstrencode`.
If you run `make install` (as root or via sudo) you can just do: `jstrencode`.




<div id="testing-suite"></div>

# Testing suite:

In the
[jparse/test_jparse](https://github.com/xexyl/jparse/blob/master/test_jparse/README.md)
subdirectory we have a test suite script
[run_jparse_tests.sh](https://github.com/xexyl/jparse/blob/master/test_jparse/run_jparse_tests.sh)
which runs a battery of tests on both valid and invalid JSON files, both as
strings and files, and other things besides. One of the scripts it uses is
[jparse_test.sh](https://github.com/xexyl/jparse/blob/master/test_jparse/jparse_test.sh).
The latter script even checks for invalid location errors.

We have used our own files (with some Easter eggs included due to a shared
interest between Landon and Cody :-) ) as well as the files from the
[JSONTestSuite](https://github.com/nst/JSONTestSuite) (with **MUCH
GRATITUDE** to the maintainers: **THANK YOU!**) and all is good.

Now with these tests in place, if for some reason the parser were to be
modified, in error or otherwise, and the test fails then we know there is a
problem. As the GitHub repo has workflows to make sure that this does not happen
(or rather it alerts us to the problem) it should never be added to the repo
(unless of course we happen to push a commit that does :-) but if that happens
we'll end up fixing it.

If you wish to run this test-suite, try from the repo directory:

```sh
make clobber all test
```

<div id="bug-reporting"></div>
<div id="reporting-bugs"></div>
<div id="bugs"></div>

# Reporting bugs

If you have a problem with this repo in some form, for example you cannot
compile it in your system, or if you think there is a bug of some kind, please
kindly run from the repo directory:

```sh
make bug_report
```

and attach the log file (it will tell you what the name is) to a new issue at
the [jparse issues page](https://github.com/xexyl/jparse/issues). If it's a bug
please select the bug template.

Note that the script,
[jparse_bug_report.sh](https://github.com/xexyl/jparse/blob/master/jparse_bug_report.sh),
will tell you if it finds any problems and if it does not it tells you that you
can safely delete it. Of course just because it does not find any problems does
not necessarily mean there is not a problem. On the other hand, just because it
tells you that there is a problem does not mean that there is a problem with the
repo; it could be your environment or something else entirely.

Please do **NOT** report a problem with JSON: we know that there are a number
of, shall we say, 'issues', but this is not an issue here but rather
[there](https://www.json.org/json-en.html). :-)

<div id="see-also"></div>

# See also

For more information, try from the repo directory:

```sh
man ./man/man1/jparse.1
man ./man/man3/jparse.3
man ./man/man1/jstrdecode.1
man ./man/man1/jstrencode.1
```

or if you have installed everything (i.e. you ran `make install` as root or via
`sudo(1)`) then you can do:

```
man 1 jparse
man 3 jparse
man jstrdecode
man jstrencode
```

**NOTE**: the library man page currently has no example but you can always look
at [jparse_main.c](https://github.com/xexyl/jparse/blob/master/jparse_main.c)
for a relatively simple example (the source code for `jparse(1)` itself, as
described earlier).


<hr>

<div id="history"></div>

# History

It was way back in 1692 when Landon decided that the **IOCCC** ([International
Obfuscated C Code Contest](https://www.ioccc.org)) should use JSON for data
files. Initially a rudimentary parser was in the works but it was decided that a
real parser would be needed and Cody volunteered to help (actually he was
helping before this). We decided to use `flex` and `bison` but we still had to
write thousands of lines of code ourselves. In the end it came to be a solid
parser, both a tool and a library, along with other useful tools.

If you need or just want more details on what happened, and how it progressed,
we suggest you check out the `CHANGES.md` file here and at the [mkiocccentry
repo](https://github.com/ioccc-src/mkiocccentry).

If you really wish to go further than that you can read the GitHub git log in
the `mkiocccentry` repo under the `jparse/` subdirectory, plus the git log at
this jparse repo,  as well as reading the source code. There is a lot to read,
however, so you probably will not want to do that.

If you do read the source code we **STRONGLY** recommend you read the `jparse.l`
and `jparse.y` files and **NOT** the bison or flex generated code! This is
because the generated code might give you nightmares and cause other horrible
symptoms. :-) See
[sorry.tm.ca.h](https://github.com/xexyl/jparse/blob/master/sorry.tm.ca.h) for
more details on this. Of course if you're brave enough to read the generated
code you're welcome to but don't say we did not warn you! :-)

Of course, the code we wrote is well commented and might or might not be worth
reading.
