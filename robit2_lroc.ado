program robit2_lroc, rclass
	syntax [, nograph]

	set more off
	ret scalar N = _N
	local num_pts = 400
	matrix roc_mat = J(`num_pts', 2, .)

	forvalues i = 1/`num_pts' {
		local val = `i' / `num_pts'
		qui robit2_lstat, cutoff(`val')
		matrix roc_mat[`i', 1] = r(P_p1)
		matrix roc_mat[`i', 2] = 100 - r(P_n0)
	}

	preserve
	clear
	qui svmat roc_mat
	sort roc_mat2
	qui integ roc_mat1 roc_mat2
	ret scalar area = r(integral) / 100 / 100

	if "`graph'" == "" {
		local area : di %6.4f return(area)
		twoway (scatter roc_mat1 roc_mat2, connect(l)) 		///
			(function y = x, range(0 100) lcolor(black)), 	///
			ytitle(`"Sensitivity (%)"') 					///
			xtitle(`"1-Specificity (%)"') 					///
			ylabel(0(25)100, grid) 							///
			xlabel(0(25)100, grid) 							///
			legend(off)										///
			note(`"Area under ROC curve = `area'"')
	}
	restore

	#delimit ;
	noi di in gr _n
		`"Robit"'
		`" model for `e(depvar)'"' _n(2)
		`"number of observations = "' in yel %8.0f return(N) _n
		in gr `"area under ROC curve   = "'
		in yel %8.4f return(area) ;
	#delimit cr

	matrix drop roc_mat

end
