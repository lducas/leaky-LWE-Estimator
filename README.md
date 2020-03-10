# A Sage Toolkit to attack and estimate the hardness of LWE with Side Information

This repository contains the artifacts associated to the article

[DDGR20] **LWE with Side Information: Attacks and Concrete Security Estimation**
by _Dana Dachman-Soled, Léo Ducas, Huijing Gong, Mélissa Rossi_
https://eprint.iacr.org/2020/292.pdf

The code is written for Sage 9.0 (Python 3 Syntax).

## Organization
The library itself is to be dound in the `framework` folder. 
`Sec5.2_validation` and `Sec6_applications` contain the code to reproduce our experiments.


## How to use the full-fledged version
The full-fledged implementation is called when the class of the instance is DBDD. Let us create a small LWE instance and estimate its security in bikz. The code should be run from the directories `Sec5.2_validation` or `Sec6_applications`.
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

```python
sage: t = cputime()
....: secret = dbdd.attack()
....: str(cputime(t)) + "CPU Seconds for the attack"

       Running the Attack      
Running BKZ-42   Success ! 
  
120.73061799999999 CPU Seconds for the attack
```

Here, the block size stopped at 42 while an average blocksize of 45.40 has been estimated. Let us now create four vectors v for making perfect hints. To simulate side information, we compute the hints with the function dbdd.leak(v).

```python
sage: # Simulating perfect hints
....: v0 = vec([randint(0, 1) for i in range(m + n)])
....: v1 = vec([randint(0, 1) for i in range(m + n)])
....: v2 = vec([randint(0, 1) for i in range(m + n)])
....: v3 = vec([randint(0, 1) for i in range(m + n)]) 
....: # Computing l = <vi, s>
....: dbdd.leak(v0), dbdd.leak(v1), dbdd.leak(v2), dbdd.leak(v3)

(27, -62, -45, -47)
```

Let us now integrate the perfect hints into our instance.

```python
sage: # Integrate perfect hints
....: _ = dbdd.integrate_perfect_hint(v0, 27) 
....: _ = dbdd.integrate_perfect_hint(v1, -62) 
....: _ = dbdd.integrate_perfect_hint(v2, -45) 
....: _ = dbdd.integrate_perfect_hint(v3, -47)

 integrate perfect hint   u0 + u1 + u7 + u8 + u9 + ... = 27 
 Worthy hint !   dim=140, δ=1.01252643, β=41.93 
 integrate perfect hint   u0 + u2 + u8 + u9 + u10 + ... = -62
 Worthy hint !   dim=139, δ=1.01275412, β=38.42 
 integrate perfect hint   u0 + u1 + u3 + u4 + u7 + ... = -45
 Worthy hint !   dim=138, δ=1.01293851, β=34.78 
 integrate perfect hint   u1 + u9 + u11 + u12 + u13 + ... = -47
 Worthy hint !   dim=137, δ=1.01314954, β=30.91 
```

The cost of the lattice attack has decreased by around 14 bikz. Let us now create four vectors v for making modular hints. To simulate side information, we compute the hint with the function dbdd.leak(v) with different moduli. 

```python
sage: # Simulating modular hints
....: v0 = vec([randint(0, 1) for i in range(m + n)])
....: v1 = vec([randint(0, 1) for i in range(m + n)])
....: v2 = vec([randint(0, 1) for i in range(m + n)])
....: v3 = vec([randint(0, 1) for i in range(m + n)]) 
....: # Computing l = <vi, s> mod k
....: dbdd.leak(v0)%2, dbdd.leak(v1)%3, dbdd.leak(v2)%4, dbdd.leak(v3)%5

(1, 1, 2, 3)
```

Let us now integrate the modular hints into our instance. We assume smoothness. In other words, the lattice is sparsified but the covariance matrix and average remain the same.

```python
sage: # Integrate modular hints
....: _ = dbdd.integrate_modular_hint(v0, 1, 2, True) 
....: _ = dbdd.integrate_modular_hint(v1, 1, 3, True) 
....: _ = dbdd.integrate_modular_hint(v2, 2, 4, True) 
....: _ = dbdd.integrate_modular_hint(v3, 3, 5, True)

integrate modular hint   (smooth)   u2 + u3 + u4 + ... = 1 MOD 2
        Worthy hint !   dim=137, δ=1.01318729, β=30.55 
integrate modular hint   (smooth)   u0 + u2 + u10 + ... = 1 MOD 3
        Worthy hint !   dim=137, δ=1.01319931, β=29.98 
integrate modular hint   (smooth)   u0 + u4 + u9 + ... = 2 MOD 4
        Worthy hint !   dim=137, δ=1.01327415, β=29.24 
integrate modular hint   (smooth)   u2 + u3 + u6 + ... = 3 MOD 5
        Worthy hint !   dim=137, δ=1.01331577, β=28.37 
```

As modular hints contain less information than perfect ones, especially for low modulus, the cost of the lattice attack decreased by only 3 bikz. Let us do the same for approximate hints. To simulate side information, we compute the hint with the function dbdd.leak(v) and manually change the value to represent the measurement noise. 

```python
sage: # Simulating approximate hints
....: v0 = vec([randint(0, 1) for i in range(m + n)])
....: v1 = vec([randint(0, 1) for i in range(m + n)])
....: v2 = vec([randint(0, 1) for i in range(m + n)])
....: v3 = vec([randint(0, 1) for i in range(m + n)]) 
....: # Computing l = <vi, s> + noise
....: dbdd.leak(v0) + 2, dbdd.leak(v1) + 1, dbdd.leak(v2) - 1, dbdd.leak(v3)

(-19, -29, -16, 1)
```

Let us now integrate the approximate hints into our instance. We assume that we want to condition the new information with the prior one and not to erase the previous distribution.

```python
sage: # Integrate approximate hints
....: var = 10
....: _ = dbdd.integrate_approx_hint(v0, -19, var, aposteriori=False) 
....: _ = dbdd.integrate_approx_hint(v1, -29, var, aposteriori=False) 
....: _ = dbdd.integrate_approx_hint(v2, -16, var, aposteriori=False) 
....: _ = dbdd.integrate_approx_hint(v3, 1, var, aposteriori=False)

integrate approx hint   (conditionning)
      u0 + u4 + u5 + u6 + u8 + ... = -19 + χ(σ²=10.000)
      Worthy hint !   dim=137, δ=1.01322376, β=29.74 
integrate approx hint   (conditionning)
     u0 + u5 + u6 + u7 + u8 + ... = -29 + χ(σ²=10.000)
     Worthy hint !   dim=137, δ=1.01329667, β=28.56 
integrate approx hint   (conditionning)
     u0 + u4 + u5 + u7 + u12 + ... = -16 + χ(σ²=10.000)
     Worthy hint !   dim=137, δ=1.01337366, β=27.24 
integrate approx hint   (conditionning)
     u1 + u2 + u3 + u4 + u5 + ... = 1 + χ(σ²=10.000)
     Worthy hint !   dim=137, δ=1.01340026, β=25.77
```

Here, the cost of the lattice reduction attack has decreased by 3 bikz.
While all the hints have been integrated, we finally estimate the security and run the attack again.

```python
sage: beta, delta = dbdd.estimate_attack()
....: t = cputime()
....: secret = dbdd.attack()
....: str(cputime(t)) + " CPU Seconds for the attack"

       Attack Estimation       
 dim=137     δ=1.013400      β=25.77  
  
       Running the Attack      
Running BKZ-27   Success ! 

47.93729300000001 CPU Seconds for the attack
```

This time, BKZ stopped at blocksize 27 while the estimation was around 26 bikz.