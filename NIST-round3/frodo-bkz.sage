load("../framework/instance_gen.sage")

verbosity = 2

print("=============  FRODOKEM-640")
# NIST1 FRODOKEM-640
n = 640
m = 640+16
q = 2**15

frodo_distribution = [9288, 8720, 7216, 5264, 3384, 1918, 958, 422, 164, 56, 17, 4, 1]
D_s = get_distribution_from_table(frodo_distribution, 2 ** 16)
D_e = D_s
print(D_s)
v = sum([D_s[x]*x*x for x in D_s])
print(sqrt(v))


_, _, inst = initialize_from_LWE_instance(DBDD_predict_diag, n, q,
                                          m, D_e, D_s, verbosity=verbosity)

inst.integrate_q_vectors(q, report_every=20)
print(" Attack Estimation via GSA + Interesect model ")
inst.estimate_attack()
print(" Attack Estimation via simulation + probabilistic model ")
inst.estimate_attack(probabilistic=True, lift_union_bound=True, silent=False)


print("=============  FRODOKEM-976")
# NIST1 FRODOKEM-976
n = 976
m = 976+16
q = 2**16

frodo_distribution = [11278, 10277, 7774, 4882, 2545, 1101, 396, 118, 29, 6, 1]
D_s = get_distribution_from_table(frodo_distribution, 2 ** 16)
D_e = D_s
print(D_s)
v = sum([D_s[x]*x*x for x in D_s])
print(sqrt(v))

_, _, inst = initialize_from_LWE_instance(DBDD_predict_diag, n, q,
                                          m, D_e, D_s, verbosity=verbosity)

inst.integrate_q_vectors(q, report_every=20)
print(" Attack Estimation via GSA + Interesect model ")
inst.estimate_attack()
print(" Attack Estimation via simulation + probabilistic model ")
inst.estimate_attack(probabilistic=True, lift_union_bound=True, silent=False)

print("=============  FRODOKEM-1344")
# NIST1 FRODOKEM-1344
n = 1344
m = 1344+16
q = 2**16

frodo_distribution = [18286, 14320, 6876, 2023, 364, 40, 2]
D_s = get_distribution_from_table(frodo_distribution, 2 ** 16)
D_e = D_s
print(D_s)
v = sum([D_s[x]*x*x for x in D_s])
print(sqrt(v))

_, _, inst = initialize_from_LWE_instance(DBDD_predict_diag, n, q,
                                          m, D_e, D_s, verbosity=verbosity)

inst.integrate_q_vectors(q, report_every=20)
print(" Attack Estimation via GSA + Interesect model ")
inst.estimate_attack()
print(" Attack Estimation via simulation + probabilistic model ")
inst.estimate_attack(probabilistic=True, lift_union_bound=True, silent=False)

