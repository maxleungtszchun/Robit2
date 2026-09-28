program robit2_cv, rclass
	syntax varlist [, k(integer 5) min_val(real 0.5) max_val(real 10) nograph]

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

	capture which crossfold
	if _rc ssc install crossfold

	tempname r_est opt_RMSE
	local dfs = (`max_val'-`min_val')/`step' + 1
	matrix avg_r_est_matrix = J(`dfs', 2, .)

	local i = 1
	forvalues df = `min_val'(`step')`max_val' {
		qui crossfold robit2 `lhs' `rhs', df(`df') k(`k')
		matrix `r_est' = r(est)
		mata: st_numscalar("avg_r_est", mean(st_matrix("`r_est'")))
		matrix avg_r_est_matrix[`i', 1] = `df'
		matrix avg_r_est_matrix[`i', 2] = avg_r_est
		local ++i
	}
	matrix colnames avg_r_est_matrix = "df" "RMSE"

	drop _est_est*

	preserve
	clear
	qui svmat avg_r_est_matrix

	rename avg_r_est_matrix1 df
	rename avg_r_est_matrix2 RMSE
	list

	sort RMSE
	list in 1
	local opt_df = df[1]
	scalar `opt_RMSE' = RMSE[1]

	if "`graph'" == "" {
		sort df
		twoway (line RMSE df), ///
			xline(`opt_df') ///
			title(`"`k'-fold CV"') ///
			xtitle("df") ///
			ytitle("Average RMSE")
	}
	restore

	ret scalar cv_opt_df = `opt_df'
	ret scalar cv_opt_RMSE = `opt_RMSE'
end
