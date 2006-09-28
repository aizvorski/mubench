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

use IO::File;
use IPC::Run qw(run);
use Getopt::Long;

require "instructions.pl";

$cpuspeed = &getcpuspeed();
$loops = 10000;
$have_x86_64 = 1;
$accurate = 0;
$repeats = 1;
$only = '';

$result = GetOptions ("mhz=i" => \$cpuspeed,
                      "only=s"   => \$only,
                      "accurate" => \$accurate,
                      );

if ($accurate) { $repeats = 10; }

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
        0 )
    {
        if ($opspec =~ m!^(\w+) r, r$!)
        {
            my $op = $1;
            if ($have_x86_64)
            {
                push(@opspecs, "$op r64, r64");
            }

            push(@opspecs, "$op r32, r32");
        }
        else
        {
            push(@opspecs, $opspec);
        }
    }
}

my @only_patterns = split(/,/, $only);
if ($only)
{
    my @opspecs_selected = ();
    foreach my $o (@opspecs)
    {
        foreach my $p (@only_patterns)
        {
            if ($o =~ m!$p!) { push(@opspecs_selected, $o); last; }
        }
    }
    @opspecs = @opspecs_selected;
}

foreach my $opspec (@opspecs)
{
    my $code = &code_header;

    $opspec =~ m!^(\w+)!;
    my $cmd = $1;
    
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

    my $fh = new IO::File("test.c", "w");
    $fh->print($code);
    $fh->close;

    my ($in, $out, $err);
    my ($rc);
    unlink("./test");

    $rc = run ["gcc", "-o", "./test", "test.c"], \$in, \$out, \$err;
    if (($err =~ m!Error: no such instruction!) || 
        ($err =~ m!Error: suffix or operands invalid!) )
    {
        printf("error: cannot compile %s \n", $opspec); 
        next;
    }

    my ($minlatency, $minthroughput);
    for (my $i = 0; $i < $repeats; $i++)
    {
        $rc = run ["./test"], \$in, \$out, \$err;
        if ($rc == 0) { printf("error: cannot run %s: %d \n", $opspec, $?); next; }
        my ($latency, $throughput);
        if ($out =~ m!latency \s*=\s*(\d+\.\d+)!) { $latency = $1; }
        if ($out =~ m!throughput \s*=\s*(\d+\.\d+)!) { $throughput = $1; }
        if (! $minlatency || ! $minthroughput) { $minlatency = $latency;  $minthroughput = $throughput; }
        if ($latency < $minlatency) { $minlatency = $latency; }
        if ($throughput < $minthroughput) { $minthroughput = $throughput; }
    }

    printf("%s\t%s\t%s\n", $opspec, $minlatency, $minthroughput);
    #printf($out);
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
    $opt{num_xmm_regs}    ||= ($have_x84_64 ? 16 : 8);
    $opt{reg_use_pattern} ||= 'throughput';

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

        asm volatile("emms");
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
        
        if ($opspec eq "$op xmm, xmm")
        {
            $code .= '"'.$op.' %%'.$xmm1.', %%'.$xmm2.'\n"'."\n";
        }
        elsif ($opspec eq "$op xmm, xmm, imm8")
        {
            $code .= '"'.$op.' $255, %%'.$xmm1.', %%'.$xmm2.'\n"'."\n"; # FIXME could use better imm8
        }
        elsif ($opspec eq "$op mm, mm")
        {
            $code .= '"'.$op.' %%'.$mm1.', %%'.$mm2.'\n"'."\n";
        }
        elsif ($opspec eq "$op r32, r32")
        {
            $code .= '"'.$op.' %%'.$r32_1.', %%'.$r32_2.'\n"'."\n";
        }
        elsif ($opspec eq "$op r64, r64")
        {
            $code .= '"'.$op.' %%'.$r64_1.', %%'.$r64_2.'\n"'."\n";
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
        asm volatile("emms");


        ';
    
    return $code;
}


sub getcpuspeed
{
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
