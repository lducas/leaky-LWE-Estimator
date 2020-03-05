from multiprocessing import Pool
from map_drop import map_drop
from numpy.random import seed as np_seed
load("../framework/instance_gen.sage")

Derr = build_centered_binomial_law(6)
modulus = 11

try:
    N_tests = int(sys.argv[1])
    threads = int(sys.argv[2])
except:
    N_tests = 5
    threads = 1


def v(i):
    return canonical_vec(d, i)


qvec_donttouch = 20


def randv():
    vv = v(randint(qvec_donttouch, d - 1))
    vv -= v(randint(qvec_donttouch, d - 1))
    vv += v(randint(qvec_donttouch, d - 1))
    vv -= v(randint(qvec_donttouch, d - 1))
    vv += v(randint(qvec_donttouch, d - 1))
    return vv


def one_experiment(id, aargs):
    (N_hints, T_hints) = aargs
    mu, variance = average_variance(Derr)
    set_random_seed(id)
    np_seed(seed=id)
    A, b, dbdd = initialize_from_LWE_instance(DBDD, n, q,
                                              m, D_e, D_s,
                                              verbosity=0)
    A, b, dbdd_p = initialize_from_LWE_instance(DBDD_predict,
                                                n, q, m, D_e,
                                                D_s,
                                                verbosity=0)
    for j in range(N_hints):
        vv = randv()
        print(vv)
        if T_hints == "Perfect":
            dbdd.integrate_perfect_hint(vv, dbdd.leak(vv))
            dbdd_p.integrate_perfect_hint(vv, dbdd_p.leak(vv))
        if T_hints == "Approx":
            dbdd.integrate_approx_hint(vv, dbdd.leak(vv) +
                                       draw_from_distribution(Derr),
                                       variance)
            dbdd_p.integrate_approx_hint(vv, dbdd_p.leak(vv) +
                                         draw_from_distribution(Derr),
                                         variance)
        if T_hints == "Modular":
            dbdd.integrate_modular_hint(vv, dbdd.leak(vv) % modulus,
                                        modulus, smooth=True)
            dbdd_p.integrate_modular_hint(vv, dbdd_p.leak(vv) % modulus,
                                          modulus, smooth=True)

    dbdd_p.integrate_q_vectors(q, indices=range(20))
    dbdd.integrate_q_vectors(q, indices=range(20))
    beta_pred_light, _ = dbdd_p.estimate_attack(probabilistic=True)
    beta_pred_full, _ = dbdd.estimate_attack(probabilistic=True)
    beta, _ = dbdd.attack()
    return (beta, beta_pred_full, beta_pred_light)


dic = {" ": None}


def validation_prediction(N_tests, N_hints, T_hints):
    # Estimation
    import datetime
    ttt = datetime.datetime.now()
    res = map_drop(N_tests, threads, one_experiment, (N_hints, T_hints))
    beta_real = RR(sum([r[0] for r in res])) / N_tests
    beta_pred_full = RR(sum([r[1] for r in res])) / N_tests
    beta_pred_light = RR(sum([r[2] for r in res])) / N_tests

    print("%d,\t %.3f,\t %.3f,\t %.3f \t\t" %
          (N_hints, beta_real, beta_pred_full, beta_pred_light), end=" \t")
    print("Time:", datetime.datetime.now() - ttt)
    return beta_pred_full


logging("Number of threads : %d" % threads, style="DATA")
logging("Number of Samples : %d" % N_tests, style="DATA")
logging("     Validation tests     ", style="HEADER")

n = 40
m = n
q = 3301
D_s = build_centered_binomial_law(40)
D_e = build_centered_binomial_law(40)
d = m + n

print("\n \n None")

print("hints,\t real,\t pred_full, \t pred_light,")

beta_pred = validation_prediction(N_tests, 0, "None")

print("\n \n Perfect")

print("hints,\t real,\t pred_full, \t pred_light,")
for h in range(1, 100):
    beta_pred = validation_prediction(N_tests, h, "Perfect")  # Line 0
    if beta_pred < 3:
        break

print("\n \n Modular")

print("hints,\t real,\t pred_full, \t pred_light,")
for h in range(2, 200, 2):
    beta_pred = validation_prediction(N_tests, h, "Modular")  # Line 0
    if beta_pred < 3:
        break

print("\n \n Approx")

print("hints,\t real,\t pred_full, \t pred_light,")
for h in range(4, 200, 4):
    beta_pred = validation_prediction(N_tests, h, "Approx")  # Line 0
    if beta_pred < 3:
        break
