program robit2_lfit, rclass
	tempvar p yobs yexp n_j i summand
	tempname K chi_p

	qui robit2_p `p'
	local no_cons `"`r(no_cons)'"'
	scalar `K' = rowsof(r(b))

	bysort `no_cons': gen `yobs' = sum(`e(depvar)'==1)
	bysort `no_cons': gen `yexp' = sum(`p')
	bysort `no_cons': gen `n_j' = _N
	bysort `no_cons': gen `i' = _n

	gen `summand' = ((`yobs'-`yexp')^2)/(`yexp'*(1-`yexp'/`n_j'))
	qui summ `summand' if `i' == `n_j'
	ret scalar chi = r(sum)
	ret scalar m = r(N)
	ret scalar N = _N
	ret scalar df = return(m) - `K'

	scalar `chi_p' = chi2tail(return(df), return(chi))

	di _n in smcl as txt `"{title:"' /*
		*/ `"Robit"' /*
		*/ `" model for `e(depvar)', goodness-of-fit test}"'

	di _n in gr _col(8) `"number of observations = "' in ye %9.0g return(N)
	di in gr `" number of covariate patterns = "' in ye %9.0g return(m)

	local skip = 29 - length(`"Pearson chi2(`return(df)')"')
	#delimit ;
	di in gr _skip(`skip') `"Pearson chi2("' in ye return(df)
	   in gr `") = "'
	   in ye %12.2f return(chi) _n
	   in gr _col(19) `"Prob > chi2 = "'
	   in ye %14.4f `chi_p' ;
	#delimit cr
end
