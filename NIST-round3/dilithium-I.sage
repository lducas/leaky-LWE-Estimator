load("../framework/instance_gen.sage")

verbosity = 2
report_every = None

# Dilithium-I round-3 parameters
n = 4*256
m = 4*256
q = 8380417
eta = 2
D_s = {x : 1./(2*eta+1) for x in range(-eta, eta+1)}
D_e = D_s

_, _, inst = initialize_from_LWE_instance(DBDD_predict_diag, n, q,
                                          m, D_e, D_s, verbosity=verbosity)

inst.integrate_q_vectors(q)
inst.estimate_attack()
print(" Attack Estimation via simulation + probabilistic model ")

inst.estimate_attack(probabilistic=True, lift_union_bound=True, silent=False)
