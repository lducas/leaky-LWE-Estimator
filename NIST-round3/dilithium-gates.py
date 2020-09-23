from cost import *


# Result of the DDGR20 BKZ prediction
#
# ======= Dilithium-NL2 round3
# GSA Intersect:               dim=2049   δ=1.003828      β=423.43 
# Probabilistic simulation:    dim=2049                   β=433.73
# ======= Dilithium-NL3 round3
# GSA Intersect:               dim=2654   δ=1.002903      β=623.61
# Probabilistic simulation:    dim=2654                   β=638.33
# ======= Dilithium-NL5 round3
# GSA Intersect:               dim=3540   δ=1.002284      β=862.84  
# Probabilistic simulation:    dim=3540                   β=883.56 

# As expected, the GSA intersect prediction roughly match the 
# one made by the dilithium dedicated script :
#
# Dilithium-NL2  : Primal attacks uses block-size 423 and 1010 samples
# Dilithium-NL3  : Primal attacks uses block-size 624 and 1285 samples
# Dilithium-NL5  : Primal attacks uses block-size 863 and 1670 samples


print("              \t& n   \t&  β \t& β' \t& gates \t& memory ")
print("Dilithium-NL2 \t& %d\t& %d\t& %d\t& %.1f \t& %.1f "%summary(2049, 433))
print("Dilithium-NL3 \t& %d\t& %d\t& %d\t& %.1f \t& %.1f "%summary(2654, 638))
print("Dilithium-NL5 \t& %d\t& %d\t& %d\t& %.1f \t& %.1f "%summary(3540, 883))

