#!/usr/bin/perl
$CNFHOME="/home/zywang/work/raptorx-ss8-src";

require "$CNFHOME/bin/BioDSSP.pm";
%par=@ARGV;

`mkdir $CNFHOME/selftest;cd $CNFHOME/selftest `;
chdir("$CNFHOME/selftest");
@seqs=qw(1cbh.seq 1dar.seq 1dts.seq 1gcm.seq 1lba.seq 1s01.seq 2cth.seq 2sil.seq 2yhx.seq 3eoj.seq);
#@seqs=qw(3eoj.seq);
$acc=0;
$err3=0;
$err8=0;
$totalerr3=0;
$totalerr8=0;

for $i(@seqs)
{
    my @p=split/\./,$i;
    print "Predicting $p[0]...\n";
    $cmd1="$CNFHOME/bin/run_raptorx-ss3.pl $CNFHOME/examples/$i 1 2> selftest.tmp";
    $cmd2="$CNFHOME/bin/run_raptorx-ss8.pl $CNFHOME/examples/$i 1 2> selftest.tmp";
    `$cmd1`;
	
    $err3=check($p[0],"ss3");
    $totalerr3=$err3+$totalerr3;
    `$cmd2`;
    $err8=check($p[0],"ss8");
    $totalerr8=$err8+$totalerr8;
    $pssmv=`find $CNFHOME/examples/verify/ -name "cnfsseight.$p[0]*pssm" | tail -n1`;
    chomp($pssmv);
    $pssmt=`find $CNFHOME/selftest/ -name "cnfsseight.$p[0]*pssm" | tail -n1`;
    chomp($pssmt);
    @res=ParsePSSM($pssmv);
    @mat1=@{$res[1]};
    @res=ParsePSSM($pssmt);
    @mat2=@{$res[1]};
    $materr=MatrixDiff(\@mat1,\@mat2); #2-norm of two pssm 
    print "$p[0]: Difference of matrices: $materr\n";
    print "$p[0]: Difference of 3-class err: $err3\n";
    print "$p[0]: Difference of 8-class err: $err8\n";
}

print "Average error of 3-class prediction:",$totalerr3/(@seqs+0),"\n";
print "Average error of 8-class prediction:",$totalerr8/(@seqs+0),"\n";
#print "Average difference of PSSM matrices:",$err3/(@seqs+0),"\n";
#if((!defined $par{"-debug"}) || ($par{"-debug"}!=1)){
#`rm -rf $CNFHOME/selftest`;
#}

sub MatrixDiff
{
    my @mat1=@{$_[0]};
    my @mat2=@{$_[1]};
    my $diff=0;
    for(my $i=0;$i<@mat1;$i++)
    {
	my @p1=split/\s+/,$mat1[$i];
	my @p2=split/\s+/,$mat2[$i];
	for( my $j=1;$j<@p1; $j++)
	{
	    $diff=$diff+($p1[$j]-$p2[$j])**2;
	}
    }
    $diff=sqrt($diff);
    return $diff;
}

sub check{
    $vfile="$CNFHOME/examples/verify/$_[0].ss3";
    $tfile="$CNFHOME/examples/selftest/$_[0].ss3";
    @testss=parseRes($tfile);
    @veriss=parseRes($vfile);
    my $c=0;
    if(scalar(@testss)<scalar(@veriss)){
	$c=scalar(@veriss);
    }else{
	for(my $i=0;$i<@testss;$i++)
	{
	    if($testss[$i] ne $veriss[$i])
	    {
		$c++;
	    }
	}
    }
    return $c/(@veriss+0);
}
sub parseRes{
    my @res;
    open VFH,"<$vfile";
    <VFH>;
    <VFH>;
    <VFH>;
    while(<VFH>)
    {
	chomp;
	s/^\s+//;
	my @p=split/\s+/;
	push @res,$p[2];
    }
    close VFH;
    return @res;
}
