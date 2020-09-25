load("../framework/instance_gen.sage")

verbosity = 2

# Dilithium-I round-3 parameters
print("============= Dilithium-I")
n = 4*256
m = 4*256
q = 8380417
eta = 2
D_s = {x : 1./(2*eta+1) for x in range(-eta, eta+1)}
D_e = D_s

_, _, inst = initialize_from_LWE_instance(DBDD_predict_diag, n, q,
                                          m, D_e, D_s, verbosity=verbosity)

inst.integrate_q_vectors(q, report_every=20)
print(" Attack Estimation via GSA + Interesect model ")
inst.estimate_attack()
print(" Attack Estimation via simulation + probabilistic model ")
inst.estimate_attack(probabilistic=True, lift_union_bound=True, silent=False)

print("============= Dilithium-II")

# Dilithium-II round-3 parameters
n = 5*256
m = 6*256
q = 8380417
eta = 4
D_s = {x : 1./(2*eta+1) for x in range(-eta, eta+1)}
D_e = D_s

_, _, inst = initialize_from_LWE_instance(DBDD_predict_diag, n, q,
                                          m, D_e, D_s, verbosity=verbosity)

inst.integrate_q_vectors(q, report_every=20)
print(" Attack Estimation via GSA + Interesect model ")
inst.estimate_attack()
print(" Attack Estimation via simulation + probabilistic model ")

inst.estimate_attack(probabilistic=True, lift_union_bound=True, silent=False)

print("============= Dilithium-III")

# Dilithium-II round-3 parameters
n = 7*256
m = 8*256
q = 8380417
eta = 2
D_s = {x : 1./(2*eta+1) for x in range(-eta, eta+1)}
D_e = D_s

_, _, inst = initialize_from_LWE_instance(DBDD_predict_diag, n, q,
                                          m, D_e, D_s, verbosity=verbosity)

inst.integrate_q_vectors(q, report_every=20)
print(" Attack Estimation via GSA + Interesect model ")
inst.estimate_attack()
print(" Attack Estimation via simulation + probabilistic model ")
inst.estimate_attack(probabilistic=True, lift_union_bound=True, silent=False)
