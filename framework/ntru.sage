# Code adapted from:
# https://github.com/kpatsakis/NTRU_Sage/blob/master/ntru.sage
# Under GPL 2.0 license.

class NTRUEncrypt:

	def sample(self,NN, o,mo):
	    s = [1]*o+[-1]*mo+[0]*(NN-o-mo)
	    assert(len(s) == NN)
	    shuffle(s)
	    return self.R(s)

	#reduces the coefficients of polynomial f modulo pp
	#and "fixes" them so that they belong to [-pp/2,pp/2]
	def modCoeffs(self,f,pp):
	    clist = f.list()
	    p2 = pp/2
	    for i in range(len(clist)):
	        clist[i]  =  clist[i]%pp
	        if clist[i]>p2:
	            clist[i] -= pp
	    return self.R(clist)

	def red(self, pol):
		pol = pol % (self.x^self.n -1)
		return self.modCoeffs(pol, self.q)

	def __inv_poly_mod_prime__(self,poly,p):
		k = 0;b = 1;c = 0*self.x;
		f = poly;g = self.x^self.n-1
		f = self.modCoeffs(f, p)
		res = False
		while True:
			while f(0) == 0 and not f.is_zero():
				f = f.shift(-1)
				c = c.shift(1)
				c = self.modCoeffs(c, p)
				k += 1
			if f.is_one():
				e = (-k)%self.n
				retval =  self.x^e*b 
				res = True
				break
			elif f.degree() == -1 or f.is_zero():
				break
			if f.degree()<g.degree():
				f,g = g,f
				b,c = c,b
			f = f+g
			b = b+c
			f = self.modCoeffs(f, p)
			c = self.modCoeffs(c, p)
		if res:
			retval = retval%(self.x^self.n-1)
			retval = self.modCoeffs(retval, p)
			return True, retval
		else:
			return False,0

	def __inv_poly_mod_prime_pow__(self,poly):
		res,b = self.__inv_poly_mod_prime__(poly, self.p)
		if res:
			qr = self.p
			while qr<self.q:
				qr = qr^2
				b = b*(2-poly*b)
				b = b%(self.x^self.n-1)
				b = self.modCoeffs(b, self.q)
			return True,b
		else:
			return False,0

	def gen_keys(self):
		res = False
		self.R =  ZZ['x']
		self.x = self.R.gen()
		while (res == False):
			f  =  self.sample(self.n,self.Df,self.Df-1)
			res,fInv  =  self.__inv_poly_mod_prime_pow__(f)

		g = self.sample(self.n,self.Dg,self.Dg)
		h = self.red(g*fInv)
		return ([h[i] for i in range(self.n)],([f[i] for i in range(self.n)], [g[i] for i in range(self.n)]))

	def __init__(self, n, q, Df, Dg):
		self.n = n
		self.q = q
		F = factor(q)
		if len(F) != 1:
			raise ValueError("NTRU modulus must be a prime power")
		if 2*Dg > n:
			raise ValueError("The number of ones in NTRU secret key exceeds n/2")
		if 2*Df > n:
			raise ValueError("The number of ones in NTRU secret key exceeds n/2")

		self.p, self.e = F[0]
		self.q = q
		self.Df = Df
		self.Dg = Dg

