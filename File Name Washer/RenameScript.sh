#!/usr/bin/perl
# convmv 2.05 - converts filenames from one encoding to another
# Copyright © 2003-2018 Bjoern JACKE <bjoern@j3e.de>
#
# This program comes with ABSOLUTELY NO WARRANTY; it may be copied or modified
# under the terms of the GNU General Public License version 2 or 3 as
# published by the Free Software Foundation.

# to get a man page:
# pod2man --section 1 --center=" " convmv | gzip > convmv.1.gz


=head1 NAME

convmv - converts filenames from one encoding to another

=head1 SYNOPSIS

B<convmv> [B<options>] FILE(S) ... DIRECTORY(S)

=head1 OPTIONS

=over 4

=item B<-f ENCODING>

specify the current encoding of the filename(s) from which should be converted

=item B<-t ENCODING>

specify the encoding to which the filename(s) should be converted

=item B<-i>

interactive mode (ask y/n for each action)

=item B<-r>

recursively go through directories

=item B<--nfc>

target files will be normalization form C for UTF-8 (Linux etc.)

=item B<--nfd>

target files will be normalization form D for UTF-8 (OS X etc.).

=item B<--qfrom> , B<--qto>

be more quiet about the "from" or "to" of a rename (if it screws up your
terminal e.g.). This will in fact do nothing else than replace any non-ASCII
character (bytewise) with ? and any control character with * on printout, this
does not affect rename operation itself.

=item B<--exec> command

execute the given command. You have to quote the command and #1 will be
substituted by the old, #2 by the new filename. Using this option link
targets will stay untouched. Have in mind that #1 and #2 will be quoted
by convmv already, you must not add extra quotation marks around them.

Example:

convmv -f latin1 -t utf-8 -r --exec "echo #1 should be renamed to #2" path/to/files

=item B<--list>

list all available encodings. To get support for more Chinese or Japanese
encodings install the Perl HanExtra or JIS2K Encode packages.

=item B<--lowmem>

keep memory footprint low by not creating a hash of all files. This disables
checking if symlink targets are in subtree. Symlink target pointers will be
converted regardlessly. If you convert multiple hundredthousands or millions of
files the memory usage of convmv might grow quite high. This option would help
you out in that case.

=item B<--nosmart>

by default convmv will detect if a filename is already UTF8 encoded and will
skip this file if conversion from some charset to UTF8 should be performed.
C<--nosmart> will also force conversion to UTF-8 for such files, which might
result in "double encoded UTF-8" (see section below).

=item B<--fixdouble>

using the C<--fixdouble> option convmv does only convert files which will still
be UTF-8 encoded after conversion. That's useful for fixing double-encoded
UTF-8 files. All files which are not UTF-8 or will not result in UTF-8 after
conversion will not be touched. Also see chapter "How to undo double UTF-8 ..."
below.

=item B<--notest>

Needed to actually rename the files. By default convmv will just print what it
wants to do.

=item B<--parsable>

This is an advanced option that people who want to write a GUI front end will
find useful (some others maybe, too). It will convmv make print out what it
would do in an easy parsable way. The first column contains the action or some
kind of information, the second column mostly contains the file that is to be
modified and if appropriate the third column contains the modified value.  Each
column is separated by \0\n (nullbyte newline). Each row (one action) is
separated by \0\0\n (nullbyte nullbyte newline).

=item B<--run-parsable>

This option can be used to blindly execute the output of a previous
B<--parsable> run.  This way it's possible to rename a huge amount of file in
a minimum of time.

=item B<--no-preserve-mtimes>

modifying filenames usually causes the parent directory's mtime being updated.
Since version 2 convmv by default resets the mtime to the old value. If your
filesystem supports sub-second resolution the sub-second part of the atime and
mtime will be lost as Perl does not yet support that. With this option you can
B<disable> the preservation of the mtimes.

=item B<--replace>

if the file to which shall be renamed already exists, it will be overwritten if
the other file content is equal.

=item B<--unescape>

this option will remove this ugly % hex sequences from filenames and turn them
into (hopefully) nicer 8-bit characters. After --unescape you might want to do
a charset conversion. This sequences like %20 etc. are sometimes produced when
downloading via http or ftp.

=item B<--upper> , B<--lower>

turn filenames into all upper or all lower case. When the file is not
ASCII-encoded, convmv expects a charset to be entered via the -f switch.

=item B<--map=>some-extra-mapping

apply some custom character mappings, currently supported are:

ntfs-sfm(-undo), ntfs-sfu(-undo) for the mapping of illegal ntfs characters for
Linux or Macintosh cifs clients (see MS KB 117258 also mapchars mount option of
mount.cifs on Linux).

ntfs-pretty(-undo) for for the mapping of illegal ntfs characters to pretty
legal Japanese versions of them.

See the map_get_newname() function how to easily add own mappings if needed.
Let me know if you think convmv is missing some useful mapping here.

=item B<--dotlessi>

care about the dotless i/I issue. A lowercase version of "I" will also be
dotless while an uppercase version of "i" will also be dotted. This is an
issue for Turkish and Azeri.

By the way: The superscript dot of the letter i was added in the Middle Ages to
distinguish the letter (in manuscripts) from adjacent vertical strokes in such
letters as u, m, and n. J is a variant form of i which emerged at this time and
subsequently became a separate letter.

=item B<--caseful-sz>

let convmv convert the sz ligature (U+00DF) to the uppercase version
(U+1E9E) and vice versa. As of 2017 most fs case mapping tables don't treat
those two code points as case equivalents. Thus the default of convmv is to
treat it caseless for now also (unless this option is used).

=item B<--help>

print a short summary of available options

=item B<--dump-options>

print a list of all available options

=back

=head1 DESCRIPTION

B<convmv> is meant to help convert a single filename, a directory tree and the
contained files or a whole filesystem into a different encoding. It just
converts the filenames, not the content of the files. A special feature of
convmv is that it also takes care of symlinks, also converts the symlink target
pointer in case the symlink target is being converted, too.

All this comes in very handy when one wants to switch over from old 8-bit
locales to UTF-8 locales. It is also possible to convert directories to UTF-8
which are already partly UTF-8 encoded. convmv is able to detect if certain
files are UTF-8 encoded and will skip them by default. To turn this smartness
off use the C<--nosmart> switch.

=head2 Filesystem issues

Almost all POSIX filesystems do not care about how filenames are encoded, here
are some exceptions:

=head3 HFS+ on OS X / Darwin

Linux and (most?) other Unix-like operating systems use the so called
normalization form C (NFC) for its UTF-8 encoding by default but do not enforce
this. HFS+ on the Macintosh OS enforces normalization form D
(NFD), where a few characters are encoded in a different way. On OS X it's not
possible to create NFC UTF-8 filenames because this is prevented at filesystem
layer.  On HFS+ filenames are internally stored in UTF-16 and when converted
back to UTF-8 (because the Unix based OS can't deal with UTF-16 directly), NFD
is created for whatever reason.  See
http://developer.apple.com/qa/qa2001/qa1173.html for defails. I think it was a
very bad idea and breaks many things under OS X which expect a normal POSIX
conforming system. Anywhere else convmv is able to convert files from NFC to
NFD or vice versa which makes interoperability with such systems a lot easier.

=head3 APFS on macOS

Apple, with the introduction of APFS in macOS 10.3, gave up to impose NFD on
user space. But once you enforced NFD there is no easy way back without
breaking existing applications. So they had to make APFS
normalization-insensitive, that means a file can be created in NFC or NFD in
the filesystem and it can be accessed with both forms also. Under the hood they
store hashes of the normalized form of the filename to provide normalization
insensitivity. Sounds like a great idea? Let's see: If you readddir a
directory, you will get back the files in the the normalization form that was
used when those files were created. If you stat a file in NFC or in NFD form
you will get back whatever normalization form you used in the stat call. So
user space applications can't expect that a file that can be stat'ed and
accessed successfully, is also part of directory listings because the returned
normalization form is faked to match what the user asked for. Theoretically
also user space will have to normalize strings all the time. This is the same
problem as for the case insensitivity of filenames before, which still breaks
many user space applications. Just that the latter one was much more obvious to
spot and to implement than this thing. So long, and thanks for all the fish.

=head3 JFS

If people mount JFS partitions with iocharset=utf8, there is a similar problem,
because JFS is designed to store filenames internally in UTF-16, too; that is
because Linux' JFS is really JFS2, which was a rewrite of JFS for OS/2. JFS
partitions should always be mounted with iocharset=iso8859-1, which is also the
default with recent 2.6.6 kernels. If this is not done, JFS does not behave
like a POSIX filesystem and it might happen that certain files cannot be
created at all, for example filenames in ISO-8859-1 encoding. Only when
interoperation with OS/2 is needed iocharset should be set according to your
used locale charmap.

=head3 NFS4

Despite other POSIX filesystems RFC3530 (NFS 4) mandates UTF-8 but also says:
"The nfs4_cs_prep profile does not specify a normalization form.  A later
revision of this specification may specify a particular normalization form." In
other words, if you want to use NFS4 you might find the conversion and
normalization features of convmv quite useful.

=head3 FAT/VFAT and NTFS

NTFS and VFAT (for long filenames) use UTF-16 internally to store filenames.
You should not need to convert filenames if you mount one of those filesystems.
Use appropriate mount options instead!

=head2 How to undo double UTF-8 (or other) encoded filenames

Sometimes it might happen that you "double-encoded" certain filenames, for
example the file names already were UTF-8 encoded and you accidently did
another conversion from some charset to UTF-8. You can simply undo that by
converting that the other way round. The from-charset has to be UTF-8 and the
to-charset has to be the from-charset you previously accidently used.  If you
use the C<--fixdouble> option convmv will make sure that only files will be
processed that will still be UTF-8 encoded after conversion and it will leave
non-UTF-8 files untouched. You should check to get the correct results by doing
the conversion without C<--notest> before, also the C<--qfrom> option might be
helpful, because the double utf-8 file names might screw up your terminal if
they are being printed - they often contain control sequences which do funny
things with your terminal window. If you are not sure about the charset which
was accidently converted from, using C<--qfrom> is a good way to fiddle out the
required encoding without destroying the file names finally.

=head2 How to repair Samba files

When in the smb.conf (of Samba 2.x) there hasn't been set a correct "character
set" variable, files which are created from Win* clients are being created in
the client's codepage, e.g. cp850 for western european languages. As a result
of that the files which contain non-ASCII characters are screwed up if you "ls"
them on the Unix server. If you change the "character set" variable afterwards
to iso8859-1, newly created files are okay, but the old files are still screwed
up in the Windows encoding. In this case convmv can also be used to convert the
old Samba-shared files from cp850 to iso8859-1.

By the way: Samba 3.x finally maps to UTF-8 filenames by default, so also when
you migrate from Samba 2 to Samba 3 you might have to convert your file names.

=head2 Netatalk interoperability issues

When Netatalk is being switched to UTF-8 which is supported in version 2 then
it is NOT sufficient to rename the file names. There needs to be done more. See
http://netatalk.sourceforge.net/2.0/htmldocs/upgrade.html#volumes-and-filenames
and the uniconv utility of Netatalk for details.

=head1 SEE ALSO

L<locale(1)> L<utf-8(7)> L<charsets(7)>

=head1 BUGS

no bugs or fleas known

=head1 DONATE

You can support convmv by doing a donation, see L<https://www.j3e.de/donate.html>

=head1 AUTHOR

Bjoern JACKE
 
Send mail to bjoern [at] j3e.de for bug reports and suggestions.

=cut

require 5.008;
use Getopt::Long;
use File::Find;
use File::Basename;
use Cwd;
use Encode 'from_to','encode_utf8','decode_utf8','_utf8_on','_utf8_off';
#use Encode 'is_utf8';
use Unicode::Normalize;
use utf8;
use bytes;

Getopt::Long::Configure ("bundling");
binmode STDOUT, ":bytes";
binmode STDERR, ":bytes";

my $opt_mtimes = 1; # default 1 since convmv 2.0
my %opts = (
        'nfc'=>\$opt_nfc,
        'nfd'=>\$opt_nfd,
        'f=s'=>\$opt_f,
        't=s'=>\$opt_t,
        'r'=>\$opt_r,
        'i'=>\$opt_i,
        'list'=>\$opt_list,
        'help'=>\$opt_help,
        'notest'=>\$opt_notest,
        'qfrom'=>\$opt_qfrom,
        'qto'=>\$opt_qto,
        'replace'=>\$opt_replace,
        'nosmart'=>\$opt_nosmart,
        'lowmem'=>\$opt_lowmem,
        'exec=s'=>\$opt_exec,
        'unescape'=>\$opt_unescape,
        'upper'=>\$opt_upper,
        'lower'=>\$opt_lower,
        'dotlessi'=>\$opt_dotlessi,
        'caseful-sz'=>\$opt_caseful_sz,
        'parsable'=>\$opt_parsable,
        'run-parsable=s'=>\$opt_runparsable,
        'fixdouble'=>\$opt_fixdouble,
        'preserve-mtimes!'=>\$opt_mtimes,
        'dump-options'=>\$opt_dumpoptions,
        'undo-script=s'=>\$opt_undo_script,
        'map=s'=>\$opt_map,
        );
GetOptions %opts or exit 1;
use File::Compare;
$errors_occurred=0;
$warnings_occurred=0;
$ops=0;
$mytime = time();
$maxfilenamelength=255;
# $maxpathlength=4096; # this might be used somehow, somewhere?

%dir_time_hash=();
my $this_is_valid_utf8;

# delimiter and final delimiter for parsable mode:
$del = "\0\n";
$fin_del = "\0\0\n";

&listvalidencodings and exit 0 if ($opt_list);
&dumpoptions and exit 0 if ($opt_dumpoptions);
&runparsable and exit 0 if ($opt_runparsable);
&printusage and exit 1 if (!@ARGV or $opt_help);

&check_for_broken_perl_release();

if ($opt_parsable or $opt_runparsable) {
    if ($opt_notest or $opt_exec or $opt_i) {
        die "--parsable/--run-parsable mode cannot be used with --notest, --exec or -i\n";
    }
}

if ($opt_replace and $opt_undo_script) {
    die "--replace and --undo-script can't work together!\n";
}

if ($opt_unescape) {
    die "No charset conversion when unescaping!\n" if ($opt_f or $opt_t);
    $checkenc=\&unescape_checkenc;
    $get_newname=\&unescape_get_newname;
} elsif ($opt_upper or $opt_lower) {
    die "No charset conversion when uppering/lowering!\n" if ($opt_t);
    die "Not possible to --upper and --lower at the same time!\n" if ($opt_upper and $opt_lower);
    $checkenc=\&upperlower_checkenc;
    $get_newname=\&upperlower_get_newname;
    $opt_f="ascii" unless ($opt_f);
} elsif ($opt_map) {
    if ($opt_t or $opt_f or $opt_upper or $opt_lower or $opt_unescape) {
        die "--map parameter not allowed with other character conversion parameters\n";
    }
    $checkenc=\&dummy;
    $get_newname=\&map_get_newname;
} else {
    if (not ($opt_f and $opt_f=Encode::resolve_alias($opt_f))) {
        die "wrong/unknown \"from\" encoding!\n";
    }
    if (not ($opt_t and $opt_t=Encode::resolve_alias($opt_t))) {
        die "wrong/unknown \"to\" encoding!\n";
    }
    if ($opt_fixdouble) {
        $checkenc=\&fixdouble_checkenc;
    } else {
        $checkenc=\&char_checkenc;
    }
    $get_newname=\&char_get_newname;
}
$to_is_utf8 = lc($opt_t) =~ m/^utf-?8/;
$from_is_utf8 = lc($opt_f) =~ m/^utf-?8/;

if ($opt_qfrom) {
    $from_print=\&to_ascii;
} else {
    $from_print=\&dummy;
}

if ($opt_qto) {
    $to_print=\&to_ascii;
} else {
    $to_print=\&dummy;
}

if ($opt_nfc) {
    $norm=\&NFC;
    die "NFC requires UTF-8 as target charset\n" unless ($to_is_utf8);
} elsif ($opt_nfd) {
    $norm=\&NFD;
    die "NFD requires UTF-8 as target charset\n" unless ($to_is_utf8);
} else {
    $norm=\&dummy;
}

if ($opt_fixdouble) {
    die "--fixdouble requires UTF-8 as source and non-UTF-8 as target charset\n" unless ($from_is_utf8 and $opt_t and not $to_is_utf8);
}

$opt_lowmem=1 if ($opt_exec);

$pwd=cwd();
@args=@ARGV;
undef @ARGV;

for (@args) {
    s/\/\.\//\/\//g; # normalize "/./" to "/"
    s/\/[\/]+/\//g;  # normalize "//" to "/"
    die "file or directory not found: $_\n" unless (-e or -l);
}
if ($opt_parsable) {
    $outerr=NUL;
} else {
    $outerr=STDERR;
}
if ($opt_undo_script) {
    die "undo-script file already exists, exiting.\n" if (-e $opt_undo_script);
    open(UNDOLOG, ">", $opt_undo_script) or die "couldn't open undo-script for writing. Aborting.\n";
    print UNDOLOG "# this is a per undo script generated by convmv.\n",
            "# Please check if this looks reasonable before running!\n";
    print UNDOLOG "# Example: perl $opt_undo_script\n";
    print UNDOLOG "chdir '$pwd;\n'";
}

## do {print ord($_)."_" for (split(//,$_));print "\n"; } for (@args); # debug print

print $outerr "Starting a dry run without changes...\n" unless ($opt_notest);

if ($opt_r) {
    $myfind=\&find;
} else {
    $myfind=\&find0depth;
}

&$myfind({wanted=>\&scan,bydepth=>1,no_chdir=>1}, @args);
if (not $errors_occurred and $warnings_occurred) {
    $errors_occurred=1 if (not &print_ask ("WARNINGS occurred. Do you really want to continue?",1));
}

die "To prevent damage to your files, we won't continue.\nFirst fix this or correct options!\n" if ($errors_occurred);
unless ($opt_exec) {
    &$myfind({wanted=>\&process_symlink_targets,bydepth=>1,no_chdir=>1}, @args);
}
&$myfind({wanted=>\&process_main,bydepth=>1,no_chdir=>1}, @args);

# check for unintentionally left files
#for (keys %dir_time_hash) {
#    print $outerr "error: left in %dir_time_hash: $_\n";
#}

$mytime = time() - $mytime;
if ($opt_notest) {
    print $outerr "Ready! I converted $ops files in $mytime seconds.\n",
} else {
    print $outerr "No changes to your files done. Would have converted $ops files in $mytime seconds.\nUse --notest to finally rename the files.\n";
}

#####
## subs
###

# find-like function but without any depth search for not recursive mode:
sub find0depth() {
    my $opts = shift;
    for (@_) {
        $$opts{'wanted'}($_);
    }
}

# scan for real files and check charset first:
sub scan {
    $arg = $_;
    &get_dir_base_change;
    if (-l $arg) {
#        print "link: $arg in $dir\n";
        if (not defined(&$checkenc($arg))) { $errors_occurred=1 };
    } elsif (-d $arg) {
#        print "dir: $arg in $dir\n";
        $inod_fullname{(stat $arg)[1]}=$dir."/".$arg if (!$opt_lowmem);
        if (not defined(&$checkenc($arg))) { $errors_occurred=1 };
        if ($opt_r and not (-x $arg or -r $arg)) {
            print $outerr "WARNING: cannot traverse ",&$from_print($dir."/".$arg),"\n";
            $warnings_occurred=1;
        }
    } elsif (-f $arg) {
#        print "file: $arg in $dir\n";
        $inod_fullname{(stat $arg)[1]}=$dir."/".$arg if (!$opt_lowmem);
        if (not defined(&$checkenc($arg))) { $errors_occurred=1 };
    }
    chdir $pwd;
}

# move symlink targets:
sub process_symlink_targets {
    $arg=$_;
    &get_dir_base_change;
    if (-l $arg) {
        $oldlink=readlink $arg;
        if ((-f $oldlink or -d $oldlink) and $newname=&$get_newname($oldlink)) {
            if ( $newname ne $oldlink ) {
                if ( $inod_fullname{(stat $oldlink)[1]} or $opt_lowmem) { # = if (symlink target scanned before)
                    #print is_utf8($oldlink) ? 1 : 0;
                    #print is_utf8($newname) ? 1 : 0;
                    print $outerr "symlink \"".&$from_print($File::Find::name)."\": \"";
                    print $outerr "".&$from_print($oldlink)."\" >> \"";
                    &print_ask (&$to_print($newname)."\"",$opt_i) or return;
                    &save_parent_mtime($dir) if ($opt_mtimes);
                    if ($opt_notest) {
                        unlink $arg;
                        symlink ($newname, $arg);
                        print UNDOLOG "unlink \"".$File::Find::name."\";\n";
                        print UNDOLOG "symlink (\"$oldlink\", \"".$File::Find::name."\");\n";
                    } elsif ($opt_parsable) {
                        print "unlink".$del.$File::Find::name.$fin_del;
                        print "symlink".$del.$newname.$del.$File::Find::name.$fin_del;
                    }
                    $ops++;
                } else {
                    print $outerr "link target \"",&$from_print($oldlink),"\" of \"",&$from_print($dir."/".$arg),"\" not in subtree, left untouched!\n";
                }
            } # else { print "no need to convert link target: $oldlink to $newname\n"; }
        }
    }
    chdir $pwd;
}

# do the changes to all the real files/dirs/links:
sub process_main {
    $arg=$_;
    &get_dir_base_change;
    if (-l $arg) {
#        $type="symlink";
        $newname=&$get_newname($arg);
        if ($newname and $newname ne $arg) {
            &renameit($arg,$newname);
        }
    } elsif (-d $arg) {
#        $type="directory";
        &restore_times_if_any($dir,$arg) if ($opt_mtimes);
        $newname=&$get_newname($arg);
        if ($newname and $newname ne $arg) {
            &renameit($arg,$newname);
        }
    } elsif (-f $arg) {
#        $type="file";
        $newname=&$get_newname($arg);
        if ($newname and $newname ne $arg) {
            &renameit($arg,$newname);
        }
    }

    chdir $pwd;
}

sub char_get_newname {
# returns undef on error and string otherwise.
    my $oldfile=shift;
    my $newname;
    my $lets_die = 0;
    if (!$from_is_utf8 and $to_is_utf8 and !$opt_nosmart and &looks_like_utf8($oldfile)) {
        if ($opt_parsable) {
            print "іnfomsg".$del."skipalreadyutf8".$del.$dir."/".$oldfile.$fin_del;
        } else {
            print $outerr "Skipping, already UTF-8: ",&$from_print($dir."/".$oldfile),"\n";
        }
        return $oldfile;
    } else {
        if ($opt_fixdouble and not looks_like_utf8($oldfile)) {
            # this is legacy encoding which we ignore in fixdouble mode
            return $oldfile;
        }
        if ($from_is_utf8 and ! $to_is_utf8) {
            # from_to can't convert from NFD to non-UTF-8!
            $newname=encode_utf8(NFC(decode_utf8($oldfile)));
        } else {
            $newname=$oldfile;
        }
        from_to($newname, $opt_f, $opt_t, Encode::FB_QUIET) or $lets_die = 1;
        if ($opt_fixdouble and not looks_like_utf8($newname)) {
            return $oldfile;
        }
        if ($lets_die) {
            die "SHOULD NOT HAPPEN HERE: conversion error, no suitable charset used?: \"$oldfile\"\nTo prevent damage to your files, we won't continue. First fix this!\n";
        }
        $newname=&$norm(decode_utf8($newname)) if ($to_is_utf8);
        return $newname;
    }
    
}

sub get_dir_base_change() {
    $arg =~ s/\/*$//;
    $dir=dirname($arg);
    $arg=basename($arg);
    chdir $dir;
}

sub renameit() {
    my $oldfile=shift;
    my $newname=shift;
    my $cmd;
    my $ci_old_new_same_inode = 0;
    $newname=encode_utf8($newname) if ($to_is_utf8);
    if ($opt_exec) {
                $cmd = $opt_exec;
                $cmd =~ s/\#2/\000f8d9hqoäd\#2/g; # make the #2 unique so that file names may contain "#2"
                $cmd =~ s/\#1/\Q$oldfile\E/g;
                $cmd =~ s/\000f8d9hqoäd\#2/\Q$newname\E/g;
                print "$cmd\n";
    } else {
        #print is_utf8($oldfile) ? 1 : 0;
        #print is_utf8($newname) ? 1 : 0;
        &print_ask ("mv \"". &$from_print($dir."/".$oldfile)."\"\t\"".&$from_print($dir)."/".&$to_print($newname)."\"",$opt_i) or return;
    }
    &save_parent_mtime($dir) if ($opt_mtimes);
    # the following is to handle case-insensitive filesystems:
    if ($opt_lower or $opt_upper or $opt_nfc or $opt_nfd) {
        if ((stat $oldfile)[1] == (stat $newname)[1]) {
            $ci_old_new_same_inode = 1;
            #print $outerr "found case-insensitive filesystem...\n";
            my $tmpfile;
            for (1 .. 10000) {
                $tmpfile = "convmvtmp".$_;
                if (! -e "convmvtmp".$_) {
                    $tmpfile = "convmvtmp".$_;
                    last;
                }
            }
            if ($opt_notest) {
                rename ($oldfile, $tmpfile);
                print UNDOLOG "rename (\"$dir/$tmpfile\", \"$dir/$oldfile\");\n";
                $oldfile=$tmpfile;
            } elsif ($opt_parsable) {
                print "rename".$del.$dir."/".$oldfile.$del.$dir."/".$tmpfile.$fin_del;
                $oldfile=$tmpfile;
            }
        }
    }
    if (-e $newname and !$opt_exec and !$ci_old_new_same_inode) {
        if ($opt_replace and !&compare($oldfile,$newname)) {
            if ($opt_notest) {
                unlink $newname or print $outerr "Error: $!\n";
                rename ($oldfile, $newname) or print $outerr "Error: $!\n";
            } elsif ($opt_parsable) {
                print "unlink".$del.$dir."/".$oldfile.$fin_del;
                print "rename".$del.$dir."/".$oldfile.$del.$dir."/".$newname.$fin_del;
            }
        } else {
            if ($opt_parsable) {
                print "errormsg".$del."fileexists".$del.$newname.$fin_del;
            } else {
                print $outerr "".&$to_print($newname)," exists and differs or --replace option missing - skipped\n";
            }
        }
    } else {
        if ($opt_notest) {
            if ($opt_exec) {
                system($cmd);
            } else {
                rename ($oldfile, $newname) or print $outerr "Error: $!\n";
                print UNDOLOG "rename (\"$dir/$newname\", \"$dir/$oldfile\");\n";
            }
        } elsif ($opt_parsable) {
            print "rename".$del.$dir."/".$oldfile.$del.$dir."/".$newname.$fin_del;
        }
    }
    $ops++;
}

sub save_parent_mtime() {
    my $dir=shift;
    $dir =~ s/^\.\///;
    $dir =~ s/\.\/$//;
#    return if ($dir eq "."); # broken !?
    return if (exists $dir_time_hash{$dir});
    #print $outerr "Putting \"$dir\" in %dir_time_hash\n"; # debug print
    @{$dir_time_hash{$dir}}=(stat("."))[8..10];
}

sub restore_times_if_any() {
    my $dir=shift;
    my $old=shift;
    if ($dir eq ".") {
        $dir = "";
    } else {
        $dir .= "/";
    }
    $dir .= $old;
    if (exists $dir_time_hash{$dir}) {
        if ($opt_notest) {
            # in this functions cwd is $dir - so we need to call utime() on $old (and not $path)
            utime ${$dir_time_hash{$dir}}[0], ${$dir_time_hash{$dir}}[1], $old or print $outerr "Could not run utime() on $old: $!\n";
            print UNDOLOG "utime ".${$dir_time_hash{$dir}}[0].", ".${$dir_time_hash{$dir}}[1].", ".$dir." or print \"Could not run utime() on $dir: \$!\n\"";
        } elsif ($opt_parsable) {
            print "utime".$del.$dir.$del.${$dir_time_hash{$dir}}[0].$del.${$dir_time_hash{$dir}}[1].$del.${$dir_time_hash{$dir}}[2].$fin_del;
        }
        delete $dir_time_hash{$dir};
        #print $outerr "done\n"; # debug print
    }
}

sub listvalidencodings() {
    print "$_\n" for (Encode->encodings(":all"));
    return 1;
}

sub dumpoptions() {
    for (keys %opts) {
        s/=.*//;
        print "-" if (length($_) > 1);
        print "-$_\n";
    }
    return 1;
}

sub fixdouble_checkenc() {
    return 1;
}

sub char_checkenc() {
    my $oldfile=shift;
    my $new=$oldfile;
    if ($from_is_utf8) {
        if (! &$this_is_valid_utf8($new)) {
            if ($opt_parsable) {
                print "errormsg".$del."filenotutf8".$del.$oldfile.$fin_del;
            } else {
                print $outerr "this file was not validly encoded in UTF-8: \"". &$from_print($dir."/".$oldfile) ."\"\n";
                }
            return undef;
        }
    } else {
        if ($to_is_utf8 and !$opt_nosmart and &looks_like_utf8($oldfile)) {
            # do nothing: e.g. from_enc is shift_jis but string is utf-8. Should
            # be "smart-skipped" if to_enc is utf-8 and not produce no error here.
        }
        elsif (! from_to($new,$opt_f, "utf8", Encode::FB_QUIET) ) {
            if ($opt_parsable) {
                print "errormsg".$del."fileencodedinvalid".$del.$dir."/".$oldfile.$fin_del;
            } else {
                print $outerr "this file was not validly encoded in $opt_f: \"". &$from_print($dir."/".$oldfile) ."\"\n";
            }
            return undef;
        }
    }
    # $new is utf-8 now and $oldfile's encoding was valid ...
    my $filenamelength;
    if ($to_is_utf8) {
        $new = &$norm(decode_utf8($new));
        $filenamelength=length($new);
    } else {
        $new=encode_utf8(NFC(decode_utf8($new)));
        $filenamelength=from_to($new, "utf8", $opt_t, Encode::FB_QUIET);
    }
##    print "$oldfile|$utf8oldfile|$new|$filenamelength\n";
    if (! $filenamelength) {
        if ($opt_parsable) {
            print "errormsg".$del."charsetdoesntcoverneededcharacters".$del.$dir."/".$oldfile.$fin_del;
        } else {
            print $outerr "$opt_t doesn't cover all needed characters for: \"". &$from_print($dir."/".$oldfile) ."\"\n";
        }
        return undef;
    } elsif ($filenamelength > $maxfilenamelength) {
        print $outerr "".&$from_print($dir."/".$oldfile).": resulting filename is $filenamelength bytes long (max: $maxfilenamelength)\n";
        return undef;
    }
    &posix_check($new);
    return 1;
}

sub printusage {
    &check_for_perl_bugs;
    print <<END;
convmv 2.05 - converts filenames from one encoding to another
Copyright (C) 2003-2018 Bjoern JACKE <bjoern\@j3e.de>

This program comes with ABSOLUTELY NO WARRANTY; it may be copied or modified
under the terms of the GNU General Public License version 2 or 3 as published
by the Free Software Foundation.

 USAGE: convmv [options] FILE(S)
-f enc     encoding *from* which should be converted
-t enc     encoding *to* which should be converted
-r         recursively go through directories
-i         interactive mode (ask for each action)
--nfc      target files will be normalization form C for UTF-8 (Linux etc.)
--nfd      target files will be normalization form D for UTF-8 (OS X etc.)
--qfrom    be quiet about the "from" of a rename (if it screws up your terminal e.g.)
--qto      be quiet about the "to" of a rename (if it screws up your terminal e.g.)
--exec c   execute command instead of rename (use #1 and #2 and see man page)
--list     list all available encodings
--lowmem   keep memory footprint low (see man page)
--map m    apply an additional character mapping
--nosmart  ignore if files already seem to be UTF-8 and convert if posible
--notest   actually do rename the files
--replace  will replace files if they are equal
--unescape convert%20ugly%20escape%20sequences
--upper    turn to upper case
--lower    turn to lower case
--parsable write a parsable todo list (see man page)
--help     print this help
END
#--dotlessi care about the dotless i issue of certain locales (use with care)
#--caseful-sz treat make convmv aware of caputal sz ligature (ß vs. ẞ)
}

sub looks_like_utf8() {
    my $string = shift;
    if ($string =~ m/[^[:ascii:]]/ and &$this_is_valid_utf8($string)) {
        return 1;
    } else {
        return undef;
    }
}

sub this_is_valid_utf8_decode {
    my $string = shift;
    if (not defined(decode_utf8($string))) {
        return undef;
    } else {
        return 1;
    }
}

sub this_is_valid_utf8_decode_CROAK() {
    my $string = shift;
    # until 1.08 I used to use decode_utf8() but see perl bug #37757 (perl 5.8.7/8)
    #if (not defined(decode_utf8($string)) ) {
    #
    # let's look for a different way to find valid utf-8 ...:
    # utf8::decode() is experimental and might disappear says utf8(3pm):
    #if (utf8::decode($string) != undef) {
    #
    # Encode::decode does not work as one might expect:
    #if (Encode::decode(utf8,$string,Encode::FB_QUIET) == undef) {
    #
    # from_to() works for all Perl versions (at the moment ;)
    # ... and here we go: with Perl 5.10 from_to(utf8..utf8) doen't work either,
    # see perl bug #49830. convmv 1.10 and Perl 5.10 will again only work with
    # --nosmart.
    #
    # okay, now perluniintro suggests to do this:

    eval 'decode_utf8($string, Encode::FB_CROAK);';
    if ($@) {
        return undef;
    } else {
        return 1;
    }
}

sub to_ascii() {
    my $a=shift;
    $a =~ s/[^[:ascii:]]/?/g;
    $a =~ s/[[:cntrl:]]/*/g;
    return $a;
}

sub dummy() {
    return shift;
}

sub print_ask() { # takes 2 arguments, string and askornot
    if ($opt_parsable) {
        return 1;
    }
    my $a="";
    print shift;
    my $ask = shift;
    while ($ask and not $a =~ m/^[yn]$/i) {
        print " (y/n) ";
        $a=<STDIN>;
    }
    print "\n";
    if ($a =~ m/^n$/i) {
        return undef;
    } else {
        return 1;
    }
}

sub unescape_checkenc() {
    my $name = shift;
    if ($name =~ m/^[[:ascii:]]*$/) { # should we be more strict ?
        &posix_check(&unescape_get_newname($name));
        return 1;
    } else {
        if ($opt_parsable) {
            print "errormsg".$del."notanescapedfile".$del.$name.$fin_del;
        } else {
            print $outerr "\"",&$from_print($name),"\" not ASCII - this does not seem to be an escaped filename.\n";
        }
        return undef;
    }
}

sub map_get_newname() {
    $_ = shift;
    return $_ if ($_ eq "." or $_ eq "..");
    _utf8_on($_); # this is needed for tr/multibyte/non-multibyte/ to work! Otherwise we would
                  # have to make a s/// for each character, grrr...
    if ($opt_map eq "ntfs-sfm") { # see MS KB 117258 (but map : instead of /
        tr/\x01-\x1f\"\*\:\<\>\?\\\|/\x{f001}-\x{f027}/;
        s/ $/\x{f028}/;  # Space, only if occurring as the last character of the name
        s/\.$/\x{f029}/; # period, only if occurring as the last character of the name
    } elsif ($opt_map eq "ntfs-sfm-undo") {
        tr/\x{f001}-\x{f027}/\x01-\x1f"*:<>?\\| /;
        s/\x{f028}$/ /;  # Space, only if occurring as the last character of the name
        s/\x{f029}$/./;  # period, only if occurring as the last character of the name
    } elsif ($opt_map eq "ntfs-sfu") { # +0xF000, see MS KB ???? anyone knows a link or has archived an old one?
        tr/\x01-\x1f\"\*\/\<\>\?\\\|/\x{f001}-\x{f01f}\x{f022}\x{f02a}\x{f02f}\x{f03c}\x{f03e}\x{f03f}\x{f05c}\x{f07c}/;
        #??? s/ $/space/;  # Space, only if occurring as the last character of the name
        #??? s/\.$/period/; # period, only if occurring as the last character of the name
    } elsif ($opt_map eq "ntfs-sfu-undo") {
        tr/\x{f001}-\x{f01f}\x{f022}\x{f02a}\x{f02f}\x{f03c}\x{f03e}\x{f03f}\x{f05c}\x{f07c}/\x01-\x1f"*\/<>?\\|/;
        #??? s/space$/ /;  # Space, only if occurring as the last character of the name
        #??? s/period$/./; # period, only if occurring as the last character of the name
    } elsif ($opt_map eq "ntfs-pretty") {
        s/\"/”/g;  # U+201D
        s/\*/∗/g;  # U+2731
        s/\?/？/g; # U+FF1F
        s/\:/꞉/g;  # U+A789
        s/\</＜/g; # U+FF1C
        s/\>/＞/g; # U+FF1E
        s/\|/❘/g;  # U+2758
        s/\\/＼/g; # U+FF3C
    } elsif ($opt_map eq "ntfs-pretty-undo") {
        s/”/"/g;   # U+201D
        s/∗/*/g;   # U+2731
        s/？/?/g;  # U+FF1F
        s/꞉/:/g;   # U+A789
        s/＜/</g;  # U+FF1C
        s/＞/>/g;  # U+FF1E
        s/❘/|/g;   # U+2758
        s/＼/\\/g; # U+FF3C
    } else {
        die "map parameter \"$opt_map\" not supported. Use one of ",
            "ntfs-sfm, ntfs-sfm-undo, ",
            "ntfs-sfu, ntfs-sfu-undo, ",
            "ntfs-pretty, ntfs-pretty-undo\n";
    }
    return $_;
}

sub unescape_get_newname() { # return undef on error, string otherwise
    my $newname = shift;
#    $newname =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg; # this was done before
    $newname =~ s/(%)([0-9a-fA-F][0-9a-fA-F])/chr(hex($2))/eg;
    return $newname;
}


sub upperlower_checkenc() {
    my $oldname = shift;
    my $newname = upperlower_get_newname($oldname);
    if ($from_is_utf8) {
        if (! &$this_is_valid_utf8($oldname)) {
            if ($opt_parsable) {
                print "errormsg".$del."filenotutf8".$del.$dir."/".$oldname.$fin_del;
            } else {
                print $outerr "this file was not validly encoded in UTF-8: \"". &$from_print($dir."/".$oldname) ."\"\n";
                }
            return undef;
        }
    }
    if (not defined($newname)) {
        return undef;
    } else {
        &posix_check($newname);
        return 1;
    }
}

sub upperlower_get_newname() {
# return undef on error, string otherwise
    my $oldname = shift;
    my $name=$oldname;
    if (! from_to($name, $opt_f, "utf8", Encode::FB_QUIET)) { # should also leave NFD as it is ...
        if ($opt_parsable) {
            print "errormsg".$del."fileencodedinvalid".$del.$dir."/".$oldfile.$fin_del;
        } else {
            print $outerr "\"",&$from_print($oldname),"\" not encoded in $opt_f ? Supply the correct encoding via -f option!\n";
        }
        return undef;
    }
    _utf8_on($name);    # Unicode in Perl can be a real pain ...
    no bytes;
    if ($opt_upper) {
        if ($opt_dotlessi) {
            $name =~ s/ı/I/g;
            $name =~ s/i/İ/g;
        }
        # we do not want to upper ß to SS ! Let's substitute it with
        # NUL+DWSLQH (NUL may not be part of filename) and get it back after uc().
        # Unicode 5.1(draft) news: Uppercasing U+00DF (ß) LATIN SMALL LETTER SHARP S
        # to the new U+1E9E LATIN CAPITAL LETTER SHARP S.
        # but until now I don't see use for this in filenames ...
        $name =~ s/ß/\000DWSLQH/g;
        $name = uc($name);
        if ($opt_caseful_sz) {
            $name =~ s/\000DWSLQH/ẞ/g;
        } else {
            $name =~ s/\000DWSLQH/ß/g;
        }
    } else {
        if ($opt_dotlessi) {
            $name =~ s/I/ı/g;
            $name =~ s/İ/i/g;
        }
        $name =~ s/ẞ/\000dwslqh/g;
        $name = lc($name);
        if ($opt_caseful_sz) {
            $name =~ s/\000dwslqh/ß/g;
        } else {
            $name =~ s/\000dwslqh/ẞ/g;
        }
    }
    use bytes;
    _utf8_off($name);
    # we should also do special treatment for UTF-8 NFD of "I with dot above" in byte mode now, otherwise we get "i̇", which is a double-single dotted i ;-)
    # the problems that arise with this letter are endless ...
#    $name =~ s/i\314\207/i/g if ($from_is_utf8);
    if (! from_to($name, "utf8", $opt_f, Encode::FB_QUIET)) {
        if ($opt_parsable) {
            print "errormsg".$del."fileencodingunknown".$del.$dir."/".$oldfile.$fin_del;
        } else {
            print $outerr $opt_upper?"Upper":"Lower","case of \"",&$from_print($oldname),"\" not possible in $opt_f ! Maybe supply different encoding via -f option.\n";
        }
        return undef;
    }
    return $name;
}

sub posix_check() {
    my $name=shift;
    if ($name =~ m/[\000\/]/) {
        print $outerr "WARNING: new filename \"",&$to_print($name),"\" contains characters, which are not POSIX filesystem conform! This may result in data loss.\n";
        $warnings_occurred=1;
    }
}

# still unused, but might be used for Netatalk CAP encoding:
sub cap2utf8() {
    my $oldname = shift;
    if (($oldname !~ m/^:2eDS_Store/) and ($oldname =~ /:/)) {
        $oldname =~ s/(:([0-9a-f][0-9a-f]))/chr(hex($2))/eg;
    }
    return $oldname;
}


sub runparsable() {
    $/=$fin_del;
    open(FH, "<", $opt_runparsable);
    while(<FH>) {
        my @line = split($del, $_);
        if ($line[0] eq "rename") {
            print "renaming ".$line[1]."\n";
            rename($line[1], $line[2]) or print "-> FAILED\n";
        } elsif ($line[0] eq "utime") {
            print "restoring times on ".$line[1]."\n";
            utime $line[2], $line[3], $line[1] or print "-> FAILED\n";
        } elsif ($line[0] eq "symlink") {
            print "symlinking ".$line[1]."\n";
            symlink($line[1], $line[2]) or print "-> FAILED\n";
        } elsif ($line[0] eq "unlink") {
            print "deleting ".$line[1]."\n";
            unlink $line[1] or print "-> FAILED\n";
        }
    }
    close FH;
}

sub check_for_broken_perl_release() {
    # Check that most basic Perl Encode features we use work reliably
    # and decide which code path we use for &this_is_valid_utf8():
    my $test = ""."\366";
    my $error = "";

    if (not defined(decode_utf8($test))) {
        $this_is_valid_utf8=\&this_is_valid_utf8_decode;
        return 0;
    }
    $error .= "decode_utf8(\$test) check failed\n";
    
    eval 'decode_utf8($test, Encode::FB_CROAK);';
    if (not $@) {
        $error .= "eval 'decode_utf8(\$non-utf8, Encode::FB_CROAK);'; check failed.\n";
    } else {
        $test = ""."ö";
        eval 'decode_utf8($test, Encode::FB_CROAK);';
        if ($@) {
            $error .= "eval 'decode_utf8(\$utf8, Encode::FB_CROAK);'; check failed.\n";
        } else {
            $this_is_valid_utf8=\&this_is_valid_utf8_decode_CROAK;
            return 0;
        }
    }
    print "Your Perl release is too broken to make convmv work reliably:\n",$error;
    exit 1;
}

sub check_for_perl_bugs() {
    # Check for certain Perl fleas that we more or less have to work around:
    # until 1.08 I used to use decode_utf8() but see perl bug #37757 (perl 5.8.7/8)
    #if (not defined(decode_utf8($string)) )
    my $bugs = "";
    my $test = "\366";

    my $u8test = NFD(""."ö");     # "". is intended as only so we have _utf8_off set
                    # otherwise from_to doesn't convert the $data to
                    # something else.
    # print "DEBUG: string is UTF-8 flagged: ",is_utf8($u8test) ? "yes" : "no","\n";
    eval "from_to($u8test, 'utf8', 'iso-8859-1');";
    if ($u8test ne "\366") {
        # Perl::Encode guys think that conversion from decomposed UTF-8
        # to any other charset does not have to be supported by from_to.
        # Why, when NFC or NFD this is both perfectly valid UTF-8?
        $bugs .= "#22111 ";
    }
    if (decode_utf8($test)) {
        $bugs .= "#37757 ";
        # Convmv 1.08 and below would not work here!
        # Perl documentation up to 5.8.8 said that
        # decode_utf8($data_that_is_not_utf_8) should return undef
    }
    if (! from_to($test,utf8,utf8,Encode::FB_QUIET) == undef) {
        $bugs .= "#49830 ";
        # convmv 1.10-1.11 would not work here!
        # broken UTF-8 is silently being converted to sane UTF-8 without throwing
        # an error.
    }
    if ($bugs) {
        print "Your Perl version has fleas $bugs\n";
    }

}

