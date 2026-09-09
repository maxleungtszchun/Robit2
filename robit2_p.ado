program robit2_p, rclass
	syntax namelist(min=1 max=1) [, xb pr]

    if "`namelist'" == "" {
        di as error "Error: You must specify a variable name."
        exit 198
    }
    confirm new var `namelist'

	tempvar intercept
	gen `intercept' = 1

	tempname eb b b_cons_last
	matrix `eb' = e(b)

	local length_eb `= colsof(`eb') - 2'
	matrix `b' = J(`length_eb', 1, .)
	matrix `b'[1, 1] = _b[xb:_cons]
	local b_index 2

	local names_eb: colnames `eb'
	foreach i in `names_eb' {
		if "`i'" != "_cons" {
			matrix `b'[`b_index', 1] = _b[xb:`i']
			local no_cons `no_cons' `i'
			local ++b_index
		}
	}
	matrix rownames `b' = "_cons" `no_cons'

	mata: get_Xb("`intercept'", "`b'")

	if ("`xb'" != "" & "`pr'" != "") {
		di as error "Error: Only pr or xb is allowed."
		exit 198
	}

	if ("`xb'" == "") {
		if ("`pr'" == "") di "(option pr assumed; Pr(y))"
		gen `namelist' = 1 - ttail(_b[df:_cons], `temp_name'/_b[tau:_cons])
	}
	else {
		gen `namelist' = `temp_name'
	}

	matrix `b_cons_last' = J(`length_eb', 1, .)
	matrix `b_cons_last'[`length_eb', 1] = `b'[1, 1]

	forvalues i = 1/`length_eb' {
		if `i' != `length_eb' {
			local j `i' + 1
			matrix `b_cons_last'[`i', 1] = `b'[`j', 1]
		}
	}

	matrix rownames `b_cons_last' = `no_cons' "_cons"

	ret matrix b = `b'
	ret matrix b_cons_last = `b_cons_last'
	ret local no_cons `no_cons'
end
