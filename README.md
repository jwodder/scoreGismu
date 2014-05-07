    perl scoreGismu.pl [-g gismu file] [-m num] [input file]

`scoreGismu.pl` implements steps 2 through 5 of the _gismu_ scoring algorithm
described in §4.14 of _The Complete Lojban Language_ to produce a _gismu_ from
a given set of source words.  Each line of input to the program specifies a set
of Lojbanized source words and their language weights, e.g.:

    iun 0.347 upiog 0.196 emploi 0.160 us 0.123 primin 0.089 amal 0.085

(If the same word appears more than once in the same line, its final weight is
the sum of its listed weights.)  Alternatively, a line may contain only
Lojbanized source words, in which case the weights are the number of times each
word appears on the line.

For each input line, `scoreGismu.pl` will calculate the _gismu_ that match the
given source words the best according to the scoring algorithm and output the
top 5 scores (or an amount specified with the `-m` switch) and the _gismu_ that
obtained them.  Note that calculations for separate lines do not take each
other into account, and so if multiple _gismu_ sets are produced at once, they
may conflict with each other.

A file containing a list of pre-existing _gismu_, one per line, may optionally
be specified with the `-g` switch.  Any _gismu_ listed in this file or that
conflicts with a _gismu_ in this file will be excluded from consideration for
the algorithm.

This code was originally taken from [\[1\]][1], where it [was credited to one
"Hussell"][2].

For reference, the language weights used in creating the official _gismu_ were,
as listed in §4.14 of the CLL:

    Chinese     0.36
    English     0.21
    Hindi       0.16
    Spanish     0.11
    Russian     0.09
    Arabic      0.07

Some later _gismu_ instead used the weights:

    Chinese     0.347
    Hindi       0.196
    English     0.160
    Spanish     0.123
    Russian     0.089
    Arabic      0.085

[1]: https://groups.google.com/d/msg/lojban/MYL6KsfNKzc/-6LiJISgP0MJ
[2]: https://groups.google.com/d/msg/lojban/MYL6KsfNKzc/O3LFGdRV5WEJ
