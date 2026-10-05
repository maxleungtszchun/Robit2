program robit2_pl, rclass
	syntax varlist [, min_val(real 0.5) max_val(real 10) nograph]

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

	local opt = _N

	sort profile_ll
	list df profile_ll in `opt', abbreviate(30)

	local opt_df = df[`opt']
	tempname opt_profile_ll
	scalar `opt_profile_ll' = profile_ll[`opt']

	sort df
	gen pl_ratio_stat = 2 * (`opt_profile_ll' - profile_ll)
	gen in_conf_set = (pl_ratio_stat <= invchi2(1, 1 - 0.1))
	list, abbreviate(30)

	if "`graph'" == "" {
		twoway (line profile_ll df), ///
			xline(`opt_df') ///
			title("Profile Log Likelihood") ///
			xtitle("df") ///
			ytitle("Profile Log Likelihood")
	}

	restore

	ret scalar pl_opt_df = `opt_df'
	ret scalar pl_opt_profile_ll = `opt_profile_ll'
end
