from fpylll import *
from fpylll.algorithms.bkz2 import BKZReduction

load("../framework/load_strategies.sage")
load("../framework/DBDD.sage")
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
            self.B = eliminate_linear_dependencies(self.B, dim=self._dim)

        # Remove linear dependencies in the dual lattice generator set
        if self.D is not None:
            if has_been_reduced and (self.D.nrows() > self._dim):
                # Display a warning because it does the calculus twice
                # Maybe there exists a method to use the previous calculation
                #   to remove dependencies in the dual basis ?
                self.logging("Double computation with LLL", priority=0, style='WARNING', newline=False)
            has_been_reduced = has_been_reduced or (self.D.nrows() > self._dim)
            self.D = eliminate_linear_dependencies(self.D, dim=self._dim)

        # And then, execute the function with bases (and not just generator sets)
        return fn(self, *args, **kwargs)
    return decorated


class DBDD_optimized(DBDD):
    """
    This class defines all the elements defining a DBDD instance with all
    the basis computations, with some performance optimizations
    """

    def __init__(self, B, S, mu, u=None, verbosity=1, homogeneous=False, float_type="ld", D=None, Bvol=None):
        assert B or D
        self._dim = (B or D).nrows() # Lattice dimension
        self.Pi = identity_matrix(self._dim) # Reduction matrix
        self.Gamma = identity_matrix(self._dim) # Substitution matrix
        super().__init__(B, S, mu, u=u, verbosity=verbosity, homogeneous=homogeneous, float_type=float_type, D=D, Bvol=None)

    def dim(self):
        return self._dim

    def S_diag(self):
        S = self.Gamma * self.S * self.Gamma.T # Restore covariance matrix
        return [S[i, i] for i in range(S.nrows())]

    @need_lattices_bases
    def volumes(self):
        return super().volumes()

    def reduce(self, V):
        """ Transform a dual vector of the original lattice
        into the corresponding dual vector of the reduced lattice
        """
        V = V * self.Gamma
        if V == 0:
            raise RejectedHint("Redundant hint")
        return V

    @need_lattices_bases
    def test_primitive_dual(self, V, action):
        V = self.reduce(V)
        return super().test_primitive_dual(self, V, action)

    @not_after_projections
    @hint_integration_wrapper(force=True, requires=["dual"],
                              invalidates=["primal"])
    def integrate_perfect_hint(self, v, l):
        V = self.homogeneize(v, l)
        V = self.reduce(V)

        # Update dual basis
        self.D = lattice_orthogonal_section(
            self.D, V,
            assume_full_rank=True,
            output_basis=False,
        )
        self._dim -= 1

        # Update search space
        VS = V * self.S
        den = scal(VS * V.T)

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
        V = self.reduce(V)

        if not smooth:
            raise NotImplementedError()

        self.D = lattice_modular_intersection(
            self.D, V, k,
            assume_full_rank=True,
            output_basis=False,
        )

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
            V = self.reduce(V)
            VS = V * self.S
            d = scal(VS * V.T)
            center = scal(self.mu * V.T)
            coeff = (- center / (variance + d))
            self.mu += coeff * VS
            self.S -= (1 / (variance + d) * VS.T) * VS
        else:
            V = concatenate(v, 0)
            V = self.reduce(V)
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
        raise NotImplementedError()

    @hint_integration_wrapper(force=False,
                              requires=["primal"],
                              invalidates=["dual"])
    def integrate_short_vector_hint(self, v):
        V = self.homogeneize(v, 0)

        if V.ncols() > self.Pi.nrows(): # Cannot use self._dim here
            V = V * self.Pi.T # Reduce the short vector if not already
        assert V.ncols() == self.Pi.nrows()

        V -= V * self.PP

        if scal((V * self.S) * V.T) == 0:
            raise InvalidHint("Projects to 0")

        self.projections += 1
        PV = identity_matrix(V.ncols()) - projection_matrix(V)
        try:
            self.B = lattice_project_against(
                self.B, V,
                assume_full_rank=True,
                output_basis=False,
            )
            self._dim -= 1
        except ValueError:
            raise InvalidHint("Not in Λ")

        self.mu = self.mu * PV
        self.u = self.u * (self.Pi.T * PV * self.Gamma.T)
        self.S = PV.T * self.S * PV
        self.PP += V.T * (V / scal(V * V.T))

    def check_solution(self, solution):
        if solution.ncols() != self.Pi.ncols():
            # Is testing a reduced solution, so restore for checking
            solution = solution * self.Gamma.T
        return super().check_solution(solution)

    @need_lattices_bases
    def attack(self, beta_max=None, beta_pre=None, randomize=False, tours=1):
        beta, solution = super().attack(
            beta_max=beta_max,
            beta_pre=beta_pre,
            randomize=randomize,
            tours=tours
        )
        if solution is not None:
            solution = solution * self.Gamma.T # Restore the secret from dimension reduction
        return beta, solution
