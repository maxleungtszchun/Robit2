program robit2_pl, rclass
	syntax varlist [, min_val(real 0.5) max_val(real 10) graph]

	gettoken lhs rhs : varlist

	if `min_val' <= 0 | `max_val' <= 0 {
		display as error "min_val and max_val must be positive."
		exit
	}

	if `min_val' >= `max_val' {
		display as error "max_val must be larger than min_val."
		exit
	}

	local step = 0.5

	if mod(`max_val'-`min_val', `step') != 0 {
		display as error "max_val - min_val must be a multiple of 0.5."
		exit
	}

	tempname memhold
	tempfile results
	qui postfile `memhold' df profile_ll using "`results'", replace

	forvalues df = `min_val'(`step')`max_val' {
		qui robit2 `lhs' `rhs', df(`df')
		post `memhold' (`df') (e(ll))
	}
	postclose `memhold'

	preserve
	use "`results'", clear

	list
	local opt = _N

	sort profile_ll
	list df profile_ll in `opt'

	local opt_df = df[`opt']
	tempname opt_profile_ll
	scalar `opt_profile_ll' = profile_ll[`opt']

	if "`graph'" != "" {
		sort df
		twoway (line profile_ll df), ///
			xline(`opt_df') ///
			title("Profile Likelihood") ///
			xtitle("df") ///
			ytitle("Profile Likelihood")
	}
	restore

	ret scalar opt_df = `opt_df'
	ret scalar opt_profile_ll = `opt_profile_ll'
end
