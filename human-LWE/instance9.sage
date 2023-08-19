import fpylll

load("../framework/proba_utils.sage")
load("../framework/DBDD_predict_diag.sage")
load("../framework/DBDD_optimized.sage")
load("../framework/instance_gen.sage")

n = 256
h = 25
q = 2**20
m = 163

sig = 3
D_e = build_Gaussian_law(sig, 10*sig)
D_s = {1:h/n, 0: 1 -h/n}

while True:
	_, _, dbdd = initialize_from_LWE_instance(DBDD_optimized, n, q, m, D_e, D_s, verbosity=2)
	s = list(dbdd.u[0][m:])
	print("|s| =", sum(s))
	if sum(s) == h:
		break

dbdd.float_type="dd"
dbdd.attack(tours = 4)
