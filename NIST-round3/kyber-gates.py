from cost import *


# Result of the DDGR20 BKZ prediction
#
# ======= Kyber-512 round3
# GSA Intersect:             dim=1025      δ=1.003945     β=405.53 
# Probabilistic simulation:  dim=1025                     β=413.46
# ======= Kyber-768 round3
# GSA Intersect:             dim=1467      δ=1.002904      β=623.41  
# Probabilistic simulation:  dim=1467                      β=637.43 
# ======= Kyber-1024 round3
# GSA Intersect:             dim=1918      δ=1.002263      β=873.23
# Probabilistic simulation:  dim=1918                      β=894.27

# As expected, the GSA intersect prediction roughly match the 
# one made by the kyber dedicated script :
#
# Kyber-512  : Primal attacks uses block-size 405 and 490 samples
# Kyber-768  : Primal attacks uses block-size 625 and 655 samples
# Kyber-1024 : Primal attacks uses block-size 877 and 860 samples


print("           \t & n  \t&  β \t& β' \t& gates \t& memory ")
print("Kyber-512  \t & %d\t& %d\t& %d\t& %.1f \t& %.1f "%summary(1025, 413))
print("Kyber-768  \t & %d\t& %d\t& %d\t& %.1f \t& %.1f "%summary(1467, 637))
print("Kyber-1024 \t & %d\t& %d\t& %d\t& %.1f \t& %.1f "%summary(1918, 894))

