from math import sqrt
from numpy import array, zeros
from numpy.random import shuffle, randint
from numpy.linalg import norm
from random import randint as srandint

# Instance 1 (binary secret) from Table 16

n = 256
q = 2**12
h = 8
m = 40
sigma = 3

def sample_sparse(w):
	S = set([])
	while len(S) < w:
		S.add(srandint(0, n-1))
	return tuple(S)

def vec_of_sparse(x):
	y = zeros(n, dtype="int32")
	for a in x:
		y[a] = 1
	return y

# create a sparse binary secret of weight h
A = randint(0, q, (m, n), dtype="int32")
s = vec_of_sparse(sample_sparse(h))


# Create an almost gaussian (binomial error) of variance sigma
e = zeros(m, dtype="int32")
for i in range(2*sigma**2):
	e += randint(0, 2, m)
	e -= randint(0, 2, m)

b = A.dot(s) + e % q

# The MITM attack
assert(h%2 == 0)

import time
start = time.time()

HashTable = dict({})

pow2 = array([2**i for i in range(m)])

def lsh(x):
	return ((x % q)  < q/2).dot(pow2)

def centered_mod(x):
	x = x % q
	x -= q*(x > q/2)
	return x

C = 0

At = A.transpose()

while True:
	C += 1
	s1 = sample_sparse(h//2)
	b1 = sum(At[s1[i]] for i in range(h//2)) % q
	HashTable[lsh(b1)] = s1

	try:
		s2 = HashTable[lsh(b - b1)]
	except:
		continue

	s_ = vec_of_sparse(s1) + vec_of_sparse(s2)
	b_ = A.dot(s_)
	if norm(centered_mod(b - b_)) < 2 * sigma * sqrt(m):
		break

end = time.time()

if not (s == s_).all():
	print("Fail")	
	print(s)
	print(s_)
	print(b - b_)
print("MITM Success after %d trials in %.2f sec"%(C, end-start))

