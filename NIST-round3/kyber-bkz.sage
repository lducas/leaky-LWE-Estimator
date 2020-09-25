load("../framework/instance_gen.sage")

verbosity = 2

# Kyber-512 round-3 parameters
print("============= Kyber-512")
n = 512
m = 512
q = 3329
D_s = build_centered_binomial_law(3)
D_e = D_s

_, _, inst = initialize_from_LWE_instance(DBDD_predict_diag, n, q,
                                          m, D_e, D_s, verbosity=verbosity)

inst.integrate_q_vectors(q, report_every=20)
print(" Attack Estimation via GSA + Interesect model ")
inst.estimate_attack()
print(" Attack Estimation via simulation + probabilistic model ")

inst.estimate_attack(probabilistic=True, lift_union_bound=True, silent=False)

# Kyber-768 round-3 parameters
print("============= Kyber-768")
n = 768
m = 768
q = 3329
D_s = build_centered_binomial_law(2)
D_e = D_s

_, _, inst = initialize_from_LWE_instance(DBDD_predict_diag, n, q,
                                          m, D_e, D_s, verbosity=verbosity)

inst.integrate_q_vectors(q, report_every=20)
inst.estimate_attack()
print(" Attack Estimation via simulation + probabilistic model ")

inst.estimate_attack(probabilistic=True, lift_union_bound=True, silent=False)


# Kyber-1024 round-3 parameters
print("============= Kyber-1024")
n = 1024
m = 1024
q = 3329
D_s = build_centered_binomial_law(2)
D_e = D_s

_, _, inst = initialize_from_LWE_instance(DBDD_predict_diag, n, q,
                                          m, D_e, D_s, verbosity=verbosity)

inst.integrate_q_vectors(q, report_every=20)
print(" Attack Estimation via GSA + Interesect model ")
inst.estimate_attack()
print(" Attack Estimation via simulation + probabilistic model ")

inst.estimate_attack(probabilistic=True, lift_union_bound=True, silent=False)
