use XML::XPath;

%benchmark_results = (
                      'Intel Core2' => +{ file => 'mubench-results-20060928T200612.xml' },
                      'AMD K7' =>  +{ file => 'mubench-results-20060929T062529.xml' },
                      'AMD K8' =>  +{ file => 'mubench-results-20060929T100150.xml' },
                      'Intel P4 (F2)' => +{ file => 'mubench-results-20060929T144442.xml' },
                      );

@cpus = sort keys %benchmark_results;
foreach my $cpu (@cpus)
{
    $benchmark_results{ $cpu }->{xp} = new XML::XPath( filename => $benchmark_results{ $cpu }->{file} );
}

@opspecs = &mubench_result_get_all_ops( $benchmark_results{ $cpus[1] }->{xp} );
#%opspecs_hash = map { $_ => 1 } @opspecs;
#@opspecs = sort keys %opspecs_hash;


$html .= "<table>";
$html .= "<tr>";
$html .= "<td rowspan=2>Instruction</td>";
$html .= "<td colspan=".scalar(@cpus)." align=\"center\">Latency</td>";
$html .= "<td colspan=".scalar(@cpus)." align=\"center\">Throughput (Reciprocal )</td>";
$html .= "</tr>"."\n";
$html .= "<tr>";
foreach my $cpu (@cpus)
{
    $html .= "<td>".$cpu."</td>";
}
foreach my $cpu (@cpus)
{
    $html .= "<td>".$cpu."</td>";
}
$html .= "</tr>"."\n";

foreach my $op (@opspecs)
{
    $html .= "<tr>";
    $html .= "<td>".$op."</td>";
    foreach my $cpu (@cpus)
    {
        $html .= "<td>". 
            &round_to_fraction( &mubench_result_get_latency_for_op($benchmark_results{$cpu}->{xp}, $op) ).
            "</td>";
    }
    foreach my $cpu (@cpus)
    {
        $html .= "<td>". 
            &round_to_fraction( &mubench_result_get_throughput_for_op($benchmark_results{$cpu}->{xp}, $op) ).
            "</td>";
    }
    $html .= "</tr>"."\n";
}
$html .= "</table>"."\n";

print $html;




sub round_to_fraction
{
    my ($v) = @_;
    my $accuracy = 0.05;
    foreach my $rv (0.25, 0.33, 0.5, 0.66, 0.75, 1, 1.25, 1.33, 1.5, 1.75, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    {
        if (abs($rv - $v) < $accuracy * $rv)
        {
            return $rv;
        }
    }
    
    if ($v)
    {
        return sprintf("%.2f", $v);
    }
    else
    {
        return "-";
    }
}

sub mubench_result_get_all_ops
{
    my ($xp) = @_;
    @ops = map { $_->string_value() } $xp->findnodes('/mubench/test/op');
    return @ops;
}

sub mubench_result_get_latency_for_op
{
    my ($xp, $op) = @_;
    my @nodes = $xp->findnodes('/mubench/test[op="'.$op.'" and count(op)=1]/l');
    if (scalar(@nodes)){ return $nodes[0]->string_value(); }
    else { return undef; }
}

sub mubench_result_get_throughput_for_op
{
    my ($xp, $op) = @_;
    my @nodes = $xp->findnodes('/mubench/test[op="'.$op.'" and count(op)=1]/t');
    if (scalar(@nodes)){ return $nodes[0]->string_value(); }
    else { return undef; }
}

sub mubench_result_get_throughput_for_ops_pair
{
    my ($xp, $op, $op2) = @_;
    my @nodes = $xp->findnodes('/mubench/test[op="'.$op.'" and op="'.$op2.'" and count(op)=2]/t');
    if (scalar(@nodes)){ return $nodes[0]->string_value(); }
    else { return undef; }
}

