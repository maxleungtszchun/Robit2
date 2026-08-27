program robit2_margins, rclass
	syntax [, atmeans]

	tempvar Xb fXb
	tempname result b result_no_cons

	qui robit2_p `Xb', xb
	matrix `b' = r(b)

	if "`atmeans'" == "" {
		gen `fXb' = tden(_b[df:_cons], `Xb'/_b[tau:_cons])
		qui summ `fXb'
		matrix `result' = r(mean) * `b'
	}
	else {
		qui summ `Xb'
		matrix `result' = tden(_b[df:_cons], r(mean)/_b[tau:_cons]) * `b'
	}

	local names_b: rownames `b'
	matrix rownames `result' = `names_b'
	matrix colnames `result' = "dy/dx"
	matrix `result_no_cons' = `result'[2...,1]
	matrix list `result_no_cons'
	ret matrix ame = `result_no_cons'
end
