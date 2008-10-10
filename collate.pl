#!/usr/bin/perl -w
$cpun = 0;
foreach $f (@ARGV) {
    my $name = "cpu$cpun";
    $f =~ s/^([^=]+)=// and $name = $1;
    @order = ();
    if($f =~ /bz2$/) {
        open FH, "-|", "bzcat", $f;
    } else {
        open FH, "<", $f;
    }
    while(<FH>) {
        m#<op>([^<>]+)</op># or next;
        my $op = $1;
        push @order, $op;
        if(m#<l>(\d+\.\d+)</l><t>(\d+\.\d+)</t>#) {
            $time{$op}[$cpun] = sprintf "%.1f/%.1f", round($1), round($2);
        } else {
            $time{$op}[$cpun] = "err";
        }
    }
    close FH;
    $cpun++;
}
foreach my $op (@order) {
    next if !grep {$_ && !/err/} @{$time{$op}};
    printf "%-22s ", $op;
    foreach my $t (@{$time{$op}}) {
        defined($t) or $t = "undef";
        if($t =~ m#(.*)/(.*)#) {
            my($a,$b) = ($1,$2);
            $a =~ s/\.0+$//;
            $b =~ s/\.0+$//;
            $t = sprintf "%4s/%-4s", $a, $b;
        } else {
            $t = " "x((10-length($t))/2) . $t . " "x((9-length($t))/2);
        }
        print "$t ";
    }
    print "\n";
}

sub round {
    my $n = shift;
    my $i = int($n);
    $n -= $i;
    my @fracs = (0, .1, .25, .33, .5, .67, .75, .9, 1);
    return $i + (sort {abs($a-$n) <=> abs($b-$n)} @fracs)[0];
}
