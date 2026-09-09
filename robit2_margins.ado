program robit2_margins, rclass
	syntax [, atmeans]

	tempvar Xb fXb
	tempname result b result_no_cons J J1 J2 x_bar cov fprimeXb V cov_no_cons sd_no_cons combined_result z p

	matrix `V' = e(V)
	matrix `V' = `V'[3...,3...]

	qui robit2_p `Xb', xb
	matrix `b' = r(b)
	local no_cons `"`r(no_cons)'"'

	if "`atmeans'" == "" {
		gen `fXb' = tden(_b[df:_cons], `Xb'/_b[tau:_cons])
		qui summ `fXb'
		matrix `result' = r(mean) * `b'
	}
	else {
		qui summ `Xb'
		matrix `result' = tden(_b[df:_cons], r(mean)/_b[tau:_cons]) * `b'

		local length_b `= rowsof(`b')'
		matrix `J2' = tden(_b[df:_cons], r(mean)/_b[tau:_cons]) * I(`length_b')

		scalar `fprimeXb' = -((_b[df:_cons]+1)*r(mean)/_b[tau:_cons])*tden(_b[df:_cons], r(mean)/_b[tau:_cons])/(_b[df:_cons]+(r(mean)/_b[tau:_cons])^2)
		est store robit2_e
		qui mean `no_cons'
		matrix `x_bar' = (e(b), 1)
		qui est restore robit2_e
		matrix `J1' = `fprimeXb' * `b' * `x_bar'

		matrix `J' = `J1' + `J2'
		matrix `cov' = `J' * `V' * `J''
	}

	local names_b: rownames `b'
	matrix rownames `result' = `names_b'
	matrix colnames `result' = "dy/dx"
	matrix `result_no_cons' = `result'[2...,1]

	if "`atmeans'" == "" {
		matlist `result_no_cons'
	}
	else {
		local row_cov `= rowsof(`cov') - 1'
		matrix `cov_no_cons' = `cov'[1..`row_cov',1..`row_cov']
		mata: st_matrix("`sd_no_cons'", sqrt(st_matrix("`cov_no_cons'")))

		matrix `sd_no_cons' = vecdiag(`sd_no_cons')'
		matrix rownames `sd_no_cons' = `no_cons'
		matrix colnames `sd_no_cons' = "Delta-method:Std Err"

		mata: st_matrix("`z'", st_matrix("`result_no_cons'") :/ st_matrix("`sd_no_cons'"))
		matrix rownames `z' = `no_cons'
		matrix colnames `z' = "z"

		mata: st_matrix("`p'", 2*normal(-abs(st_matrix("`z'"))))
		matrix rownames `p' = `no_cons'
		matrix colnames `p' = "P>|z|"

		matrix `combined_result' = `result_no_cons', `sd_no_cons', `z', `p'
		matlist `combined_result',  border(top bottom) title("Conditional marginal effects") ///
			cspec(o0& %12s | %10.7g & %12.7g & %5.2f & %5.3f o0&) rspec(--&-)
		ret matrix sd = `sd_no_cons'
	}
	ret matrix ame = `result_no_cons'
end
