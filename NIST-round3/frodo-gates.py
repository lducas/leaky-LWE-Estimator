from cost import *


# Result of the DDGR20 BKZ prediction
#
# ======= Frodo-640 round3
# GSA Intersect:                dim=1297 	 δ=1.003474 	 β=485.84
# Probabilistic simulation:     dim=1297 	 	 	 		 β=496.36  
# ======= Frodo-976
# GSA Intersect:                dim=1969 	 δ=1.002647 	 β=707.60 
# Probabilistic simulation:     dim=1969 	 			 	 β=724.78 
# ======= Frodo-1344
# GSA Intersect:                dim=2634 	 δ=1.002152 	 β=933.55  
# Probabilistic simulation:     dim=2634 	 	 	 		 β=957.51  


print("              \t& n   \t&  β \t& β' \t& gates \t& memory ")
print("Frodo-640 \t& %d\t& %d\t& %d\t& %.1f \t& %.1f "%summary(1297, 496))
print("Frodo-976 \t& %d\t& %d\t& %d\t& %.1f \t& %.1f "%summary(1969, 724))
print("Frodo-1344 \t& %d\t& %d\t& %d\t& %.1f \t& %.1f "%summary(2634, 957))

