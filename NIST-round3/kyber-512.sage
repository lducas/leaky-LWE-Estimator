load("../framework/instance_gen.sage")

verbosity = 2
report_every = None

# Kyber-512 round-3 parameters
n = 512
m = 512
q = 3329
D_s = build_centered_binomial_law(3)
D_e = D_s

_, _, inst = initialize_from_LWE_instance(DBDD_predict_diag, n, q,
                                          m, D_e, D_s, verbosity=verbosity)

inst.integrate_q_vectors(q)
inst.estimate_attack()
print(" Attack Estimation via simulation + probabilistic model ")

inst.estimate_attack(probabilistic=True, lift_union_bound=True, silent=False)
