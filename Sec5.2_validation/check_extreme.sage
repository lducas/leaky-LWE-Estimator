load("../framework/instance_gen.sage")

nn = 40
q = 97
D_s = build_centered_binomial_law(4)
var = 2
dim = 2*nn+1

for DBDD_type in [DBDD_predict_diag, DBDD_predict, DBDD, DBDD_optimized]:

	logging("++++++++++++++++++++++++++++++++ \n + " +
	          str(DBDD_type) +
	        " +  \n ++++++++++++++++++++++++++++++++", style='BIGHEADER')
	A, b, dbdd = initialize_from_LWE_instance(DBDD_type, nn, q, nn, D_s, D_s, verbosity=2)
	v = vec([1]+(2*nn-1)*[0]) 
	dbdd.estimate_attack()
	dbdd.integrate_approx_hint(v,dbdd.leak(v), 1/(3.99 * dim))
	try:
		dbdd.integrate_approx_hint(v,dbdd.leak(v), 1/(4.01 * dim))
		dbdd.logging("Extreme hint undetected", style='FAILURE')
		raise ValueError("Extreme hint went in undetected")
	except InvalidHint:
		dbdd.logging("Extreme hint avoided", style='SUCCESS')

	dbdd.integrate_perfect_hint(v,dbdd.leak(v))
	dbdd.estimate_attack()


	A, b, dbdd = initialize_from_LWE_instance(DBDD_type, nn, q, nn, D_s, D_s, verbosity=2)
	v = vec([1]+(2*nn-1)*[0]) 

	dbdd.estimate_attack()
	dbdd.integrate_modular_hint(v,dbdd.leak(v), floor(sqrt(3.99 * var * dim)))
	try:
		dbdd.integrate_modular_hint(v,dbdd.leak(v), ceil(sqrt(4.01 * var * dim)))
		dbdd.logging("Extreme hint undetected", style='FAILURE')
		raise ValueError("Extreme hint went in undetected")
	except InvalidHint:
		dbdd.logging("Extreme hint avoided", style='SUCCESS')

	dbdd.integrate_perfect_hint(v,dbdd.leak(v))
	dbdd.estimate_attack()


	A, b, dbdd = initialize_from_LWE_instance(DBDD_type, nn, q, nn, D_s, D_s, verbosity=2)
	v = vec([1]+(2*nn-1)*[0]) 

	# Hand forcing an extreme hint, hoping for detection when adding a perfect hint
	if DBDD_type==DBDD_predict_diag:
		dbdd.S[0] = 0.00001
	else:
		dbdd.S[0,0] = 0.00001
	dbdd.estimate_attack()
	try:
		dbdd.integrate_perfect_hint(v,dbdd.leak(v))
		dbdd.logging("Extreme hint undetected", style='FAILURE')
		raise ValueError("Extreme hint went in undetected")
	except InvalidHint:
		dbdd.logging("Extreme hint avoided", style='SUCCESS')
