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

$VERSION = '0.2.0';

use IO::File;
use IPC::Run qw(run);
use Getopt::Long;

require "instructions.pl";

$options_string = join(' ', $0, @ARGV);

$cpuspeed = &getcpuspeed();
$loops = 100000;
$have_64bit = 1;
$have_32bit = 1;
$pairs = 1;
$accurate = 1;
$fast = 0;
$repeats = 3;
$include = '';
$output = 'xml';
$outfile = undef;

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
                      );

if ($accurate) { $repeats = 10; }
if ($fast) { $repeats = 1; }

@opspecs = ();
foreach my $l (@instructions)
{
    my $opspec = lc($l);
    $opspec =~ s!xmm/imm8!xmm!;
    $opspec =~ s!mm/imm8!mm!;

    if ($opspec =~ m!^(\w+) xmm, xmm$! ||
        $opspec =~ m!^(\w+) xmm, xmm, imm8$! ||
        $opspec =~ m!^(\w+) mm, mm$! ||
        $opspec =~ m!^(\w+) r, r$! ||
        $opspec =~ m!^(\w+) r$! ||
        $opspec =~ m!^(\w+) r, imm8$! ||
        0 )
    {
        if ($opspec =~ m!^(\w+) r, r$!)
        {
            my $op = $1;
            if ($have_64bit)
            {
                push(@opspecs, "$op r64, r64");
            }
            if ($have_32bit)
            {
                push(@opspecs, "$op r32, r32");
            }
        }
        elsif ($opspec =~ m!^(\w+) r$!)
        {
            my $op = $1;
            if ($have_64bit)
            {
                push(@opspecs, "$op r64");
            }
            if ($have_32bit)
            {
                push(@opspecs, "$op r32");
            }
        }
        elsif ($opspec =~ m!^(\w+) r, imm8$!)
        {
            my $op = $1;
            if ($have_64bit)
            {
                push(@opspecs, "$op r64, imm8");
            }
            if ($have_32bit)
            {
                push(@opspecs, "$op r32, imm8");
            }
        }
        else
        {
            push(@opspecs, $opspec);
        }
    }
}

# filter instructions based on include patterns
my @include_patterns = split(/,/, $include);
if ($include)
{
    my @opspecs_selected = ();
    foreach my $o (@opspecs)
    {
        foreach my $p (@include_patterns)
        {
            if ($o =~ m!$p!) { push(@opspecs_selected, $o); last; }
        }
    }
    @opspecs = @opspecs_selected;
}

if ($pairs) { $num_tests = scalar(@opspecs) * scalar(@opspecs); }
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
    run ["gcc", "-v"], \$in, \$out, \$err;
    $outfh->printf("\n<gcc-version>$err</gcc-version>\n");

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

    $rc = run ["gcc", "-o", "./test", "./test.c"], \$in, \$out, \$err;
    if (($err =~ m!Error: no such instruction!) || 
        ($err =~ m!Error: suffix or operands invalid!) ||
        ($err =~ m!Error: bad register name!) ) 
    {
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

    my $clobberlist = '';
    for (my $i = 0; $i < $opt{num_xmm_regs}; $i++)
    {
        $clobberlist .= '"%xmm'.$i.'", ';
    }
    for (my $i = 0; $i < 8; $i++)
    {
        $clobberlist .= '"%mm'.$i.'", ';
    }
    for (my $i = 0; $i < scalar(@regs_32bit); $i++)
    {
        $clobberlist .= '"%'.$regs_32bit[ $i ].'", ';
    }
    for (my $i = 0; $i < scalar(@regs_64bit); $i++)
    {
        $clobberlist .= '"%'.$regs_64bit[ $i ].'", ';
    }
    $clobberlist =~ s!, $!!;

    # FIXME
    if ($opt{ops}->[0] =~ m!ps !) { $opt{init_xmm_regs} = 'float'; }
    elsif ($opt{ops}->[0] =~ m!pd !) { $opt{init_xmm_regs} = 'double'; }
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

    for (my $i = 0; $i < $opt{num_xmm_regs}; $i++)
    {
        if ($opt{init_xmm_regs} eq 'integer')
        {
            $code .= '"pxor %%xmm'.$i.', %%xmm'.$i.' \n"'. "\n";
        }
        elsif ($opt{init_xmm_regs} eq 'float')
        {
            $code .= '"xorps %%xmm'.$i.', %%xmm'.$i.' \n"'. "\n";
        }
        elsif ($opt{init_xmm_regs} eq 'double')
        {
            $code .= '"xorpd %%xmm'.$i.', %%xmm'.$i.' \n"'. "\n";
        }
    }

    $code .= '
         : 
         : 
         : '.$clobberlist.'
        );
';

# write main loop
    $code .= '
        i = 0;
        while (i < loops)
        {
        i++;

        asm volatile(
';

    for (my $i = 0; $i < $opt{cmds_per_loop}; $i++)
    {
        my $opspec = $opt{ops}->[ $i % scalar(@{ $opt{ops} }) ];
        my $op;
        if ($opspec =~ m!^(\w+)!)
        {
            $op = $1;
        }
        else { die "could not parse opspec"; }
        
        # FIXME don't need all types of registers for every op
        my ($xmm1, $xmm2);
        my ($mm1, $mm2);
        my ($r32_1, $r32_2);
        my ($r64_1, $r64_2);
        if ($opt{reg_use_pattern} eq 'throughput')
        {
            # throughput
            # A*B->A, B*C->B, ...
            $xmm1 = sprintf('xmm%d', ($i+1) % $opt{num_xmm_regs});
            $xmm2 = sprintf('xmm%d', ($i  ) % $opt{num_xmm_regs});
            $mm1 = sprintf('mm%d', ($i+1) % 8);
            $mm2 = sprintf('mm%d', ($i  ) % 8);
            $r32_1 = $regs_32bit[ ($i+1) % scalar(@regs_32bit) ];
            $r32_2 = $regs_32bit[ ($i  ) % scalar(@regs_32bit) ];
            $r64_1 = $regs_64bit[ ($i+1) % scalar(@regs_64bit) ];
            $r64_2 = $regs_64bit[ ($i  ) % scalar(@regs_64bit) ];
        }
        if ($opt{reg_use_pattern} eq 'throughput2')
        {
            # throughput, type two
            # A*B->A, C*D->C, ...
            $xmm1 = sprintf('xmm%d', (2*$i+1) % $opt{num_xmm_regs});
            $xmm2 = sprintf('xmm%d', (2*$i  ) % $opt{num_xmm_regs});
            $mm1 = sprintf('mm%d', (2*$i+1) % 8);
            $mm2 = sprintf('mm%d', (2*$i  ) % 8);
            $r32_1 = $regs_32bit[ (2*$i+1) % scalar(@regs_32bit) ];
            $r32_2 = $regs_32bit[ (2*$i  ) % scalar(@regs_32bit) ];
            $r64_1 = $regs_64bit[ (2*$i+1) % scalar(@regs_64bit) ];
            $r64_2 = $regs_64bit[ (2*$i  ) % scalar(@regs_64bit) ];
        }
        if ($opt{reg_use_pattern} eq 'latency')
        {
            # latency
            # A*B->B, B*C->C, ...
            $xmm1 = sprintf('xmm%d', ($i  ) % $opt{num_xmm_regs});
            $xmm2 = sprintf('xmm%d', ($i+1) % $opt{num_xmm_regs});
            $mm1 = sprintf('mm%d', ($i  ) % 8);
            $mm2 = sprintf('mm%d', ($i+1) % 8);
            $r32_1 = $regs_32bit[ ($i  ) % scalar(@regs_32bit) ];
            $r32_2 = $regs_32bit[ ($i+1) % scalar(@regs_32bit) ];
            $r64_1 = $regs_64bit[ ($i  ) % scalar(@regs_64bit) ];
            $r64_2 = $regs_64bit[ ($i+1) % scalar(@regs_64bit) ];
        }

        if ($op =~ m!^(div|idiv|mul|imul)$!) { $r32_2 = 'eax'; $r64_2 = 'rax'; }
        my $imm8 = 16;

        if ($opspec eq "$op xmm, xmm")
        {
            $code .= '"'.$op.' %%'.$xmm1.', %%'.$xmm2.'\n"'."\n";
        }
        elsif ($opspec eq "$op xmm, xmm, imm8")
        {
            $code .= '"'.$op.' $'.$imm8.', %%'.$xmm1.', %%'.$xmm2.'\n"'."\n"; # FIXME could use better imm8
        }
        elsif ($opspec eq "$op mm, mm")
        {
            $code .= '"'.$op.' %%'.$mm1.', %%'.$mm2.'\n"'."\n";
        }
        elsif ($opspec eq "$op r64, r64")
        {
            $code .= '"'.$op.' %%'.$r64_1.', %%'.$r64_2.'\n"'."\n";
        }
        elsif ($opspec eq "$op r32, r32")
        {
            $code .= '"'.$op.' %%'.$r32_1.', %%'.$r32_2.'\n"'."\n";
        }
        elsif ($opspec eq "$op r64")
        {
            $code .= '"'.$op.' %%'.$r64_1.'\n"'."\n";
        }
        elsif ($opspec eq "$op r32")
        {
            $code .= '"'.$op.' %%'.$r32_1.'\n"'."\n";
        }
        elsif ($opspec eq "$op r64, imm8")
        {
            $code .= '"'.$op.' $'.$imm8.', %%'.$r64_1.'\n"'."\n";
        }
        elsif ($opspec eq "$op r32, imm8")
        {
            $code .= '"'.$op.' $'.$imm8.', %%'.$r32_1.'\n"'."\n";
        }
    }
    $code .= '
         : 
         : 
         : '.$clobberlist.'
        );
        ';

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
