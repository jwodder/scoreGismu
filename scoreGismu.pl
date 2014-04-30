#!/usr/bin/perl

use warnings;

use Algorithm::Diff qw(LCS);

@checks = ();
while(<>) {
 %sourceWords = ();
 @sourceWords = ();
 if(/^\s*(?:\S+\s+\d*\.?\d+\s*)+\s*$/) {
  @temp = (split /\s+/);
  for($i=0; $i<@temp; $i+=2) {
   $sourceWords{$temp[$i]} += $temp[$i+1];
  }
  push @sourceWords, [$_, $sourceWords{$_}, [split //]] for keys %sourceWords;
 } elsif(/\S/) {
  ++$sourceWords{$_} for split /\s+/;
  push @sourceWords, [$_, $sourceWords{$_}, [split //]] for keys %sourceWords;
 }
 push @checks, [@sourceWords] if @sourceWords;
}

@vowels = qw(a e i o u);
@consonants = qw(m n l r p t k f s c x b d g v z j);
@initialPairs = qw(ml mr pl pr tr ts tc kl kr fl fr sm sn sl sr sp st sk sf cm cn cl cr cp ct ck cf xl xr bl br dr dz dj gl gr vl vr zm zb zd zg zv jm jb jd jg jv);
@internalPairs = qw(mn ml mr mp mt mk mf ms mc mx mb md mg mv mj nm nl nr np nt nk nf ns nc nx nb nd ng nv nz nj ln lm lr lp lt lk lf ls lc lx lb ld lg lv lz lj rn rm rl rp rt rk rf rs rc rx rb rd rg rv rz rj pn pm pl pr pt pk pf ps pc px tn tm tl tr tp tk tf ts tc tx kn km kl kr kp kt kf ks kc fn fm fl fr fp ft fk fs fc fx sn sm sl sr sp st sk sf sx cn cm cl cr cp ct ck cf xn xm xl xr xp xt xf xs bn bm bl br bd bg bv bz bj dn dm dl dr db dg dv dz dj gn gm gl gr gb gd gv gz gj vn vm vl vr vb vd vg vz vj zn zm zl zr zb zd zg zv jn jm jl jr jb jd jg jv);

%blockingLetters = ('m' => ['n'],
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

for $c1 (@consonants) {
 for $v1 (@vowels) {
  for $c2 (@internalPairs) {
   for $v2 (@vowels) {
    $possibleGismu{"$c1$v1$c2$v2"} = 1;
   }
  }
 }
}
for $c1 (@initialPairs) {
 for $v1 (@vowels) {
  for $c2 (@consonants) {
   for $v2 (@vowels) {
    $possibleGismu{"$c1$v1$c2$v2"} = 1;
   }
  }
 }
}

$file = 'gismu.txt';
open(IN, $file) or die "Couldn't open $file: $!\n";
while(<IN>) {
 if(/\s*([a-gi-pr-vxz]{5})/) {
  $gismu = $1;
  $gismu =~ s/^\s+//;
  $gismu =~ s/\s+$//;
  if(length $gismu == 5) {
   $g4 = substr($gismu, 0, 4);
   delete $possibleGismu{"$g4$_"} for @vowels;
   for $i (0..3) {
    $letter = substr($gismu, $i, 1);
    if(exists $blockingLetters{$letter}) {
     for $newLetter (@{$blockingLetters{$letter}}) {
      substr($gismu, $i, 1) = $newLetter;
      delete $possibleGismu{$gismu};
     }
     substr($gismu, $i, 1) = $letter;
    }
   }
  }
 }
}
close IN;

print "Preliminary work finished. Beginning scoring.\n";

for $check (@checks) {
 @sourceWords = @$check;
 print "\nSource words:";
 print " $$_[0] $$_[1]" for sort {$$b[1] <=> $$a[1] or $$a[0] cmp $$b[0]} @sourceWords;
 print "\n";
 $count = 0;
 $max = 0;
 @bestGismu = ();
 for $gismu (keys %possibleGismu) {
  ++$count;
  print "First $count possible gismu scored.\n" if $count % 10000 == 0;
  $score = 0;
  @gismuSequence = split(//, $gismu);
  for $source (@sourceWords) {
   $word = $$source[0];
   $weight = $$source[1];
   @wordSequence = @{$$source[2]};
   @lcs = LCS(\@wordSequence, \@gismuSequence);
   if(@lcs >= 3) {
    $score += $weight * @lcs / @wordSequence;
   } elsif(@lcs == 2) {
    if($gismu =~ /$lcs[0].?$lcs[1]/) {
     if($word =~ /$lcs[0].?$lcs[1]/) {
      $score += $weight * 2 / @wordSequence;
     }
    }
   }
  }
  if($score >= $max) {
   $max = $score;
   unshift(@bestGismu, [$gismu, $score]);
  }
 }
 print "Top score is $max.\n";
 for $gismu (@bestGismu) {
  last if @$gismu[1] < $max;
  print " @$gismu[0]";
 }
 print "\n";
}