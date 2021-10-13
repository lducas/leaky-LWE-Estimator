# A Sage Toolkit to attack and estimate the hardness of LWE with Side Information

This repository contains the artifacts associated to the article

[DDGR20] **LWE with Side Information: Attacks and Concrete Security Estimation**
by _Dana Dachman-Soled, Léo Ducas, Huijing Gong, Mélissa Rossi_
https://eprint.iacr.org/2020/292.pdf

The code is written for Sage 9.0 (Python 3 Syntax).

Contributors are:
 - Dana Dachman-Soled
 - Huijing Gong
 - Léo Ducas
 - Mélissa Rossi
 - Thibauld Feneuil

This project was supported through the European Union PROMETHEUS project (Horizon 2020 Research and Innovation Program, grant 780701).

## Organization
The library itself is to be found in the `framework` folder. 
`Sec5.2_validation` and `Sec6_applications` contain the code to reproduce our experiments.


## How to use the full-fledged version
The full-fledged implementation is called when the class of the instance is DBDD. Let us create a small LWE instance and estimate its security in bikz. The code should be run from the directories `Sec5.2_validation` or `Sec6_applications`.

> :information_source:  The class `DBDD`  is the _textbook implementation_ of DBDD described in [DDGR20]. The class `DBDD_optimized` is a _faster version_ of the class `DBDD`, combining some performance optimizations. It can be used exactly in the same way as `DBDD` for larger LWE instances.

```sage
sage: load("../framework/instance_gen.sage")
....: n = 70
....: m = n
....: q = 3301
....: D_s = build_centered_binomial_law(40)
....: D_e = D_s
....: A, b, dbdd = initialize_from_LWE_instance(DBDD, n, q, m, D_e, D_s)
....: # In such parameter range, no need to integrate q-vectors
....: beta, delta = dbdd.estimate_attack()
``` 
```text
      Build DBDD from LWE      
 n= 70   m= 70   q=3301 
       Attack Estimation      
 dim=141     δ=1.012362      β=45.40
```

Our full-fledged implementation contains an attack procedure that runs BKZ with iterating gradually the block size. It then compares the recovered secret with the actual one.

```sage
sage: secret = dbdd.attack()
```
```text
       Running the Attack      
Running BKZ-42   Success ! 
```

Here, the block size stopped at 42 while an average blocksize of 45.40 has been estimated. Let us now create four vectors v for making perfect hints. To simulate side information, we compute the hints with the function dbdd.leak(v).

```sage
sage: # Simulating perfect hints
....: v0 = vec([randint(0, 1) for i in range(m + n)])
....: v1 = vec([randint(0, 1) for i in range(m + n)])
....: v2 = vec([randint(0, 1) for i in range(m + n)])
....: v3 = vec([randint(0, 1) for i in range(m + n)]) 
....: # Computing l = <vi, s>
....: dbdd.leak(v0), dbdd.leak(v1), dbdd.leak(v2), dbdd.leak(v3)
```
```text
(27, -62, -45, -47)
```

Let us now integrate the perfect hints into our instance.

```sage
sage: # Integrate perfect hints
....: _ = dbdd.integrate_perfect_hint(v0, 27) 
....: _ = dbdd.integrate_perfect_hint(v1, -62) 
....: _ = dbdd.integrate_perfect_hint(v2, -45) 
....: _ = dbdd.integrate_perfect_hint(v3, -47)
```
```text
 integrate perfect hint   u0 + u1 + u7 + u8 + u9 + ... = 27     Worthy hint !   dim=140, δ=1.01252643, β=41.93 
 integrate perfect hint   u0 + u2 + u8 + u9 + u10 + ... = -62   Worthy hint !   dim=139, δ=1.01275412, β=38.42 
 integrate perfect hint   u0 + u1 + u3 + u4 + u7 + ... = -45    Worthy hint !   dim=138, δ=1.01293851, β=34.78 
 integrate perfect hint   u1 + u9 + u11 + u12 + u13 + ... = -47 Worthy hint !   dim=137, δ=1.01314954, β=30.91 
```

The cost of the lattice attack has decreased by around 14 bikz. Let us now create four vectors v for making modular hints. To simulate side information, we compute the hint with the function dbdd.leak(v) with different moduli. 

```sage
sage: # Simulating modular hints
....: v0 = vec([randint(0, 1) for i in range(m + n)])
....: v1 = vec([randint(0, 1) for i in range(m + n)])
....: v2 = vec([randint(0, 1) for i in range(m + n)])
....: v3 = vec([randint(0, 1) for i in range(m + n)]) 
....: # Computing l = <vi, s> mod k
....: dbdd.leak(v0)%2, dbdd.leak(v1)%3, dbdd.leak(v2)%4, dbdd.leak(v3)%5
```
```text
(1, 1, 2, 3)
```

Let us now integrate the modular hints into our instance. We assume smoothness. In other words, the lattice is sparsified but the covariance matrix and average remain the same.

```sage
sage: # Integrate modular hints
....: _ = dbdd.integrate_modular_hint(v0, 1, 2, True) 
....: _ = dbdd.integrate_modular_hint(v1, 1, 3, True) 
....: _ = dbdd.integrate_modular_hint(v2, 2, 4, True) 
....: _ = dbdd.integrate_modular_hint(v3, 3, 5, True)
```
```text
integrate modular hint   (smooth)   u2 + u3 + u4 + ... = 1 MOD 2        Worthy hint !   dim=137, δ=1.01318729, β=30.55 
integrate modular hint   (smooth)   u0 + u2 + u10 + ... = 1 MOD 3       Worthy hint !   dim=137, δ=1.01319931, β=29.98 
integrate modular hint   (smooth)   u0 + u4 + u9 + ... = 2 MOD 4        Worthy hint !   dim=137, δ=1.01327415, β=29.24 
integrate modular hint   (smooth)   u2 + u3 + u6 + ... = 3 MOD 5        Worthy hint !   dim=137, δ=1.01331577, β=28.37 
```

As modular hints contain less information than perfect ones, especially for low modulus, the cost of the lattice attack decreased by only 3 bikz. Let us do the same for approximate hints. To simulate side information, we compute the hint with the function dbdd.leak(v) and manually change the value to represent the measurement noise. 

```sage
sage: # Simulating approximate hints
....: v0 = vec([randint(0, 1) for i in range(m + n)])
....: v1 = vec([randint(0, 1) for i in range(m + n)])
....: v2 = vec([randint(0, 1) for i in range(m + n)])
....: v3 = vec([randint(0, 1) for i in range(m + n)]) 
....: # Computing l = <vi, s> + noise
....: dbdd.leak(v0) + 2, dbdd.leak(v1) + 1, dbdd.leak(v2) - 1, dbdd.leak(v3)
```
```text
(-19, -29, -16, 1)
```

Let us now integrate the approximate hints into our instance. We assume that we want to condition the new information with the prior one and not to erase the previous distribution.

```sage
sage: # Integrate approximate hints
....: var = 10
....: _ = dbdd.integrate_approx_hint(v0, -19, var, aposteriori=False) 
....: _ = dbdd.integrate_approx_hint(v1, -29, var, aposteriori=False) 
....: _ = dbdd.integrate_approx_hint(v2, -16, var, aposteriori=False) 
....: _ = dbdd.integrate_approx_hint(v3, 1, var, aposteriori=False)
```
```text
integrate approx hint   (conditionning)
      u0 + u4 + u5 + u6 + u8 + ... = -19 + χ(σ²=10.000)      Worthy hint !   dim=137, δ=1.01322376, β=29.74 
integrate approx hint   (conditionning)
     u0 + u5 + u6 + u7 + u8 + ... = -29 + χ(σ²=10.000)       Worthy hint !   dim=137, δ=1.01329667, β=28.56 
integrate approx hint   (conditionning)
     u0 + u4 + u5 + u7 + u12 + ... = -16 + χ(σ²=10.000)      Worthy hint !   dim=137, δ=1.01337366, β=27.24 
integrate approx hint   (conditionning)
     u1 + u2 + u3 + u4 + u5 + ... = 1 + χ(σ²=10.000)         Worthy hint !   dim=137, δ=1.01340026, β=25.77
```

Here, the cost of the lattice reduction attack has decreased by 3 bikz.
While all the hints have been integrated, we finally estimate the security and run the attack again.

```sage
sage: beta, delta = dbdd.estimate_attack()
....: secret = dbdd.attack()
```
```text
       Attack Estimation       
 dim=137     δ=1.013400      β=25.77  
  
       Running the Attack      
Running BKZ-27   Success ! 
```

This time, BKZ stopped at blocksize 27 while the estimation was around 26 bikz.

## How to use the lightweight version

The lightweight implementation is called when the class of the DBDD instance is `DBDD_predict`. While the heavy basis of the lattice is not stored, only its volume and dimension are stored. Let us create an LWE instance. Before estimating the cost of the lattice reduction attack in bikz, one needs to integrate the q vectors (i.e. drop some LWE samples). Then, the security is computed in bikz thanks to the volume and dimension of the lattice. 

```sage
sage: load("../framework/instance_gen.sage")
....: n = 512
....: m = n
....: q = 2 ^ 15
....: D_e = {-2: 0.05, -1: 0.20, 0: 0.5, 1: 0.20, 2: 0.05}
....: D_s = D_e
....: A, b, dbdd = initialize_from_LWE_instance(DBDD_predict, n, q, m, D_e, D_s)
....: _ = dbdd.integrate_q_vectors(q, report_every=20)
....: beta, delta = dbdd.estimate_attack()
```
```text
      Build DBDD from LWE      
 n=512   m=512   q=32768 
       Integrating q-vectors      
 [...20]   integrate short vector hint
    Worthy hint !   dim=1024, δ=1.00518248, β=270.72
 
       Attack Estimation      
 dim=1016    δ=1.005183      β=270.69 
 ```

 We now create a new LWE instance (necessary because the q vectors should always been included at the end). And, we create 4 vectors and simulate side information. Here we only integrate perfect hints.

```sage
 sage: load("../framework/instance_gen.sage")
....: A, b, dbdd = initialize_from_LWE_instance(DBDD_predict, n, q, m, D_e, D_s)
....: # Simulating hints
....: v0 = vec([1 if i < m / 2 else 0 for i in range(m + n)])
....: v1 = vec([0 if i < m / 2 else 1 for i in range(m + n)])
....: v2 = vec([1 if i < m else 0 for i in range(m + n)])
....: v3 = vec([1 if i < m / 4 else 0 for i in range(m + n)])
....: # Computing l = <vi, s>
....: dbdd.leak(v0), dbdd.leak(v1), dbdd.leak(v2), dbdd.leak(v3)
 ```
 ```text
     Build DBDD from LWE      
 n=512   m=512   q=32768 
(33, 9, 56, 12)
 ```

 The hints must be now integrated and we assess the lattice reduction cost. Due to the shape of our vectors, new short vector hints must be integrated. 

```sage
 sage: # Integrate hints
....: _ = dbdd.integrate_perfect_hint(v0, 33) 
....: _ = dbdd.integrate_perfect_hint(v1, 9)
....: _ = dbdd.integrate_perfect_hint(v2, 56)
....: _ = dbdd.integrate_perfect_hint(v3, 12)
....: M = q * identity_matrix(n + m)
....: V = vec(M[0] - M[1])
....: i = 0
....: while dbdd.integrate_short_vector_hint(V):
....:     i += 1
....:     V = vec(M[i] - M[i + 1])
....: beta, delta = dbdd.estimate_attack()
 ```
 ```text
 integrate perfect hint   u0 + u1 + u2 + u3 + u4 + ... = 33      Worthy hint !   dim=1024, δ=1.00519338, β=269.83 
 integrate perfect hint   u256 + u257 + u258 + u259 ... = 9      Worthy hint !   dim=1023, δ=1.00520492, β=268.91 
 integrate perfect hint   u0 + u1 + u2 + u3 + u4 + ... = 56      Worthy hint !   dim=1022, δ=1.00521752, β=268.03 
 integrate perfect hint   u0 + u1 + u2 + u3 + u4 + ... = 12      Worthy hint !   dim=1021, δ=1.00522793, β=267.19 
 integrate short vector hint   32768*c0 - 32768*c1 ∈ Λ    Not sure if in Λ,       Unworthy hint, Rejected. 
       Attack Estimation      
 dim=1021    δ=1.005228      β=267.19
  ```


Here, with 4 perfect hints, the cost of the lattice reduction attack has decreased by around 3 bikz. The blocksize may be actually below 267.19 as there may be residual short vector hints.

## How to use the super lightweight version

The super lightweight implementation is called when the class of the instance is `DBDD_predict_diag`. Here, we assume that the covariance matrix is always diagonal. Let us create an LWE instance. We integrate the q vectors (i.e. drop some LWE samples) and compute the security in bikz. 

```sage
sage: load("../framework/instance_gen.sage")
....: n = 512
....: m = n
....: q = 2 ^ 15
....: D_e = {-2: 0.05, -1: 0.20, 0: 0.5, 1: 0.20, 2: 0.05}
....: D_s = D_e
....: A, b, dbdd = initialize_from_LWE_instance(DBDD_predict_diag, n, q, m, D_e, D_s)
....: _ = dbdd.integrate_q_vectors(q, report_every=20)
....: beta, delta = dbdd.estimate_attack()
```
```text
       Build DBDD from LWE      
 n=512   m=512   q=32768 
       Integrating q-vectors      
 [...20]   integrate short vector hint        Worthy hint !   dim=1024, δ=1.00518248, β=270.72 
       Attack Estimation      
 dim=1016    δ=1.005183      β=270.69
```

We create 20 canonical (necessary to keep the covariance matrix diagonal) vectors for integrating perfect hints.

```sage
sage: A, b, dbdd = initialize_from_LWE_instance(DBDD_predict_diag, n, q, m, D_e, D_s)
....: # Simulating hints
....: v = [[] for _ in range(20)]
....: for i in range(20):
....:     v[i] = canonical_vec(m + n, i)
```
```text
     Build DBDD from LWE      
 n=512   m=512   q=32768
```
The perfect hints are integrated into a new instance and the security is estimated.
```sage
sage: # Integrate hints
....: for i in range(20):
....:     _ = dbdd.integrate_perfect_hint(v[i], dbdd.leak(v[i]))
....: _ = dbdd.integrate_q_vectors(q, report_every=20)
....: beta, delta = dbdd.estimate_attack()
```
```text
integrate perfect hint   u0 = -2         Worthy hint !   dim=1024, δ=1.00519245, β=270.02 
integrate perfect hint   u1 = -1         Worthy hint !   dim=1023, δ=1.00520080, β=269.31 
integrate perfect hint   u2 = 1          Worthy hint !   dim=1022, δ=1.00520918, β=268.61 
integrate perfect hint   u3 = 0          Worthy hint !   dim=1021, δ=1.00521757, β=267.91 
integrate perfect hint   u4 = 1          Worthy hint !   dim=1020, δ=1.00522774, β=267.21 
integrate perfect hint   u5 = 1          Worthy hint !   dim=1019, δ=1.00523618, β=266.51 
integrate perfect hint   u6 = 0          Worthy hint !   dim=1018, δ=1.00524465, β=265.81 
integrate perfect hint   u7 = -2         Worthy hint !   dim=1017, δ=1.00525490, β=265.11 
integrate perfect hint   u8 = 0          Worthy hint !   dim=1016, δ=1.00526341, β=264.41 
integrate perfect hint   u9 = 0          Worthy hint !   dim=1015, δ=1.00527195, β=263.71 
integrate perfect hint   u10 = 2         Worthy hint !   dim=1014, δ=1.00528229, β=263.01 
integrate perfect hint   u11 = 0         Worthy hint !   dim=1013, δ=1.00529087, β=262.32 
integrate perfect hint   u12 = 0         Worthy hint !   dim=1012, δ=1.00529947, β=261.62 
integrate perfect hint   u13 = 2         Worthy hint !   dim=1011, δ=1.00530810, β=260.93 
integrate perfect hint   u14 = 0         Worthy hint !   dim=1010, δ=1.00531856, β=260.23 
integrate perfect hint   u15 = 2         Worthy hint !   dim=1009, δ=1.00532723, β=259.54 
integrate perfect hint   u16 = 1         Worthy hint !   dim=1008, δ=1.00533593, β=258.85 
integrate perfect hint   u17 = 0         Worthy hint !   dim=1007, δ=1.00534647, β=258.16 
integrate perfect hint   u18 = -1        Worthy hint !   dim=1006, δ=1.00535522, β=257.46 
integrate perfect hint   u19 = 1         Worthy hint !   dim=1005, δ=1.00536399, β=256.77 
       Integrating q-vectors      
 [...20]   integrate short vector hint   32768*c1023 ∈ Λ      Worthy hint !   dim=1004, δ=1.00536426, β=256.76 
 [...20]   integrate short vector hint   32768*c1003 ∈ Λ      Worthy hint !   dim=984, δ=1.00536755, β=256.54 
       Attack Estimation       
 dim=979     δ=1.005368      β=256.53  
 ```
  The integration of 20 perfect hints implies here a loss of 13 bikz.
