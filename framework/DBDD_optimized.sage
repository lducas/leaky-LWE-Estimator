from fpylll import *
from fpylll.algorithms.bkz2 import BKZReduction

load("../framework/load_strategies.sage")
load("../framework/DBDD_generic.sage")
load("../framework/proba_utils.sage")

def need_lattices_bases(fn):
    """
    Decorator which removes linear dependencies in lattice generator sets
    of the DBDD instance to manipulate bases in the execution of the
    decorated method
    """
    def decorated(self, *args, **kwargs):
        has_been_reduced = False

        # Remove linear dependencies in the primal lattice generator set
        if self.B is not None:
            has_been_reduced = has_been_reduced or (self.B.nrows() > self._dim)
            self.B = remove_linear_dependencies(self.B, self._dim)

        # Remove linear dependencies in the dual lattice generator set
        if self.D is not None:
            if has_been_reduced and (self.D.nrows() > self._dim):
                # Display a warning because it does the calculus twice
                # Maybe there exists a method to use the previous calculation
                #   to remove dependencies in the dual basis ?
                self.logging("Double computation with LLL", priority=0, style='WARNING', newline=False)
            has_been_reduced = has_been_reduced or (self.D.nrows() > self._dim)
            self.D = remove_linear_dependencies(self.D, self._dim)

        # And then, execute the function with bases (and not just generator sets)
        return fn(self, *args, **kwargs)
    return decorated


class DBDD_optimized(DBDD_generic):
    """
    This class defines all the elements defining a DBDD instance with all
    the basis computations
    """

    def __init__(self, B, S, mu, u=None, verbosity=1, homogeneous=False, float_type="ld", **kwargs):
        """constructor that builds a DBDD instance from a lattice, mean, sigma
        and a target
        ;min_dim: Number of coordinates to find to consider the problem solved
        :B: Basis of the lattice
        :S: The Covariance matrix (Sigma) of the uSVP solution
        :mu: The expectation of the uSVP solution
        :u: The unique vector to be found (optinal, for verification purposes)
        :fp_type: Floating point type to use in FPLLL ("d, ld, dd, qd")
        """
        self.verbosity = verbosity
        self.B = B                     # The lattice Basis
        self.D = kwargs.get('D', None) # The dual Basis (only B or D is active)
        assert (self.D is None) or (self.D.T * self.B == identity_matrix(B.nrows()))
        self._dim = B.nrows()
        self.S = S
        self.PP = 0 * S  # Span of the projections so far (orthonormal)
        self.mu = mu
        self.homogeneous = homogeneous
        if homogeneous and scal(mu * mu.T) > 0:
            raise InvalidArgument("Homogeneous instances must have mu=0")
        self.u = u
        self.u_original = u
        self.expected_length = RR(sqrt(self.S.trace()) + 1)
        self.projections = 0
        self.Pi = identity_matrix(self._dim) # Reduction matrix
        self.Gamma = identity_matrix(self._dim) # Substitution matrix
        self.save = {"save": None}
        self.float_type = float_type
        self.estimate_attack(silent=True)

    def dim(self):
        return self._dim

    def S_diag(self):
        return [self.S[i, i] for i in range(self.S.nrows())]

    @need_lattices_bases
    def volumes(self):
        if self.B is not None:
            Bvol = logdet(self.B * self.B.T) / 2
        else:
            Bvol = -logdet(self.D * self.D.T) / 2

        S = self.S + self.mu.T * self.mu
        Svol = degen_logdet(S)
        dvol = Bvol - Svol / 2.
        return (Bvol, Svol, dvol)

    @need_lattices_bases
    def test_primitive_dual(self, V, action):
        if self.B is None:
            self.B = dual_basis(self.D)

        W = V * self.B.T
        den = lcm([x.denominator() for x in W[0]])
        num = gcd([x for x in W[0] * den])
        assert den == 1

        if num == 1:
            return True
        if action == "warn":
            logging("non-primitive (factor %d)." %
                    num, style="WARNING", newline=False)
            return True
        elif action == "reject":
            raise RejectedHint("non-primitive (factor %d)." % num)

        raise InvalidHint("non-primitive (factor %d)." % num)

    def get_reduced_hint_vector(self, V):
        V = V * self.Gamma
        if V == 0:
            raise RejectedHint("Redundant hint")
        return V

    @not_after_projections
    @hint_integration_wrapper(force=True, requires=["dual"],
                              invalidates=["primal"])
    def integrate_perfect_hint(self, v, l):
        V = self.homogeneize(v, l)
        V = self.get_reduced_hint_vector(V)

        VS = V * self.S
        den = scal(VS * V.T)

        self.D = lattice_orthogonal_section(self.D, V)
        self._dim -= 1

        num = self.mu * V.T
        self.mu -= (num / den) * VS
        num = VS.T * VS
        self.S -= num / den

        # Realize the dimension reduction
        Gamma, (_, pseudo_inv) = build_substitution_matrix(V)
        normalized_Gamma = Gamma*pseudo_inv

        self.D = self.D * Gamma
        self.mu = self.mu * normalized_Gamma
        self.S = normalized_Gamma.T * self.S * normalized_Gamma
        self.PP = 0 * self.S

        self.Pi = normalized_Gamma.T * self.Pi
        self.Gamma *= Gamma

    @not_after_projections
    @hint_integration_wrapper(force=True, requires=["dual"], invalidates=["primal"])
    def integrate_modular_hint(self, v, l, k, smooth=True):
        V = self.homogeneize(v, l)
        V = self.get_reduced_hint_vector(V)

        if not smooth:
            raise NotImplementedError()

        self.D = lattice_modular_intersection(self.D, V, k)

    @not_after_projections
    @hint_integration_wrapper(force=True)
    def integrate_approx_hint(self, v, l, variance, aposteriori=False):
        if variance < 0:
            raise InvalidHint("variance must be non-negative !")
        if variance == 0:
            raise InvalidHint("variance=0 : must use perfect hint !")
        # Only to check homogeneity if necessary
        self.homogeneize(v, l)

        if not aposteriori:
            V = self.homogeneize(v, l)
            V = self.get_reduced_hint_vector(V)
            VS = V * self.S
            d = scal(VS * V.T)
            center = scal(self.mu * V.T)
            coeff = (- center / (variance + d))
            self.mu += coeff * VS
            self.S -= (1 / (variance + d) * VS.T) * VS
        else:
            V = concatenate(v, 0)
            V = self.get_reduced_hint_vector(V)
            VS = V * self.S
            if not scal(VS * VS.T):
                raise RejectedHint("0-Eigenvector of Σ forbidden,")

            den = scal(VS * V.T)
            self.mu += ((l - scal(self.mu * V.T)) / den) * VS
            self.S += (((variance - den) / den**2) * VS.T ) * VS

    @not_after_projections
    @hint_integration_wrapper()
    def integrate_approx_hint_fulldim(self, center,
                                      covariance, aposteriori=False):
        # Using http://www.cs.columbia.edu/~liulp/pdf/linear_normal_dist.pdf
        # with A = Id
        if self.homogeneous:
            raise NotImplementedError()

        if not aposteriori:
            d = self.S.nrows() - 1
            if self.S.rank() != d or covariance.rank() != d:
                raise InvalidHint("Covariances not full dimensional")

            zero = vec(d * [0])
            F = (self.S + block4(covariance, zero.T, zero, vec([1]))).inverse()
            F[-1, -1] = 0
            C = concatenate(center, 1)

            self.mu += ((C - self.mu) * F) * self.S
            self.S -= self.S * F * self.S
        else:
            raise NotImplementedError()

    @hint_integration_wrapper(force=False,
                              requires=["primal"],
                              invalidates=["dual"])
    def integrate_short_vector_hint(self, v):
        V = self.homogeneize(v, 0)

        if V.dimensions()[1] > self.Pi.nrows(): # Cannot use self._dim here
            V = V * self.Pi.T # Reduce the short vector if not already
        assert V.dimensions()[1] == self.Pi.nrows()

        V -= V * self.PP

        if scal((V * self.S) * V.T) == 0:
            raise InvalidHint("Projects to 0")

        self.projections += 1
        PV = identity_matrix(V.ncols()) - projection_matrix(V)
        try:
            self.B = lattice_project_against(self.B, V)
            self._dim -= 1
        except ValueError:
            raise InvalidHint("Not in Λ")

        self.mu = self.mu * PV
        self.u = self.u * (self.Pi.T * PV * self.Gamma.T)
        self.S = PV.T * self.S * PV
        self.PP += V.T * (V / scal(V * V.T))

    @need_lattices_bases
    def attack(self, beta_max=None, beta_pre=None, randomize=False, tours=1):
        """
        Run the lattice reduction to solve the DBDD instance.
        Return the (blocksize, solution) of a succesful attack,
        or (None, None) on failure
        """
        self.logging("      Running the Attack     ", style="HEADER")

        if self.B is None:
            self.B = dual_basis(self.D)

        # Apply adequate distortion
        denom = lcm([x.denominator() for x in self.B.list()])
        B = self.B
        d = B.nrows()
        S = self.S + self.mu.T * self.mu
        L, Linv = square_root_inverse_degen(S, self.B)
        M = B * Linv

        # Make the matrix Integral
        denom = lcm([x.denominator() for x in M.list()])
        M = matrix(ZZ, M * denom)

        # Build the BKZ object
        G = GSO.Mat(IntegerMatrix.from_matrix(M), float_type=self.float_type)
        bkz = BKZReduction(G)
        if randomize:
            bkz.lll_obj()
            bkz.randomize_block(0, d, density=d / 4)
            bkz.lll_obj()

        u_den = lcm([x.denominator() for x in self.u.list()])

        if beta_pre is not None:
            self.logging("\rRunning BKZ-%d (until convergence)" %
                         beta_pre, newline=False)
            bkz.lll_obj()
            par = BKZ.Param(block_size=beta_pre, strategies=strategies)
            bkz(par)
            bkz.lll_obj()
        else:
            beta_pre = 2
        # Run BKZ tours with progressively increasing blocksizes
        for beta in range(beta_pre, B.nrows() + 1):
            self.logging("\rRunning BKZ-%d" % beta, newline=False)
            if beta_max is not None:
                if beta > beta_max:
                    self.logging("Failure ... (reached beta_max)",
                                 style="SUCCESS")
                    self.logging("")
                    return None, None

            if beta == 2:
                bkz.lll_obj()
            else:
                par = BKZ.Param(block_size=beta,
                                strategies=strategies, max_loops=tours)
                bkz(par)
                bkz.lll_obj()
            # Recover the tentative solution,
            # undo distorition, scaling, and test it
            v = vec(bkz.A[0])
            v = u_den * v * L / denom
            solution = matrix(ZZ, v.apply_map(round)) / u_den
            solution = solution * self.Gamma.T # Restore the secret from dimension reduction

            if not self.check_solution(solution):
                continue

            self.logging("Success !", style="SUCCESS")
            self.logging("")
            return beta, solution

        self.logging("Failure ...", style="FAILURE")
        self.logging("")
        return None, None
