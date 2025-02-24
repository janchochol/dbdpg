#!perl

## Spellcheck as much as we can

use 5.006;
use strict;
use warnings;
use Test::More;
use utf8;
select(($|=1,select(STDERR),$|=1)[1]);

my (@testfiles, $fh);

if (! $ENV{AUTHOR_TESTING}) {
	plan (skip_all =>  'Test skipped unless environment variable AUTHOR_TESTING is set');
}
elsif (!eval { require Text::SpellChecker; 1 }) {
	plan skip_all => 'Could not find Text::SpellChecker';
}
else {
	opendir my $dir, 't' or die qq{Could not open directory 't': $!\n};
	@testfiles = map { "t/$_" } grep { /^.+\.(t|pl)$/ } readdir $dir;
	closedir $dir or die qq{Could not closedir "$dir": $!\n};
	plan tests => 18+@testfiles;
}

my %okword;
my $file = 'Common';
while (<DATA>) {
	if (/^## (.+):/) {
		$file = $1;
		next;
	}
	next if /^#/ or ! /\w/;
	for (split) {
		$okword{$file}{$_}++;
	}
}


sub spellcheck {
	my ($desc, $text, $filename) = @_;
	my $check = Text::SpellChecker->new(text => $text, lang => 'en_US');
	my %badword;
	while (my $word = $check->next_word) {
		next if $okword{Common}{$word} or $okword{$filename}{$word};
		$badword{$word}++;
	}
	my $count = keys %badword;
	if (! $count) {
		pass ("Spell check passed for $desc");
		return;
	}
	fail ("Spell check failed for $desc. Bad words: $count");
	for (sort keys %badword) {
		diag "$_\n";
	}
	return;
}


## First, the plain ol' textfiles
for my $file (qw/README Changes TODO README.dev README.win32/) {
	if (!open $fh, '<', $file) {
		fail (qq{Could not find the file "$file"!});
	}
	else {
		{ local $/; $_ = <$fh>; }
		close $fh or warn qq{Could not close "$file": $!\n};
		if ($file eq 'Changes') {
			s{\b(?:from|by) [A-Z][\w \.]+[<\[\n]}{}gs;
			s{\b[Tt]hanks to (?:[A-Z]\w+\W){1,3}}{}gs;
			s{Abhijit Menon-Sen}{}gs;
			s{eg/lotest.pl}{};
			s{\[.+?\]}{}gs;
			s{\S+\@\S+\.\S+}{}gs;
			s{git commit [a-f0-9]+}{git commit}gs;
            s{B.*lint Szilakszi}{}gs;
		}
		elsif ($file eq 'README.dev') {
			s/^\t\$.+//gsm;
		}
		spellcheck ($file => $_, $file);
	}
}

## Now the embedded POD
SKIP: {
	if (!eval { require Pod::Spell; 1 }) {
		skip ('Need Pod::Spell to test the spelling of embedded POD', 2);
	}

	for my $file (qw{Pg.pm lib/Bundle/DBD/Pg.pm}) {
		if (! -e $file) {
			fail (qq{Could not find the file "$file"!});
		}
		my $string = qx{podspell $file};
		spellcheck ("POD from $file" => $string, $file);
	}
}

## Now the comments
SKIP: {
	if (!eval { require File::Comments; 1 }) {
		skip ('Need File::Comments to test the spelling inside comments', 11+@testfiles);
	}
    {
		## For XS files...
		package File::Comments::Plugin::Catchall; ## no critic
		use strict;
		use warnings;
		require File::Comments::Plugin;
		require File::Comments::Plugin::C;

		our @ISA     = qw(File::Comments::Plugin::C);

		sub applicable {
			my($self) = @_;
			return 1;
		}
	}


	my $fc = File::Comments->new();

	my @files;
	for (sort @testfiles) {
		push @files, "$_";
	}


	for my $file (@testfiles, qw{Makefile.PL Pg.xs Pg.pm lib/Bundle/DBD/Pg.pm
        dbdimp.c dbdimp.h types.c quote.c quote.h Pg.h types.h}) {
		## Tests as well?
		if (! -e $file) {
			fail (qq{Could not find the file "$file"!});
		}
		my $string = $fc->comments($file);
		if (! $string) {
			fail (qq{Could not get comments from file $file});
			next;
		}
		$string = join "\n" => @$string;
		$string =~ s/=head1.+//sm;
		spellcheck ("comments from $file" => $string, $file);
	}


}


__DATA__
## These words are okay

## Common:

AutoInactiveDestroy
grokbase
ActiveKids
adbin
adsrc
AIX
API
archlib
arith
arrayref
arrayrefs
async
attr
attrib
attribs
authtype
autocommit
AutoCommit
AutoEscape
backend
backtrace
bitmask
blib
bool
booleans
bools
bt
BUFSIZE
Bunce
bytea
BYTEA
CachedKids
cancelled
carlos
Checksum
checksums
Checksums
ChildHandles
chopblanks
ChopBlanks
cmd
CMD
CompatMode
conf
config
conformant
coredump
Coredumps
cpan
CPAN
cpansign
cperl
creat
CursorName
cvs
cx
datatype
Datatype
DATEOID
datetime
DATETIME
dbd
DBD
dbdimp
dbdpg
DBDPG
dbgpg
dbh
dbi
DBI
DBI's
DBIx
dbivport
DBIXS
dbmethod
dbname
DDL
deallocate
Debian
decls
Deepcopy
dequote
dequoting
dev
devel
Devel
dHTR
dir
dirname
discon
distcheck
disttest
DML
dollaronly
dollarsign
dr
drh
DSN
dv
emacs
endcopy
enum
env
ENV
ErrCount
errorlevel
errstr
eval
externs
ExtUtils
fe
FetchHashKeyName
fh
filename
FreeBSD
func
funct
GBorg
gcc
GCCDEBUG
gdb
getcopydata
getfd
getline
github
GH
greg
GSM
HandleError
HandleSetErr
hashref
hba
html
http
ifdefs
ifndefs
InactiveDestroy
includedir
IncludingOptionalDependencies
initdb
inout
installarchlib
installsitearch
INSTALLVENDORBIN
IP
ish
Kbytes
largeobject
lcrypto
ld
LD
ldconfig
LDDFLAGS
len
lgcc
libpq
libpqswip
linux
LOBs
localhost
LongReadLen
LongTruncOk
lpq
LSEG
lssl
machack
Makefile
MakeMaker
malloc
MCPAN
md
Mdevel
Mergl
metadata
mis
Momjian
Mullane
multi
ness
Newz
nntp
nonliteral
noprefix
noreturn
nosetup
notused
nullable
NULLABLE
num
numbound
ODBC
ODBCVERSION
oid
OID
onerow
param
params
ParamTypes
ParamValues
parens
passwd
patchlevel
pch
perl
perlcritic
perlcriticrc
perldocs
PGBOOLOID
PgBouncer
pgbuiltin
PGCLIENTENCODING
pgend
pglibpq
pglogin
PGP
PGPORT
pgprefix
PGRES
PGresult
pgsql
pgstart
pgtype
pgver
php
pid
PID
PlanetPostgresql
POSIX
Postgres
POSTGRES
postgres
postgresql
PostgreSQL
powf
PQclear
PQconnectdb
PQconsumeInput
PQexec
PQexecParams
PQexecPrepared
PQprepare
PQprotocolVersion
PQresultErrorField
PQsendQuery
PQserverVersion
PQsetErrorVerbosity
pragma
pragmas
pre
preparse
preparser
prepending
PrintError
PrintWarn
projdisplay
putcopydata
putcopyend
putline
pv
pwd
qual
qw
RaiseError
RDBMS
README
ReadOnly
realclean
RedHat
relcheck
requote
RowCache
RowCacheSize
RowsInCache
runtime
Sabino
safemalloc
savepoint
savepoints
Savepoints
sbin
schemas
SCO
Sep
SGI
sha
ShowErrorStatement
sitearch
skipcheck
smethod
snprintf
Solaris
sprintf
sql
SQL
sqlstate
SQLSTATE
SSL
sslmode
stderr
STDERR
STDIN
STDOUT
sth
strcpy
strdup
strerror
stringification
strlen
STRLEN
strncpy
structs
submitnews
Sv
svn
tablename
tablespace
tablespaces
TaintIn
TaintOut
TCP
tempdir
testdatabase
testname
tf
TID
TIMEOID
timestamp
TIMESTAMP
TIMESTAMPTZ
tmp
TMP
TODO
TraceLevel
tuple
TUPLES
turnstep
txn
typename
uid
undef
unicode
unix
UNKNOWNOID
userid
username
Username
usr
UTC
utf
UTF
Util
valgrind
varchar
VARCHAR
VARCHAROID
VER
versioning
veryverylongplaceholdername
Waggregate
Wbad
Wcast
Wchar
Wcomment
Wconversion
Wdeclaration
Wdisabled
weeklynews
Wendif
Wextra
wfile
Wfloat
Wformat
whitespace
Wimplicit
Winit
Winline
Winvalid
Wmain
Wmissing
Wnested
Wnonnull
Wpacked
Wpadded
Wparentheses
Wpointer
Wredundant
Wreturn
writeable
Wsequence
Wshadow
Wsign
Wstrict
Wswitch
Wsystem
Wtraditional
Wtrigraphs
Wundef
Wuninitialized
Wunknown
Wunreachable
Wunused
Wwrite
www
xs
xsi
xst
XSUB
yaml
YAML
yml
JSON
PQsetSingleRowMode
quickexec

## TODO:
ala
hstore
cpantesters
hashrefs
rowtypes
struct
bucardo
github
https

## README.dev:
abc
pgp
dbix
shortid
bucardo
Conway's
cpantesters
distro
DProf
dprofpp
gpl
GPL
leaktester
mak
mathinline
MDevel
nCompiled
nServer
NYTProf
nytprofhtml
profiler
pulldown
repo
scsys
spellcheck
SvTRUE
testallversions
testfile
testme
txt
uk
XSubPPtmpAAAA
json
MYMETA

## README:
BOOTCHECK
bucardo
cabrion
CentOS
conf
cryptographically
danla
david
dll
dllname
dlltool
dmake
drnoble
DynaLoader
Eisentraut
engsci
EXTRALIBS
fe
freenode
Gcc
gmx
hdf
irc
jmore
landgren
Landgren
Lauterbach
LDLOADLIBS
MAKEFILE
pc
pexports
PROGRA
sandia
sco
sl
sv
testdb
turnstep
Ubuntu

## Changes:
Bálint
Github
Refactor
SvNVs
signalling
bigint
boolean
bucardo
destringifying
expr
ints
Garamond
gborg
Hofmann
BIGINT
jsontable
largeobjects
repo
BMP
NOSUCH
PGINITDB
tableinfo
dTHX
bpchar
oids
perls
reinstalling
spclocation
Kai
marshalling
n's
optimizations
Perlish
Pg's
Pieter
qw
regex
spellcheck
Szilakszi
uc
VC

## Pg.pm:
onwards
Oid
pseudotype
lseg
afterwards
hashrefs
PGSYSCONFDIR
PGSERVICE

## Pg.xs:
PQexec
stringifiable
struct

## dbdimp.c:
Bytea
DefaultValue
PQstatus
SvPV
SvUTF
alphanum
pos
pqtype
rescan
resultset
ABCD
AvARRAY
BegunWork
COPYing
DBIc
Deallocate
Deallocation
ExecStatusType
INV
NULLs
Oid
PQoids
PQvals
PGRES
ROK
StartTransactionCommand
backend's
backslashed
boolean
cancelling
copypv
copystate
coredumps
currph
currpos
dashdash
deallocating
defaultval
dereference
destringify
dollarquote
dollarstring
encodings
fallthrough
firstword
getcom
inerror
login
mortalize
myval
n'egative
nullable
numphs
numrows
ok
p'ositive
paramTypes
Perlish
ph
preparable
proven
quickexec
recv'd
reprepare
repreparing
req
scs
sectionstop
slashslash
slashstar
sqlclient
starslash
stringify
sv
topav
topdollar
tuples
typedef
unescaped
untrace
versa
xPID

## dbdimp.h:
PQ
SSP
funcs
implementor
ph

## quote.c:
arg
Autogenerate
compat
downcase
elsif
estring
gotlist
kwlist
lsegs
maxlen
mv
ofile
qq
src
strcmp
strtof
SVs
tempfile

## types.c:
ASYNC
Autogenerate
basename
BIGINT
BOOLOID
DESCR
LONGVARCHAR
OLDQUERY
PASSBYVAL
ParseData
ParseHeader
SMALLINT
SV
TINYINT
VARBINARY
ndone
arg
arrayout
binin
binout
boolout
bpchar
chr
cid
cmp
dat
delim
descr
dq
elsif
lseg
maxlen
mv
newfh
oct
ok
oldfh
pos
printf
qq
slashstar
starslash
sqlc
sqltype
src
struct
svtype
tcase
tdTHX
tdefault
textin
textout
thisname
tid
timestamptz
tswitch
typarray
typdelim
typedef
typefile
typelem
typinput
typname
typoutput
typrecv
typrelid
typsend
uc

## types.h:
Nothing

## Pg.h:
DBILOGFP
DBIS
PGfooBar
PYTHIAN
THEADER
cpansearch
ocitrace
preprocessors
src
xxh

## Makefile.PL:
prereqs
subdirectory

## t/07copy.t:
copystate

## t/03dbmethod.t:
CamelCase
Multi
arrayref
fk
fktable
intra
odbcversion
pktable
selectall
selectcol
selectrow
untrace

## t/01constants.t:
RequireUseWarnings
TSQUERY

## t/99_yaml.t:
YAMLiciousness

## t/02attribs.t:
INV
NUM
PARAMS
encodings
lc
msg
uc

## t/03smethod.t:
ArrayTupleFetch
SSP
arg
fetchall
fetchrow
undefs

## t/12placeholders.t:
encodings
https
LEFTARG
RIGHTARG

## t/99_spellcheck.t:
gsm
sm
Spellcheck
ol
textfiles

## README.win32:
DRV
ITHREADS
MSVC
MULTI
SYS
VC
Vc
cd
exe
frs
gz
libpg
mak
mkdir
myperl
pgfoundry
nmake
rc
src
vcvars
xcopy
GF
Gf
ITHREADS
MSVC
MULTI
SYS
VC
Vc
cd
exe
gz
libpg
mak
mkdir
myperl
nmake
rc
src
vcvars
xcopy
