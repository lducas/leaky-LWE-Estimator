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


def randv():
    vv = v(randint(0, d - 1))
    vv -= v(randint(0, d - 1))
    vv += v(randint(0, d - 1))
    vv -= v(randint(0, d - 1))
    vv += v(randint(0, d - 1))
    return vv


def one_experiment(id, aargs):
    N_hints, T_hints, simul, probabilistic = aargs
    mu, variance = average_variance(Derr)
    set_random_seed(id)
    np_seed(seed=id)
    A, b, dbdd = initialize_from_LWE_instance(DBDD_predict if simul else DBDD,
                                              n, q, m, D_e, D_s, verbosity=0)

    if simul:
        beta, _ = dbdd.estimate_attack(tours=1, probabilistic=probabilistic)
        return beta
    else:
        beta, _ = dbdd.attack(tours=1)
        return beta


dic = {" ": None}


def validation_prediction(N_tests, N_hints, T_hints):
    # Estimation
    import datetime
    ttt = datetime.datetime.now()
    pred_N_test = int(ceil(threads / 2))
    res = map_drop(pred_N_test, pred_N_test, one_experiment,
                   (N_hints, T_hints, True, True))
    beta_pred_proba = RR(sum(res)) / (pred_N_test)

    res = map_drop(pred_N_test, pred_N_test, one_experiment,
                   (N_hints, T_hints, True, False))
    beta_pred_intersect = RR(sum(res)) / (pred_N_test)

    res = map_drop(N_tests, threads, one_experiment,
                   (N_hints, T_hints, False, None))
    beta_real = RR(sum(res)) / N_tests

    print("n:%3d Beta Real: %2.3f Beta predicted: %2.3f beta predicted(intersect): %2.3f "
          % (n, beta_real, beta_pred_proba, beta_pred_intersect), end=" \t")
    print("Walltime: ", datetime.datetime.now() - ttt, end=" \t")
    print("DIFF \t\t%.3f,\t%.3f,\t%.3f"
          % (beta_real, beta_pred_proba - beta_real,
             beta_pred_intersect - beta_real))
    return


logging("Number of threads : %d" % threads, style="DATA")
logging("Number of Samples : %d" % N_tests, style="DATA")
logging("     Validation tests     ", style="HEADER")

for k in range(30, 100, 2):
    n = k
    m = n
    q = 3301
    D_s = build_centered_binomial_law(40)
    D_e = build_centered_binomial_law(40)
    d = m + n
    validation_prediction(N_tests, 0, "None")  # Line 0
