#!/usr/bin/perl -w
use strict;
use Algorithm::Diff qw(LCS);
use Getopt::Std;

my $maxQty = 5;
my %opts;
getopts('G:g:m:', \%opts) || exit 2;
$maxQty = int($opts{m}) || $maxQty if $opts{m};

my @checks;
while (<>) {
 my %sourceWords;
 if (/^\s*(?:\S+\s+\d*\.?\d+\s*)+$/) {
  my @temp = split;
  for (my $i=0; $i<@temp; $i+=2) {
   $sourceWords{$temp[$i]} += $temp[$i+1]
  }
 } elsif (/\S/) {
  ++$sourceWords{$_} for split
 }
 push @checks, [ map { [$_, $sourceWords{$_}, [split //]] } keys %sourceWords ]
  if %sourceWords;
}

my @vowels = qw(a e i o u);
my @consonants = qw(m n l r p t k f s c x b d g v z j);
my @initialPairs = qw(ml mr pl pr tr ts tc kl kr fl fr sm sn sl sr sp st sk sf
 cm cn cl cr cp ct ck cf xl xr bl br dr dz dj gl gr vl vr zm zb zd zg zv jm jb
 jd jg jv);
my @internalPairs = qw(mn ml mr mp mt mk mf ms mc mx mb md mg mv mj nm nl nr np
 nt nk nf ns nc nx nb nd ng nv nz nj ln lm lr lp lt lk lf ls lc lx lb ld lg lv
 lz lj rn rm rl rp rt rk rf rs rc rx rb rd rg rv rz rj pn pm pl pr pt pk pf ps
 pc px tn tm tl tr tp tk tf ts tc tx kn km kl kr kp kt kf ks kc fn fm fl fr fp
 ft fk fs fc fx sn sm sl sr sp st sk sf sx cn cm cl cr cp ct ck cf xn xm xl xr
 xp xt xf xs bn bm bl br bd bg bv bz bj dn dm dl dr db dg dv dz dj gn gm gl gr
 gb gd gv gz gj vn vm vl vr vb vd vg vz vj zn zm zl zr zb zd zg zv jn jm jl jr
 jb jd jg jv);

my %blockingLetters = ('m' => ['n'],
		       'n' => ['m'],
		       'l' => ['r'],
		       'r' => ['l'],
		       'p' => ['b', 'f'],
		       't' => ['d'],
		       'k' => ['g', 'x'],
		       'f' => ['v', 'p'],
		       's' => ['z', 'c'],
		       'c' => ['j', 's'],
		       'x' => ['g', 'k'],
		       'b' => ['p', 'v'],
		       'd' => ['t'],
		       'g' => ['k', 'x'],
		       'v' => ['b', 'f'],
		       'z' => ['j', 's'],
		       'j' => ['c', 'z']);

my %possibleGismu;
if (exists $opts{G}) {
 my $in;
 if ($opts{G} eq '-') { $in = *STDIN }
 else { open $in, '<', $opts{G} or die "$0: $opts{G}: $!" }
 while (<$in>) {
  $possibleGismu{$1} = 1 if /^\s*([a-gi-pr-vxz]{5})\s*$/
 }
} else {
 for my $c1 (@consonants) {
  for my $v1 (@vowels) {
   for my $c2 (@internalPairs) {
    for my $v2 (@vowels) {
     $possibleGismu{"$c1$v1$c2$v2"} = 1;
    }
   }
  }
 }
 for my $c1 (@initialPairs) {
  for my $v1 (@vowels) {
   for my $c2 (@consonants) {
    for my $v2 (@vowels) {
     $possibleGismu{"$c1$v1$c2$v2"} = 1;
    }
   }
  }
 }
 if (exists $opts{g}) {
  my $in;
  if ($opts{g} eq '-') { $in = *STDIN }
  else { open $in, '<', $opts{g} or die "$0: $opts{g}: $!" }
  while (<$in>) {
   if (/^\s*([a-gi-pr-vxz]{5})\s*$/) {
    my $gismu = $1;
    my $g4 = substr($gismu, 0, 4);
    delete $possibleGismu{"$g4$_"} for @vowels;
    for my $i (0..3) {
     my $letter = substr($gismu, $i, 1);
     if (exists $blockingLetters{$letter}) {
      for my $newLetter (@{$blockingLetters{$letter}}) {
       substr($gismu, $i, 1) = $newLetter;
       delete $possibleGismu{$gismu};
      }
      substr($gismu, $i, 1) = $letter;
     }
    }
   }
  }
 }
}

print "Preliminary work finished.  Beginning scoring.\n";

for my $check (@checks) {
 my @sourceWords = @$check;
 print "\nSource words:";
 print " $$_[0] $$_[1]"
  for sort { $$b[1] <=> $$a[1] or $$a[0] cmp $$b[0] } @sourceWords;
 print "\n";
 my $count = 0;
 my @bestGismu;
 for my $gismu (keys %possibleGismu) {
  ++$count;
  print "First $count possible gismu scored.\n" if $count % 10000 == 0;
  my $score = 0;
  my @gismuSequence = split(//, $gismu);
  for my $source (@sourceWords) {
   my $word = $$source[0];
   my $weight = $$source[1];
   my @wordSequence = @{$$source[2]};
   my @lcs = LCS(\@wordSequence, \@gismuSequence);
   $score += $weight * @lcs / @wordSequence
    if @lcs >= 3 || (@lcs == 2 && match2($word, \@gismuSequence));
  }
  if (!@bestGismu) { push @bestGismu, [$score, $gismu] }
  elsif ($score >= $bestGismu[$#bestGismu][0]) {
   for my $i (0..$#bestGismu) {
    if ($score == $bestGismu[$i][0]) {
     push @{$bestGismu[$i]}, $gismu;
     last;
    } elsif ($score > $bestGismu[$i][0]) {
     splice @bestGismu, $i, 0, [$score, $gismu];
     pop @bestGismu if @bestGismu > $maxQty;
     last;
    }
   }
  }
 }
 print "Top score is $bestGismu[0][0].\n";
 printf " %-6g - %s\n", $_->[0], join(' ', splice(@$_, 1)) for @bestGismu;
}

sub match2 {
 # It's possible for there to be multiple two-character LCS's for a given pair
 # of strings, one of which meets the criteria in step 2b of the {gismu}
 # creation algorithm and one of which doesn't, and so the output from an LCS
 # function (unless it returns *all* LCS's) can't be used for step 2b.
 # Instead, almost all possible two-character substrings must be checked by
 # brute-force.  If you've got a better idea, I'd like to hear it.
 my($word, $gismuseq) = @_;
 my @gs = @$gismuseq;
 for my $i (0..3) {
  if ($i < 3) { return 1 if $word =~ /$gs[$i]($gs[$i+1]|.$gs[$i+2])/ }
  else { return 1 if index($word, $gs[$i] . $gs[$i+1]) != -1 }
 }
 return 0;
}
