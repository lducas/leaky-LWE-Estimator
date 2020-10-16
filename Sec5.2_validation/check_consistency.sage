#!/usr/bin/sage -python
# -*- coding: latin-1 -*-

load("../framework/instance_gen.sage")


def check_all_equal(du, du_):
    assert du.dim() == du_.dim()
    assert abs(du.dvol - du_.dvol) < 1e-6
    assert abs(du.beta - du_.beta) < 1e-6
    if du.delta == oo:
        assert du_.delta == oo
    else:
        assert abs(du.delta - du_.delta) < 1e-6


def test_dbdd_ppred(n, m, q, D_e, D_s, nb_hints, hint_weight):
    A, b, dbdd = initialize_from_LWE_instance(DBDD, n, q, m,
                                              D_e, D_s,
                                              verbosity=2)
    dbdd_o = DBDD_optimized(
        copy(dbdd.B), copy(dbdd.S), copy(dbdd.mu), dbdd.u,
        D=copy(dbdd.D), verbosity=2,
    )
    dbdd_p = DBDD_predict(dbdd.B, matrix(RR, dbdd.S), dbdd.mu, dbdd.u, D=dbdd.D, verbosity=2)
    hw = hint_weight
    if hw == 1:
        dbdd_d = DBDD_predict_diag(
            dbdd.B, matrix(RR, dbdd.S), dbdd.mu, dbdd.u, D=dbdd.D, verbosity=2)
    d = n + m
    dbdd.estimate_attack()
    dbdd_o.estimate_attack()
    dbdd_p.estimate_attack()

    check_all_equal(dbdd, dbdd_o)
    check_all_equal(dbdd, dbdd_p)
    print("Ok so far.")

    for h in range(nb_hints):
        v = vec(d * [0])
        for w in range(hint_weight):
            p = randint(0, d - 1)
            v[0, p] = randint(- 1, 1) if w < hint_weight - 1 else 1
        try:
            leak = dbdd.leak(v)
            force = bool(randint(0, 1))
            if (h % 3) == 0:
                dbdd.integrate_perfect_hint(v, leak,
                                            non_primitive_action="fail",
                                            force=force,
                                            catch_invalid_hint=False)
                dbdd_o.integrate_perfect_hint(v, leak, force=force)
                dbdd_p.integrate_perfect_hint(v, leak, force=force)
                if hw == 1:
                    dbdd_d.integrate_perfect_hint(v, leak, force=force)

            elif (h % 3) == 1:
                k = randint(2, 12)
                opt = True  # bool(randint(0, 1))
                dbdd.integrate_modular_hint(v, leak % k, k,
                                            smooth=True,
                                            non_primitive_action="fail",
                                            force=force,
                                            catch_invalid_hint=False)
                dbdd_o.integrate_modular_hint(v, leak % k, k,
                                              smooth=True,
                                              force=force)
                dbdd_p.integrate_modular_hint(v, leak % k, k,
                                              smooth=True,
                                              force=force)
                if hw == 1:
                    dbdd_d.integrate_modular_hint(v, leak % k, k,
                                                  smooth=True,
                                                  force=force)

            else:
                sigma = randint(1, 10) / 10
                apost = bool(randint(0, 1))
                dbdd.integrate_approx_hint(v, leak, sigma,
                                           aposteriori=apost,
                                           force=force,
                                           catch_invalid_hint=False)
                dbdd_o.integrate_approx_hint(v, leak, sigma,
                                             aposteriori=apost,
                                             force=force)
                dbdd_p.integrate_approx_hint(v, leak, sigma,
                                             aposteriori=apost,
                                             force=force)
                if hw == 1:
                    dbdd_d.integrate_approx_hint(v, leak, sigma,
                                                 aposteriori=apost,
                                                 force=force)
        except InvalidHint as e:
            logging(str(e) + " Skipping both real and predict. \n",
                    style="REJECT")
            pass

        dbdd.estimate_attack(silent=True)
        dbdd_o.estimate_attack(silent=True)
        dbdd_p.estimate_attack(silent=True)
        if hw == 1:
            dbdd_d.estimate_attack(silent=True)

        check_all_equal(dbdd, dbdd_o)
        check_all_equal(dbdd, dbdd_p)
        if hw == 1:
            check_all_equal(dbdd, dbdd_d)

    dbdd.integrate_q_vectors(q)
    dbdd_o.integrate_q_vectors(q)
    dbdd_p.integrate_q_vectors(q)
    check_all_equal(dbdd, dbdd_o)
    check_all_equal(dbdd, dbdd_p)

    if hw == 1:
        dbdd_d.integrate_q_vectors(q)
        check_all_equal(dbdd, dbdd_d)

    dbdd.estimate_attack()
    dbdd_o.estimate_attack()
    dbdd_p.estimate_attack()
    if hw == 1:
        dbdd_d.estimate_attack()
    _, solution = dbdd.attack()
    _, solution_o = dbdd_o.attack()
    assert (solution is not None) and (solution_o is not None)
    logging("Passed that batch of tests !", style="SUCCESS")


def test_dbdd_optimized(n, m, q, D_e, D_s, nb_hints, hint_weight):
    A, b, dbdd = initialize_from_LWE_instance(DBDD, n, q, m,
                                              D_e, D_s,
                                              verbosity=2)
    dbdd_o = DBDD_optimized(
        copy(dbdd.B), copy(dbdd.S), copy(dbdd.mu), dbdd.u,
        D=copy(dbdd.D), verbosity=2,
    )
    d = n + m
    dbdd.estimate_attack()
    dbdd_o.estimate_attack()
    check_all_equal(dbdd, dbdd_o)
    print("Ok so far.")

    from time import time as get_time
    get_duration = lambda t: (get_time() - t)
    basic_time = 0
    optimized_time = 0

    for h in range(nb_hints):
        v = vec(d * [0])
        for w in range(hint_weight):
            p = randint(0, d - 1)
            v[0, p] = randint(- 1, 1) if w < hint_weight - 1 else 1

        leak = dbdd.leak(v)
        if (h % 3) == 0:
            integrate_hint_method = "integrate_perfect_hint"
            args, kwargs = (v, leak), {"estimate": False}

        elif (h % 3) == 1:
            k = randint(2, 12)
            integrate_hint_method = "integrate_modular_hint"
            args, kwargs = (v, leak % k, k), {"smooth": True, "estimate": False}

        else:
            sigma = randint(1, 10) / 10
            apost = bool(randint(0, 1))
            integrate_hint_method = "integrate_approx_hint"
            args, kwargs = (v, leak, sigma), {"aposteriori": apost, "estimate": False}

        # Integrate the hint for the DBDD object
        time_point = get_time()
        getattr(dbdd, integrate_hint_method)(*args, **kwargs)
        basic_time += get_duration(time_point)

        # Integrate the hint for the DBDD_optimized object
        time_point = get_time()
        getattr(dbdd_o, integrate_hint_method)(*args, **kwargs)
        optimized_time += get_duration(time_point)

    # Integrate the q-vectors for the DBDD object
    time_point = get_time()
    dbdd.integrate_q_vectors(q)
    dbdd.estimate_attack()
    basic_time += get_duration(time_point)

    # Integrate the q-vectors for the DBDD_optimized object
    time_point = get_time()
    dbdd_o.integrate_q_vectors(q)
    dbdd_o.estimate_attack()
    optimized_time += get_duration(time_point)

    check_all_equal(dbdd, dbdd_o)

    _, solution = dbdd.attack()
    _, solution_o = dbdd_o.attack()
    assert (solution is not None) and (solution_o is not None)

    logging("DBDD execution: %.2f s" % basic_time, style="DATA")
    logging("DBDD_optimized execution: %.2f s" % optimized_time, style="DATA")
    logging("Passed that batch of tests !", style="SUCCESS")


def random_PSD(d, variance, repeat=5, diag=False):
    S = matrix(d * [d * [0]])
    noise = vec(d * [0])
    for x in range(repeat * d):
        if not diag:
            V = vec([randint(- 10, 10) + randint(- 10, 10) for i in range(d)])
        else:
            V = vec(d * [0])
            V[0, randint(0, d - 1)] = 1

        f = (variance / (repeat * scal(V * V.T)))
        S += f * V.T * V
        noise += round_to_rational(gauss(0, sqrt(f))) * V
    return S, noise


def test_dbdd_ppred_fulldimapprox(n, m, q, D_e, D_s, nb_hints, diag=False):
    A, b, dbdd = initialize_from_LWE_instance(DBDD,
                                              n, q,
                                              m, D_e,
                                              D_s,
                                              verbosity=2)
    dbdd_p = DBDD_predict(dbdd.B, matrix(RR, dbdd.S), dbdd.u, verbosity=2)
    if diag:
        dbdd_d = DBDD_predict_diag(dbdd.B, matrix(RR, dbdd.S),
                                   dbdd.u, verbosity=2)
    d = n + m
    dbdd.estimate_attack()
    dbdd_p.estimate_attack()
    check_all_equal(dbdd, dbdd_p)

    if diag:
        dbdd_d.estimate_attack()
        check_all_equal(dbdd, dbdd_d)

    for h in range(nb_hints):
        S, noise = random_PSD(d, 10, repeat=10, diag=diag)
        dbdd.integrate_approx_hint_fulldim(dbdd.u[:, :-1] + noise, S)
        dbdd_p.integrate_approx_hint_fulldim(None, S)
        if diag:
            dbdd_d.integrate_approx_hint_fulldim(None, S)

        dbdd.estimate_attack()
        dbdd_p.estimate_attack()
        check_all_equal(dbdd, dbdd_p)

        if diag:
            dbdd_d.estimate_attack()
            check_all_equal(dbdd, dbdd_d)
    dbdd.attack()
    logging("Passed that batch of tests !", style="SUCCESS")


"""
Starting the tests
"""

n = 8
m = 16
q = 90  # 2 ** 13
D_s = build_centered_binomial_law(4)
D_e = build_centered_binomial_law(4)

test_dbdd_ppred_fulldimapprox(n, m, q, D_e, D_s, 3, diag=True)
test_dbdd_ppred_fulldimapprox(n, m, q, D_e, D_s, 3)


n = 8
m = 16
q = 90  # 2 ** 13
D_s = build_centered_binomial_law(3)
D_e = build_centered_binomial_law(5)

test_dbdd_ppred_fulldimapprox(n, m, q, D_e, D_s, 3, diag=True)
test_dbdd_ppred_fulldimapprox(n, m, q, D_e, D_s, 3)


n = 30
m = 45
q = 90  # 2 ** 13
D_s = build_centered_binomial_law(4)
D_e = build_centered_binomial_law(4)


test_dbdd_ppred(n, m, q, D_e, D_s, 40, 1)
test_dbdd_ppred(n, m, q, D_e, D_s, 40, 2)
test_dbdd_ppred(n, m, q, D_e, D_s, 40, 3)

D_s = build_centered_binomial_law(3)
D_e = build_centered_binomial_law(5)

test_dbdd_ppred(n, m, q, D_e, D_s, 40, 1)
test_dbdd_ppred(n, m, q, D_e, D_s, 40, 2)
test_dbdd_ppred(n, m, q, D_e, D_s, 40, 3)


n = 30
m = 45
q = 90  # 2 ** 13
D_s = build_centered_binomial_law(4)
D_e = build_centered_binomial_law(4)

test_dbdd_optimized(n, m, q, D_e, D_s, 40, 1)
test_dbdd_optimized(n, m, q, D_e, D_s, 40, 2)
test_dbdd_optimized(n, m, q, D_e, D_s, 40, 3)


logging("All test pass !", style="SUCCESS")
