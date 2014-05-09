#include <cstdlib>  /* strtol */
#include <cstring>  /* strerror */
#include <cerrno>
#include <unistd.h>
#include <iostream>
#include <algorithm>  /* lower_bound, max, sort */
#include <deque>
#include <fstream>
#include <list>
#include <map>
#include <set>
#include <sstream>  /* istringstream */
#include <string>
#include <utility>  /* pair */
using namespace std;

const char vowels[] = "aeiou";
const char consonants[] = "mnlrptkfscxbdgvzj";

const char initialPairs[][3] = {
 "ml", "mr", "pl", "pr", "tr", "ts", "tc", "kl", "kr", "fl", "fr", "sm", "sn",
 "sl", "sr", "sp", "st", "sk", "sf", "cm", "cn", "cl", "cr", "cp", "ct", "ck",
 "cf", "xl", "xr", "bl", "br", "dr", "dz", "dj", "gl", "gr", "vl", "vr", "zm",
 "zb", "zd", "zg", "zv", "jm", "jb", "jd", "jg", "jv"};

const char internalPairs[][3] = {
 "mn", "ml", "mr", "mp", "mt", "mk", "mf", "ms", "mc", "mx", "mb", "md", "mg",
 "mv", "mj", "nm", "nl", "nr", "np", "nt", "nk", "nf", "ns", "nc", "nx", "nb",
 "nd", "ng", "nv", "nz", "nj", "ln", "lm", "lr", "lp", "lt", "lk", "lf", "ls",
 "lc", "lx", "lb", "ld", "lg", "lv", "lz", "lj", "rn", "rm", "rl", "rp", "rt",
 "rk", "rf", "rs", "rc", "rx", "rb", "rd", "rg", "rv", "rz", "rj", "pn", "pm",
 "pl", "pr", "pt", "pk", "pf", "ps", "pc", "px", "tn", "tm", "tl", "tr", "tp",
 "tk", "tf", "ts", "tc", "tx", "kn", "km", "kl", "kr", "kp", "kt", "kf", "ks",
 "kc", "fn", "fm", "fl", "fr", "fp", "ft", "fk", "fs", "fc", "fx", "sn", "sm",
 "sl", "sr", "sp", "st", "sk", "sf", "sx", "cn", "cm", "cl", "cr", "cp", "ct",
 "ck", "cf", "xn", "xm", "xl", "xr", "xp", "xt", "xf", "xs", "bn", "bm", "bl",
 "br", "bd", "bg", "bv", "bz", "bj", "dn", "dm", "dl", "dr", "db", "dg", "dv",
 "dz", "dj", "gn", "gm", "gl", "gr", "gb", "gd", "gv", "gz", "gj", "vn", "vm",
 "vl", "vr", "vb", "vd", "vg", "vz", "vj", "zn", "zm", "zl", "zr", "zb", "zd",
 "zg", "zv", "jn", "jm", "jl", "jr", "jb", "jd", "jg", "jv"};

const char blockingLetters[26][3] = {
 "", "pv", "js", "t", "", "vp", "kx", "", "", "cz", "gx", "r", "n", "m", "",
 "bf", "", "l", "zc", "d", "", "bf", "", "gk", "", "js"};

typedef pair< double, deque<string> > gismuRank;  /* This shows up too much. */

ifstream* openIF(const char* program, const char* path);
deque< map<string,double> >* readInput(istream& in);
int LCS(const string& a, const string& b);
bool cmpInput(pair<string,double> a, pair<string,double> b);
bool match2(const string& word, const string& gismu);
bool cmpRank(const gismuRank& a, double b);

int main(int argc, char** argv) {
 int maxQty = 5, ch;
 char* gimste = NULL;
 while ((ch = getopt(argc, argv, "g:m:")) != -1) {
  switch (ch) {
   case 'g': gimste = optarg; break;
   case 'm': {
    int tmp = strtol(optarg, NULL, 10);
    if (tmp >= 1) maxQty = tmp;
    break;
   }
   default:
    cerr << "Usage: " << argv[0] << " [-g gismu file] [-m n] [input file]"
	 << endl;
    return 2;
  }
 }

 deque< map<string,double> >* checks;
 if (optind < argc) {
  ifstream* infile = openIF(argv[0], argv[optind]);
  if (!infile) return 5;
  checks = readInput(*infile);
  infile->close();
  delete infile;
 } else {checks = readInput(cin); }

 set<string> possibleGismu;
 char gismuTmp[6] = {0};
 for (const char* c1 = consonants; *c1 != '\0'; c1++) {
  gismuTmp[0] = *c1;
  for (const char* v1 = vowels; *v1 != '\0'; v1++) {
   gismuTmp[1] = *v1;
   for (size_t i=0; i < sizeof(internalPairs)/sizeof(internalPairs[0]); i++) {
    gismuTmp[2] = internalPairs[i][0];
    gismuTmp[3] = internalPairs[i][1];
    for (const char* v2 = vowels; *v2 != '\0'; v2++) {
     gismuTmp[4] = *v2;
     possibleGismu.insert(string(gismuTmp));
    }
   }
  }
 }
 for (size_t i=0; i < sizeof(initialPairs)/sizeof(initialPairs[0]); i++) {
  gismuTmp[0] = initialPairs[i][0];
  gismuTmp[1] = initialPairs[i][1];
  for (const char* v1 = vowels; *v1 != '\0'; v1++) {
   gismuTmp[2] = *v1;
   for (const char* c1 = consonants; *c1 != '\0'; c1++) {
    gismuTmp[3] = *c1;
    for (const char* v2 = vowels; *v2 != '\0'; v2++) {
     gismuTmp[4] = *v2;
     possibleGismu.insert(string(gismuTmp));
    }
   }
  }
 }

 if (gimste != NULL) {
  ifstream* gfile = openIF(argv[0], gimste);
  if (!gfile) return 5;
  string line;
  while (getline(*gfile, line)) {
   size_t gstart = line.find_first_not_of(" \t\n\r\v\f");
   if (gstart == string::npos) continue;
   size_t gend = line.find_last_not_of(" \t\n\r\v\f");
   if (gend - gstart + 1 != 5) continue;
   string gismu = line.substr(gstart, gend - gstart + 1);
   if (gismu.find_first_not_of("abcdefgijklmnoprstuvxz") != string::npos)
    continue;
   char letter = gismu[4];
   for (const char* v1 = vowels; *v1 != '\0'; v1++) {
    gismu[4] = *v1;
    possibleGismu.erase(gismu);
   }
   gismu[4] = letter;
   for (int i=0; i<4; i++) {
    letter = gismu[i];
    for (const char* c = blockingLetters[letter-'a']; *c != '\0'; c++) {
     gismu[i] = *c;
     possibleGismu.erase(gismu);
    }
    gismu[i] = letter;
   }
  }
  gfile->close();
  delete gfile;
 }

 cout << "Preliminary work finished.  Beginning scoring." << endl;

 deque< map<string,double> >::const_iterator iter;
 for (iter = checks->begin(); iter != checks->end(); iter++) {
  const map<string,double>& sourceWords = *iter;
  cout << endl << "Source words:";
  deque< pair<string,double> > wordList(sourceWords.begin(), sourceWords.end());
  sort(wordList.begin(), wordList.end(), cmpInput);
  deque< pair<string,double> >::const_iterator iter2;
  for (iter2 = wordList.begin(); iter2 != wordList.end(); iter2++) {
   cout << ' ' << iter2->first << ' ' << iter2->second;
  }
  cout << endl;
  int count = 0;
  list<gismuRank> bestGismu;
  set<string>::const_iterator giter;
  for (giter = possibleGismu.begin(); giter != possibleGismu.end(); giter++) {
   if (++count % 10000 == 0) {
    cout << "First " << count << " possible gismu scored." << endl;
   }
   const string& gismu(*giter);
   double score = 0;
   map<string,double>::const_iterator witer;
   for (witer = sourceWords.begin(); witer != sourceWords.end(); witer++) {
    string word = witer->first;
    double weight = witer->second;
    int lcs = LCS(word, gismu);
    if (lcs >= 3 || (lcs == 2 && match2(word, gismu)))
     score += weight * lcs / word.length();
   }
   if (bestGismu.empty()) {
    bestGismu.push_back(gismuRank(score, deque<string>(1, gismu)));
   } else if (score >= bestGismu.back().first) {
    list<gismuRank>::iterator spot
     = lower_bound(bestGismu.begin(), bestGismu.end(), score, cmpRank);
    if (spot->first == score) {
     spot->second.push_back(gismu);
    } else {
     bestGismu.insert(spot, gismuRank(score, deque<string>(1, gismu)));
     if (bestGismu.size() > (size_t) maxQty) bestGismu.pop_back();
    }
   }
  }
  cout << "Top score is " << bestGismu.front().first << "." << endl;
  list<gismuRank>::const_iterator bgiter;
  for (bgiter = bestGismu.begin(); bgiter != bestGismu.end(); bgiter++) {
   cout << " " << bgiter->first << " -";
   deque<string>::const_iterator diter;
   const deque<string>& loiGismu(bgiter->second);
   for (diter = loiGismu.begin(); diter != loiGismu.end(); diter++) {
    cout << " " << *diter;
   }
   cout << endl;
  }
 }
 delete checks;
 return 0;
}

ifstream* openIF(const char* program, const char* path) {
 /* My version of GCC predates the ability to return streams from functions, so
  * I have to return a pointer instead. */
 ifstream* fp = new ifstream(path);
 if (fp->is_open()) {return fp; }
 else {
  cerr << program << ": " << path << ": " << strerror(errno) << endl;
  delete fp;
  return NULL;
 }
}

deque< map<string,double> >* readInput(istream& in) {
 deque< map<string,double> >* checks = new deque< map<string,double> >;
 string line;
 while (getline(in, line)) {
  map<string,double> sourceWords;
  istringstream linestream(line);
  string word;
  while (linestream >> word) {
   double weight;
   if (linestream >> weight) {sourceWords[word] += weight; }
   /* TODO: Is there a way to force `weight`'s input to end with whitespace or
    * EOL? */
   else {
    sourceWords[word] += 1;
    if (linestream.eof()) break;
    linestream.clear();
   }
  }
  if (!sourceWords.empty()) checks->push_back(sourceWords);
 }
 return checks;
}

int LCS(const string& a, const string& b) {
 int** lengths = new int*[a.length()+1];
 for (size_t i=0; i<a.length()+1; i++) {
  lengths[i] = new int[b.length()+1];
  for (size_t j=0; j<b.length()+1; j++) lengths[i][j] = 0;
 }
 for (size_t i=0; i<a.length(); i++) {
  for (size_t j=0; j<b.length(); j++) {
   if (a[i] == b[j]) lengths[i+1][j+1] = lengths[i][j] + 1;
   else lengths[i+1][j+1] = max(lengths[i+1][j], lengths[i][j+1]);
  }
 }
 int result = lengths[a.length()][b.length()];
 for (size_t i=0; i<a.length()+1; i++) delete[] lengths[i];
 delete[] lengths;
 return result;
}

bool cmpInput(pair<string,double> a, pair<string,double> b) {
 return b.second < a.second || (b.second == a.second && a.first < b.first);
}


bool match2(const string& word, const string& gismu) {
 /* It's possible for there to be multiple two-character LCS's for a given pair
  * of strings, one of which meets the criteria in step 2b of the {gismu}
  * creation algorithm and one of which doesn't, and so the output from an LCS
  * function (unless it returns *all* LCS's) can't be used for step 2b.
  * Instead, almost all possible two-character substrings must be checked by
  * brute-force.  If you've got a better idea, I'd like to hear it. */
 for (size_t i=0; i<4; i++) {
  size_t start=0, j;
  while ((j = word.find(gismu[i], start)) != string::npos) {
   if ((j+1 < word.length() && word[j+1] == gismu[i+1])
       || (i<3 && j+2 < word.length() && word[j+2] == gismu[i+2])) {
    return true;
   } else {start = j+1; }
  }
 }
 return false;
}

bool cmpRank(const gismuRank& a, double b) {
 return b < a.first;
}
