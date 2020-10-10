from random import shuffle, randint

load("../framework/proba_utils.sage")
load("../framework/DBDD_predict_diag.sage")
load("../framework/DBDD_predict.sage")
load("../framework/DBDD.sage")
load("../framework/DBDD_optimized.sage")


def initialize_from_LWE_instance(dbdd_class, n, q, m, D_e,
                                 D_s, diag=False, verbosity=1):
    """
    constructor that builds a DBDD instance from a LWE instance
    :n: (integer) size of the secret s
    :q: (integer) modulus
    :m: (integer) size of the error e
    :D_e: distribution of the error e (dictionnary form)
    :D_s: distribution of the secret s (dictionnary form)
    """
    if verbosity:
        logging("     Build DBDD from LWE     ", style="HEADER")
        logging("n=%3d \t m=%3d \t q=%d" % (n, m, q), style="VALUE")
    # define the mean and sigma of the instance
    mu_e, s_e = average_variance(D_e)
    mu_s, s_s = average_variance(D_s)
    mu = vec(m * [mu_e] + n * [mu_s] + [1])
    S = diagonal_matrix(m * [s_e] + n * [s_s] + [0])
    # draw matrix A and define the lattice
    A = matrix([[randint(0, q) for _ in range(n)] for _ in range(m)])
    B = build_LWE_lattice(-A, q) # primal
    D = build_LWE_lattice(A/q, 1/q) # dual
    # draw the secrets
    s = vec([draw_from_distribution(D_s) for _ in range(n)])
    e = vec([draw_from_distribution(D_e) for _ in range(m)])
    # compute the public value t and build a target
    b = (s * A.T + e) % q
    tar = concatenate([b, [0] * n])
    B = kannan_embedding(B, tar)
    D = kannan_embedding(D, concatenate([-b/q, [0] * n])).T
    u = concatenate([e, s, [1]])
    return A, b, dbdd_class(B, S, mu, u, verbosity=verbosity, D=D, Bvol=m*log(q))


def initialize_from_LWR_instance(dbdd_class, n, q, p, m, D_s, verbosity=1):
    if verbosity:
        logging("     Build DBDD from LWR     ", style="HEADER")
        logging("n=%3d \t m=%3d \t q=%d \t p=%d" % (n, m, q, p), style="VALUE")
    D_e = build_mod_switching_error_law(q, p)
    # draw matrix A and define the lattice
    A = matrix([[randint(0, q) for _ in range(n)] for _ in range(m)])
    s = vec([draw_from_distribution(D_s) for _ in range(n)])
    B = build_LWE_lattice(-A, q)
    b = q / p * ((p / q) * s * A.T).apply_map(lambda x: x.round(mode='down'))
    e = b - s * A.T
    tar = concatenate([b, [0] * n])
    B = kannan_embedding(B, tar)
    u = concatenate([e, s, [1]])
    # define the mean and sigma of the instance
    mu_e, s_e = average_variance(D_e)
    mu_s, s_s = average_variance(D_s)
    mu = vec(m * [mu_e] + n * [mu_s] + [1])
    S = diagonal_matrix(m * [s_e] + n * [s_s] + [0])
    return A, b, dbdd_class(B, S, mu, u, verbosity=verbosity)


def initialize_round5_instance(dbdd_class, n, q, p, h, m, D_e,
                               D_s, verbosity=1):
    if verbosity:
        logging("     Build DBDD from round5     ", style="HEADER")
        logging("n=%3d \t m=%3d \t q=%d \t p=%d" % (n, m, q, p), style="VALUE")
    # draw matrix A and define the lattice
    assert (h % 2 == 0), "Round5 requires 2 to divide h"
    A = matrix([[randint(0, q) for _ in range(n)] for _ in range(m)])
    s = h / 2 * [1] + h / 2 * [-1] + (n - h) * [0]
    shuffle(s)
    s = vec(s)
    B = build_LWE_lattice(-A, q)
    b = vec([q / p * (round((p / q) * ((s * A.T)[0][i] % q)) % p)
             for i in range(n)])
    e = vec([((- s * A.T)[0][i] + b[0][i]) % q
             if ((- s * A.T)[0][i] + b[0][i]) % q < q / 2
             else ((- s * A.T)[0][i] + b[0][i]) % q - q
             for i in range(n)])
    tar = concatenate([b, [0] * n])
    B = kannan_embedding(B, tar)
    u = concatenate([e, s, [1]])
    # define the mean and sigma of the instance
    mu_e, s_e = average_variance(D_e)
    mu_s, s_s = average_variance(D_s)
    mu = vec(m * [mu_e] + n * [mu_s] + [1])
    S = diagonal_matrix(m * [s_e] + n * [s_s] + [0])
    return A, b, dbdd_class(B, S, mu, u, verbosity=verbosity)


def initialize_LAC_instance(dbdd_class, n, q, m, D_e, D_s, verbosity=1):
    if verbosity:
        logging("     Build DBDD for LAC     ", style="HEADER")
        logging("n=%3d \t m=%3d \t q=%d" % (n, m, q), style="VALUE")
    # draw matrix A and define the lattice
    A = matrix([[randint(0, q) for _ in range(n)] for _ in range(m)])
    B = build_LWE_lattice(-A, q)
    assert (n % 4 == 0) and (m % 4 == 0), "LAC requires 4 to divide n and m"
    s = (n / 4) * [0, 1, 0, -1]
    shuffle(s)
    s = vec(s)
    e = (m / 4) * [0, 1, 0, -1]
    shuffle(e)
    e = vec(e)
    b = (s * A.T + e) % q
    tar = concatenate([b, [0] * n])
    B = kannan_embedding(B, tar)
    u = concatenate([e, s, [1]])
    # define the mean and sigma of the instance
    mu_e, s_e = average_variance(D_e)
    mu_s, s_s = average_variance(D_s)
    mu = vec(m * [mu_e] + n * [mu_s] + [1])
    S = diagonal_matrix(m * [s_e] + n * [s_s] + [0])
    return A, b, dbdd_class(B, S, mu, u, verbosity=verbosity)


def initialize_NTRU_instance(dbdd_class, n, q, D_f, D_g, verbosity=1):
    if verbosity:
        logging("     Build DBDD for NTRU HPS VERSION     ", style="HEADER")
        logging("n=%3d \t \t q=%d" % (n, q), style="VALUE")

    assert (q % 16 == 0), "NTRU-HPS requires 16 to divide q"

    # This construction of the lattice is not correct for NTRU
    # It doesn't matter when we are only doing prediction though
    if dbdd_class==DBDD:
        raise NotImplementedError("NTRU KeyGen not actually implemented.")

    B = diagonal_matrix(n * [q] + n * [1])
    mu_f, s_f = average_variance(D_f)
    mu_g, s_g = average_variance(D_g)
    mu = vec(n * [mu_f] + n * [mu_g])
    S = diagonal_matrix(n * [s_f] + n * [s_g])
    return None, None, dbdd_class(B, S, mu, None, homogeneous=True, verbosity=verbosity)
