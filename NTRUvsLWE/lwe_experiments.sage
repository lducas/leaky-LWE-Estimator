from multiprocessing import Pool
from map_drop import map_drop
from numpy.random import seed as np_seed
load("../framework/instance_gen.sage")

try:
    N_tests = int(sys.argv[1])
    threads = int(sys.argv[2])
except:
    N_tests = 5
    threads = 1


def one_experiment(id, aargs):
    set_random_seed(id)
    np_seed(seed=id)
    A, b, dbdd = initialize_from_LWE_instance(DBDD, n, q, m, D_e, D_s, verbosity=0)
    beta_pred, _ = dbdd.estimate_attack(probabilistic=True, silent=True)
    beta, _ = dbdd.attack()
    return (beta, beta_pred)


def many_experiments(N_tests):
    import datetime
    ttt = datetime.datetime.now()
    res = map_drop(N_tests, threads, one_experiment, None)
    beta_real = RR(sum([r[0] for r in res])) / N_tests
    beta_pred = RR(sum([r[1] for r in res])) / N_tests

    print("%d,\t %.3f,\t %.3f \t\t" %
          (n, beta_real, beta_pred), end=" \t")
    print("Time:", datetime.datetime.now() - ttt)
    return beta_pred


logging("Number of threads : %d" % threads, style="DATA")
logging("Number of Samples : %d" % N_tests, style="DATA")

D_e = {-1: RR(1 / 3), 0: RR(1 / 3), 1: RR(1 / 3)}
D_s = {-1: RR(1 / 3), 0: RR(1 / 3), 1: RR(1 / 3)}
q = 512

print("n,\t real,\t pred_full")
n = 15
while n < 200:
    n = next_prime(n + 2)
    m = n
    many_experiments(N_tests)
