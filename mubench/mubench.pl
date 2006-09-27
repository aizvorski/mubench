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

$cpuspeed = $ARGV[0] || &getcpuspeed();

@opspecs = ();
while ($l = <STDIN>)
{
    chomp $l;

    my $opspec = lc($l);
    if ($opspec =~ m!^(\w+) xmm, xmm$! ||
        $opspec =~ m!^(\w+) xmm, xmm/imm8$! ||
        $opspec =~ m!^(\w+) xmm, xmm, imm8$! ||
        0 )
    {
        my $cmd = $1;
        #next if ($cmd =~ m!^cvt!);
        #next if ($cmd =~ m!^cmp!);
        next if ($cmd =~ m!^(div|sqrt|rsqrt|rcp)!);
        push(@opspecs, $opspec);
    }
}


foreach my $opspec (@opspecs)
{
    my $code = &code_header;

    $opspec =~ m!^(\w+)!;
    my $cmd = $1;

    my $init_xmm_regs = 'integer';
    
    if ($cmd =~ m!ps$!) { $init_xmm_regs = 'float'; }
    elsif ($cmd =~ m!pd$!) { $init_xmm_regs = 'double'; }
    
    $code .= &generate_one_test(
                       test_name => "$cmd throughput",
                       ops => [ $opspec ],
                       cmds_per_loop => 1024,
                       num_xmm_regs => 16,
                       reg_use_pattern => 'throughput',
                       init_xmm_regs => $init_xmm_regs,
                       );
    
    #&generate_one_test(
    #    test_name => "$cmd throughput2",
    #    ops => [ $opspec ],
    #    cmds_per_loop => 1024,
    #    num_xmm_regs => 16,
    #    reg_use_pattern => 'throughput2',
    #    init_xmm_regs => $init_xmm_regs,
    #    );
    
    $code .=  &generate_one_test(
                       test_name => "$cmd latency",
                       ops => [ $opspec ],
                       cmds_per_loop => 1024,
                       num_xmm_regs => 16,
                       reg_use_pattern => 'latency',
                       init_xmm_regs => $init_xmm_regs,
                       );
    
    
    foreach my $opspec2 (@opspecs)
    {
        $opspec2 =~ m!^(\w+)!;
        my $cmd2 = $1;
        
        $code .= &generate_one_test(
                           test_name => "  $cmd,$cmd2 throughput",
                           ops => [ $opspec, $opspec2 ],
                           cmds_per_loop => 1024,
                           num_xmm_regs => 16,
                           reg_use_pattern => 'throughput',
                           init_xmm_regs => $init_xmm_regs,
                           );
    }

    $code .= &code_footer;

    my $fh = new IO::File("test.c", "w");
    $fh->print($code);
    $fh->close;

    system("gcc -o test test.c");
    
    system("./test");
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

    long int loops = 1000;
    double cpuspeed = '.$cpuspeed.';

    if (argc > 1) { cpuspeed = atof(argv[1]) * 1e+06; }
    if (cpuspeed == 0) { cpuspeed = 1e+09; }

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
    $opt{num_xmm_regs}    ||= 8;
    $opt{reg_use_pattern} ||= 'throughput';
    $opt{init_xmm_regs}   ||= 'integer';

    my $clobberlist = '';
    for (my $i = 0; $i < $opt{num_xmm_regs}; $i++)
    {
        $clobberlist .= '"%xmm'.$i.'", ';
    }
    $clobberlist =~ s!, $!!;

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
        
        my ($reg1, $reg2);
        if ($opt{reg_use_pattern} eq 'throughput')
        {
            # throughput
            # A*B->A, B*C->B, ...
            $reg1 = sprintf('xmm%d', ($i+1) % $opt{num_xmm_regs});
            $reg2 = sprintf('xmm%d', ($i  ) % $opt{num_xmm_regs});
        }
        if ($opt{reg_use_pattern} eq 'throughput2')
        {
            # throughput, type two
            # A*B->A, C*D->C, ...
            $reg1 = sprintf('xmm%d', (2*$i+1) % $opt{num_xmm_regs});
            $reg2 = sprintf('xmm%d', (2*$i  ) % $opt{num_xmm_regs});
        }
        if ($opt{reg_use_pattern} eq 'latency')
        {
            # latency
            # A*B->B, B*C->C, ...
            $reg1 = sprintf('xmm%d', ($i  ) % $opt{num_xmm_regs});
            $reg2 = sprintf('xmm%d', ($i+1) % $opt{num_xmm_regs});
        }
        
        if ($opspec eq "$op xmm, xmm" ||
            $opspec eq "$op xmm, xmm/imm8")
        {
            $code .= '"'.$op.' %%'.$reg1.', %%'.$reg2.'\n"'."\n";
        }
        elsif ($opspec eq "$op xmm, xmm, imm8")
        {
            $code .= '"'.$op.' $255, %%'.$reg1.', %%'.$reg2.'\n"'."\n";
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
        (cpuspeed / (double)i) * (t2 - t1 - tzero) / (double)'.$opt{cmds_per_loop}.' );
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
        return $mhz * 1000000;
    }
    else
    {
        return 1000 * 1000000;
    }
}
