#!/usr/bin/perl
#############################################################################
# mubench - low-level x86 instruction benchmark
# Copyright (C) 2005-2006 Alex Izvorski <aizvorski@gmail.com>
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111, USA.
#############################################################################

$VERSION = '0.2.2';

use lib "modules";

use IO::File;
use IPC::Run qw(run);
use Getopt::Long;

require "instructions.pl";

$options_string = join(' ', $0, @ARGV);

$cpuspeed = &getcpuspeed();
$loops = 100000;
$have_64bit = 1;
$have_32bit = 1;
$pairs = 0;
$accurate = 1;
$fast = 0;
$repeats = 3;
$include = '';
$output = 'xml';
$outfile = undef;
$gcc = 'gcc';
$cflags = '-mmmx -msse -msse2 -msse3 -m3dnow';

$result = GetOptions (
                      "mhz=i"       => \$cpuspeed,
                      "accurate!"   => \$accurate,
                      "fast!"       => \$fast,
                      "64bit!"      => \$have_64bit,
                      "32bit!"      => \$have_32bit,
                      "pairs!"      => \$pairs,
                      "include=s"   => \$include,
                      "output=s"    => \$output,
                      "outfile=s"   => \$outfile,
                      "gcc=s"       => \$gcc,
                      "cflags=s"    => \$cflags,
                      );

if ($accurate) { $repeats = 10; }
if ($fast) { $repeats = 5; $pairs = 0; }

@cflags = split(/\s+/, $cflags);

# expand wildcards
@opspecs = map {
    lc
} map {
    m!^(.*?)(x?mm)/(imm8)(.*)! ? ("$1$2$4", "$1$3$4") : $_;
} map {
    (my $op64 = $_) =~ s!\br\b!r64!g;
    (my $op32 = $_) =~ s!\br\b!r32!g;
    ($op64 eq $op32) ? $_ : (($op64) x $have_64bit, ($op32) x $have_32bit);
} @instructions;

# filter instructions based on include patterns
if ($include)
{
    my @include_patterns = split(/,/, $include);
    @opspecs = grep { my $op = $_; grep { $op =~ $_ } @include_patterns } @opspecs;
}

if ($pairs) { $num_tests = scalar(@opspecs) + scalar(@opspecs) * (scalar(@opspecs)-1) / 2; }
else { $num_tests = scalar(@opspecs); }
$N = 0;

# open output, print info
print STDERR "mubench $VERSION\n";
print STDERR "running $num_tests tests\n";
if ($output eq 'xml')
{
    if (! $outfile) { $outfile = "mubench-results-".&timestamp().".xml"; }
    $outfh = new IO::File($outfile, "w");
    $outfh->printf("<?xml version=\"1.0\"?>\n");
    $outfh->printf("<mubench>\n\n");
    $outfh->printf("<version>".$VERSION."</version>\n");
    $outfh->printf("<options>".$options_string."</options>\n\n");
    $outfh->printf("<start-time>".&timestamp()."</start-time>\n");
}
elsif ($output eq 'tsv')
{
    if (! $outfile) { $outfh = new IO::Handle; $outfh->fdopen(fileno(STDOUT), "w"); }
    else { $outfh = new IO::File($outfile, "w"); }
    $outfh->printf("%s\t%s\t%s\t%s\n", 'instruction 1', 'instruction 2', 'latency', 'throughput');
}
else
{
    if (! $outfile) { $outfh = new IO::Handle; $outfh->fdopen(fileno(STDOUT), "w"); }
    else { $outfh = new IO::File($outfile, "w"); }
    $outfh->printf("%-20s %-20s %-10s %-10s\n", 'instruction 1', 'instruction 2', 'latency', 'throughput');
}
print STDERR "saving results to ".($outfile ? $outfile : "standard output")."\n";

# run single tests
foreach my $opspec (@opspecs)
{
    my $code = &code_header;

    $code .= &generate_one_test(
                       test_name => "$opspec throughput",
                       ops => [ $opspec ],
                       cmds_per_loop => 1024,
                       reg_use_pattern => 'throughput',
                       );
    
    $code .=  &generate_one_test(
                       test_name => "$opspec latency",
                       ops => [ $opspec ],
                       cmds_per_loop => 1024,
                       reg_use_pattern => 'latency',
                       );
        
    $code .= &code_footer;

    my $result = &run_test($code, $opspec);
    if ($result->{err}) { print STDERR $result->{err}, "\n"; }

    if ($output eq 'xml')
    {
        if (! $result->{err})
        {
            $outfh->printf("<test><op>%s</op><l>%s</l><t>%s</t></test>\n", $opspec, $result->{latency}, $result->{throughput});
        }
        else
        {
            $outfh->printf("<test><op>%s</op><err>%s</err></test>\n", $opspec, $result->{err});
        }
    }
    elsif ($output eq 'tsv')
    {
        $outfh->printf("%s\t%s\t%s\t%s\n", $opspec, '', $result->{latency}, $result->{throughput});
    }
    else
    {
        $outfh->printf("%-20s %-20s %-10s %-10s\n", $opspec, '', $result->{latency}, $result->{throughput});
    }

    if ($N % 10 == 0) { print STDERR "\r$N out of $num_tests tests done \r"; }
    $N++;
}

# run pairs tests
if ($pairs)
{
foreach my $opspec (@opspecs)
{
foreach my $opspec2 (@opspecs)
{
    next if ($opspec2 le $opspec); # avoid the redundant calculations, A,B == B,A

    my $code = &code_header;

    $code .= &generate_one_test(
                       test_name => "$opspec, $opspec2 throughput",
                       ops => [ $opspec, $opspec2 ],
                       cmds_per_loop => 1024,
                       reg_use_pattern => 'throughput',
                       );
    
    # NOTE cannot measure latency of mix

    $code .= &code_footer;

    my $result = &run_test($code, $opspec);
    if ($result->{err}) { print STDERR $result->{err}; }

    if ($output eq 'xml')
    {
        if (! $result->{err})
        {
            $outfh->printf("<test><op>%s</op><op>%s</op><l>%s</l><t>%s</t></test>\n", $opspec, $opspec2, $result->{latency}, $result->{throughput});
        }
        else
        {
            $outfh->printf("<test><op>%s</op><op>%s</op><err>%s</err></test>\n", $opspec, $opspec2, $result->{err});
        }
    }
    elsif ($output eq 'tsv')
    {
        $outfh->printf("%s\t%s\t%s\t%s\n", $opspec, $opspec2, $result->{latency}, $result->{throughput});
    }
    else
    {
        $outfh->printf("%-20s%-20s %-10s %-10s\n", $opspec, $opspec2, $result->{latency}, $result->{throughput});
    }

    if ($N % 10 == 0) { print STDERR "\r$N out of $num_tests tests done "; }
    $N++;
}
}
}

print STDERR "\r$N out of $num_tests tests done \n";

# add extra info to xml file
if ($output eq 'xml')
{
    $outfh->printf("<end-time>".&timestamp()."</end-time>\n");

    my $fh = new IO::File("/proc/cpuinfo", "r");
    my $txt = join('', $fh->getlines());
    $fh->close();
    $outfh->printf("\n<cpuinfo>$txt</cpuinfo>\n");

    my ($in, $out, $err);
    run [$gcc, "-v"], \$in, \$out, \$err;
    $outfh->printf("\n<gcc-version>$err</gcc-version>\n");

    # FIXME assumes the assembler in the path is used
    run ["as", "-v"], \$in, \$out, \$err;
    $outfh->printf("\n<as-version>$err</as-version>\n");

    run ["uname", "-a"], \$in, \$out, \$err;
    $outfh->printf("\n<uname>$out</uname>\n");

    $outfh->printf("\n</mubench>\n");
    $outfh->close();

    my ($in, $out, $err);
    run ["md5sum", $outfile], \$in, \$out, \$err;
    my $md5 = $out;

    $outfh = new IO::File($outfile, "a");
    $outfh->printf("<!-- $md5 -->\n");
    $outfh->close();
    
    print STDERR "compressing results to $outfile.bz2\n";

    run ["bzip2", $outfile];
}
print STDERR "mubench done\n";


# run one test, input is code prepared by generate_one_test etc
sub run_test
{
    my ($code, $name) = @_;
    
    my $result = +{};

    my $fh = new IO::File("./test.c", "w");
    $fh->print($code);
    $fh->close;

    my ($in, $out, $err);
    my ($rc);
    unlink("./test");

    $rc = run [$gcc, @cflags, "-o", "./test", "./test.c"], \$in, \$out, \$err;
    if (($err =~ m!Error: !) ) 
    {
        if ($err =~ m!^(.*\n.*\n)!) { $err = $1; $err =~ s!\n! !g; }
        $result->{err} = sprintf("error: cannot compile %s: %s", $name, $err); 
        return $result;
    }

    my ($minlatency, $minthroughput);
    for (my $i = 0; $i < $repeats; $i++)
    {
        $rc = run ["./test"], \$in, \$out, \$err;
        if ($rc == 0)
        {
            $result->{err} = sprintf("error: cannot run %s: %d", $name, $?);
            return $result;
        }
        my ($latency, $throughput);
        if ($out =~ m!latency \s*=\s*(\d+\.\d+)!) { $latency = $1; }
        if ($out =~ m!throughput \s*=\s*(\d+\.\d+)!) { $throughput = $1; }
        if (! $minlatency || ! $minthroughput) { $minlatency = $latency;  $minthroughput = $throughput; }
        if ($latency < $minlatency) { $minlatency = $latency; }
        if ($throughput < $minthroughput) { $minthroughput = $throughput; }
    }

    $result->{latency} = $minlatency;
    $result->{throughput} = $minthroughput;
    return $result;
}


sub code_header
{
    return '#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <signal.h> 

#include <time.h>
#include <sys/time.h>
#include <stdio.h>

int main( int argc, char **argv )
{
    double t1, t2, tzero;
    struct timeval tv;
    long int i;

    long int loops = '.$loops.';
    double cpuspeed = '.$cpuspeed.';

    tzero = 0;

    printf("cpuspeed = %f\n", cpuspeed);
    printf("loops = %ld\n", loops);

';

}

sub code_footer
{
    return '
    return 0;
}

';

}

sub generate_one_test
{
    my (%opt) = @_;
    my $code;

    $opt{cmds_per_loop}   ||= 1024;
    $opt{num_xmm_regs}    = ($have_64bit ? 16 : 8);
    #$opt{reg_use_pattern} ||= 'throughput';

    my @regs_32bit = qw(eax ebx ecx edx esi edi); #  ebp esp
    my @regs_64bit = qw(rax rbx rcx rdx rsi rdi r8 r9 r10 r11 r12 r13 r14 r15);

    my $clobberlist = join ", ", map qq("$_"),
        map("xmm$_", 0..$opt{num_xmm_regs}-1),
        map("mm$_",  0..7),
        $have_64bit ? @regs_64bit : @regs_32bit;

    # FIXME
    if ($opt{ops}->[0] =~ m![ps]s !) { $opt{init_xmm_regs} = 'float'; }
    elsif ($opt{ops}->[0] =~ m![ps]d !) { $opt{init_xmm_regs} = 'double'; }
    else { $opt{init_xmm_regs} = 'integer'; }

# init timers
    $code .= '
// ***************************************************************************
// '.$opt{test_name}.'

        gettimeofday(&tv, NULL);
        t1 = (double)tv.tv_sec + (double)tv.tv_usec/1000000.0;

        asm volatile("emms");
';



# init registers
    $code .= '
        asm volatile(
';

    my %pxor = (integer=>"pxor", float=>"xorps", double=>"xorpd");
    foreach my $i (0 .. $opt{num_xmm_regs}-1)
    {
        $code .= qq("$pxor{$opt{init_xmm_regs}} %%xmm$i, %%xmm$i \\n"\n);
    }
    foreach my $i (0 .. 7)
    {
        $code .= qq("pxor %%mm$i, %%mm$i \\n"\n);
    }

    my $reserve_xmm0 = !!grep /xmm0/, @{$opt{ops}};
    $opt{num_xmm_regs} -= $reserve_xmm0;

    $code .= "::: $clobberlist);\n";

# write main loop
    $code .= '
        i = 0;
        while (i < loops)
        {
        i++;

        asm volatile(
	".align	64\n"
';

    if("@{$opt{ops}}" =~ m!div\b!) {
        $code .= qq("mov \$1, %%eax\\n"\n);
        $code .= qq("xor %%edx, %%edx\\n"\n);
    }

    for (my $i = 0; $i < $opt{cmds_per_loop}; $i++)
    {
        my $opspec = $opt{ops}->[ $i % scalar(@{ $opt{ops} }) ];
        my ($op) = split / /, $opspec;
        $op =~ m!^\w+$! or die "could not parse opspec";
        
        # FIXME don't need all types of registers for every op
        my ($xmm1, $xmm2);
        my ($mm1, $mm2);
        my ($r32_1, $r32_2);
        my ($r64_1, $r64_2);
        my $imm8 = 4;

        if ($opt{reg_use_pattern} =~ 'throughput')
        {
            # throughput
            # A*A->A, B*B->B, ...
            $xmm1  = sprintf('xmm%d', $i % $opt{num_xmm_regs} + $reserve_xmm0);
            $mm1   = sprintf('mm%d', $i % 8);
            $r32_1 = $regs_32bit[ $i % scalar(@regs_32bit) ];
            $r64_1 = $regs_64bit[ $i % scalar(@regs_64bit) ];
            $xmm2  = $xmm1;
            $mm2   = $mm1;
            $r32_2 = $r32_1;
            $r64_2 = $r64_1;
        }
        if ($opt{reg_use_pattern} eq 'latency')
        {
            # latency
            # A*B->B, B*C->C, ...
            $xmm1 = sprintf('xmm%d', ($i  ) % $opt{num_xmm_regs} + $reserve_xmm0);
            $xmm2 = sprintf('xmm%d', ($i+1) % $opt{num_xmm_regs} + $reserve_xmm0);
            $mm1 = sprintf('mm%d', ($i  ) % 8);
            $mm2 = sprintf('mm%d', ($i+1) % 8);
            $r32_1 = $regs_32bit[ ($i  ) % scalar(@regs_32bit) ];
            $r32_2 = $regs_32bit[ ($i+1) % scalar(@regs_32bit) ];
            $r64_1 = $regs_64bit[ ($i  ) % scalar(@regs_64bit) ];
            $r64_2 = $regs_64bit[ ($i+1) % scalar(@regs_64bit) ];

            my $unary = ($opspec =~ m!^$op (r\d+|x?mm)(, imm8)?$!);
            my $paired = ($opspec =~ m!^$op( mm, xmm| xmm, mm| r\d*, x?mm| x?mm, r\d*|$)!);
            if ($unary || $paired) {
                $xmm1 = "xmm1";
                $xmm2 = "xmm1";
                $mm1 = "mm1";
                $mm2 = "mm1";
                $r32_1 = $regs_32bit[0];
                $r32_2 = $regs_32bit[0];
                $r64_1 = $regs_64bit[0];
                $r64_2 = $regs_64bit[0];
            } elsif($opspec =~ m!r64, r32!) {
                ($r64_1 = $r32_2) =~ s!e!r!;
            }
            if ($paired) {
                my $j = 0;
                foreach (@instruction_paired_opposites) {
                    if ($opspec eq $_) {
                        if ($i&1) {
                            $opspec = $instruction_paired_opposites[$j^1];
                            ($op) = split / /, $opspec;
                        }
                        goto found_opposite;
                    }
                    $j++;
                }
                last;
                found_opposite:
            }
        }

        if ($op =~ m!div\b!) {
            if ($opt{reg_use_pattern} =~ m!throughput!) {
                $code .= qq("mov \$1, %%eax\\n"\n);
                $code .= qq("xor %%edx, %%edx\\n"\n);
            }
            $r32_1 = "eax";
            $r64_1 = "rax";
        }

        $opspec =~ m!^$op ?(.*)! or die;
        $op .= " " . join ", ", reverse split ", ", $1;
        $op =~ s!\bmm\b!%%$mm1!;
        $op =~ s!\bmm\b!%%$mm2!;
        $op =~ s!\bxmm0\b!%%xmm0!;
        $op =~ s!\bxmm\b!%%$xmm1!;
        $op =~ s!\bxmm\b!%%$xmm2!g;
        $op =~ s!\br32\b!%%$r32_1!;
        $op =~ s!\br32\b!%%$r32_2!;
        $op =~ s!\br64\b!%%$r64_1!;
        $op =~ s!\br64\b!%%$r64_2!;
        $op =~ s!\bimm8\b!\$$imm8!;
        $code .= qq("$op\\n"\n);
    }
    $code .= "::: $clobberlist);\n";

# calculate results
    $code .= '
        }
        asm volatile("emms");

        gettimeofday(&tv, NULL);
        t2 = (double)tv.tv_sec + (double)tv.tv_usec/1000000.0;
        printf("%-40s = %#.5g \n", "'. $opt{test_name} .'" ,
        (cpuspeed * 1000000 / (double)i) * (t2 - t1 - tzero) / (double)'.$opt{cmds_per_loop}.' );

        ';
    
    return $code;
}


sub getcpuspeed
{
    # try to kick frequency-variable cpu into max speed
    for (my $i = 0; $i < 10000000; $i++) { }

    my $fh = new IO::File("/proc/cpuinfo", "r");
    my $txt = join('', $fh->getlines());
    $fh->close();
    if ($txt =~ m!cpu MHz\s*:\s*(\d+\.\d+)!)
    {
        my $mhz = $1;
        return $mhz;
    }
    else
    {
        return 1000;
    }
}


sub timestamp
{
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    return sprintf("%04d%02d%02dT%02d%02d%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
}
