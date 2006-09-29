%benchmark_files = (
                    'Intel C2' => '',
                    'AMD K7' => '',
                    );

foreach my $cpu (@cpus)
{
}


$html .= "<table>";
$html .= "<tr>";
$html .= "<td>Instruction</td>";
foreach my $cpu (@cpus)
{
    $html .= "<td>".$cpu."</td>";
}
$html .= "</tr>"."\n";

foreach my $opspec (@opspecs)
{
    $html .= "<tr>";
    $html .= "<td>".$opspec."</td>";
    foreach my $cpu (@cpus)
    {
        $html .= "<td>". &round_to_fraction( $results->{$cpu}->{$opspec}->{throughput} )."</td>";
    }
    $html .= "</tr>"."\n";
}
$html .= "</table>"."\n";


sub round_to_fraction
{
    my ($v) = @_;
    my $accuracy = 0.03;
    foreach my $rv (0.25, 0.33, 0.5, 0.66, 0.75, 1, 1.25, 1.33, 1.5, 1.75, 2, 3, 4, 5, 6, 7, 8)
    {
        if (abs($rv - $v) < $accuracy * $rv)
        {
            return $rv;
        }
    }

    return $v;
}

# /mubench/test[op="foo"]
sub parse_mubench_results
{
    my ($xml) = @_;
    while ($xml =~ m!<test>(.*?)</test>!)
    {
        my $test = $1;
        if ($test =~ m!<op>(.*?)</op><op>(.*?)</op>!)
        {
            
        }
    }
}
