<meta http-equiv="Content-Type" content="text/html;charset=UTF-8">

TL;DR: find $m$ and $n$ such that $a^m = b^n$ for given some $a$ and $b$ without
floating point arithmetic or factoring.

## Motivation

A base $a$ number can be converted to base $b$ by converting groups of $m$
digits to $n$ digits. For example, `FF` in hex is always `11111111` in binary.
Working by groups is much more efficient than repeatedly reducing the whole base
$a$ number mod $b$ to get the next digit.

## First solution

$a^m = b^n$ <br/>
$log(a^m) = log(b^n)$ <br/>
$m log(a) = n log(b)$ <br/>
$n/m = log_b(a)$

Problem solved? Kinda. The logarithm has to be exact, and a fraction. The real world is not that beautiful:

    python> Fraction(log(256,16))
    Fraction(2, 1) # okay
    python> Fraction(log(216,6))
    Fraction(6755399441055745, 2251799813685248) # oops


## Second solution

Factor both numbers, compare the powers of prime factors in each number. The
ratio is $n/m$ and has to be the same for each factor for there to be a solution.
It works, but is slow with large numbers and not novel in any other way.

## Final solution

If there is a solution $(m,n)$ then $a$ and be have to be powers of the same
number, i.e. there exists some $g$ such that $a = g^l$ and $b=g^r$ for some $l$
and $r$. To compute it an algorithm quite like the Euclid's can be used, there also is a [proof](http://sandra.tedx.ee/baseconvert-proof.pdf) of its correctness.

    int compute_g(int a, int b) {
    	// Finds gratest g such that a = g^l and b=g^r for some l and r.
    	// returns 0 if it does not exist.
    	if (a < 2 || b < 2) return 0;
    	int r;
    	while (1) {
    		if (b > a) {
    			r = a;
    			a = b;
    			b = r;
    		}
    		r = a%b;
    		a /= b;
    		if (r) return 0;
    		else if (a == 1) return b;
    	}
    }

Now to find $m$ and $n$ one has to take integer logarithms base $g$ of a and
$b$. A possible implementation follows.

    #include <stdio.h>
    #include <stdbool.h>
    #include <stdlib.h>
    #include <limits.h>
    #include <assert.h>
    
    #ifdef __GNUC__
    	#define clz __builtin_clz
    #endif


    int ipow(int a, int b) { // a^b in O(bits(int)). Square and multiply.
    	int ret = 1;
    	while (b > 0) {
    		if (b & 1) ret *= a;
    		a *= a;
    		b >>= 1;
    	}
    	return ret;
    }
    
    int ilog(int a, int b) { // ceil(log_b(a)) in O(bits(int)^2).
    	assert( a > 0 && b > 1);
    	if (a == 1) return 0;
    	if (a <= b) return 1;
    	#define bits(x) (8*sizeof(x))
    	int l2a = bits(int) - clz(a);
    	int l2b = bits(int) - clz(b);
    	#undef bits
    	int right = (l2a-1)/(l2b-1)+1;
    	int left = l2a/l2b-1;
    	while (left < right) {
    		int mid = left + (right - left) / 2;
    		if (ipow(b,mid) < a) left = mid + 1;
    		else right = mid;
    	}
    	return left;
    }
    
    int main() {
    	int a, b,g;
    	for (a = 2; a <= 256; a++) for (b = 2; b < a; b++) {
    		g = magic(a,b);
    		if (g > 0) printf("%d^%d == %d^%d\n",a,ilog(b,g),b,ilog(a,g));
    	}
    	return;
    }


## Use for base conversion

When working with a limited number of bases, it is wise to just precalculate and
look up the solutions. For $a,b \in [2,256]$:

    4^1 == 2^2
    8^1 == 2^3
    8^2 == 4^3
    9^1 == 3^2
    16^1 == 2^4
    16^1 == 4^2
    16^3 == 8^4
    25^1 == 5^2
    27^1 == 3^3
    27^2 == 9^3
    32^1 == 2^5
    32^2 == 4^5
    32^3 == 8^5
    32^4 == 16^5
    36^1 == 6^2
    49^1 == 7^2
    64^1 == 2^6
    64^1 == 4^3
    64^1 == 8^2
    64^2 == 16^3
    64^5 == 32^6
    81^1 == 3^4
    81^1 == 9^2
    81^3 == 27^4
    100^1 == 10^2
    121^1 == 11^2
    125^1 == 5^3
    125^2 == 25^3
    128^1 == 2^7
    128^2 == 4^7
    128^3 == 8^7
    128^4 == 16^7
    128^5 == 32^7
    128^6 == 64^7
    144^1 == 12^2
    169^1 == 13^2
    196^1 == 14^2
    216^1 == 6^3
    216^2 == 36^3
    225^1 == 15^2
    243^1 == 3^5
    243^2 == 9^5
    243^3 == 27^5
    243^4 == 81^5
    256^1 == 2^8
    256^1 == 4^4
    256^3 == 8^8
    256^1 == 16^2
    256^5 == 32^8
    256^3 == 64^4
    256^7 == 128^8
