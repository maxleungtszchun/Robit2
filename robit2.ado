program robit2, properties(or svyb svyj svyr swml mi) eclass byable(onecall)
	if replay() {
		version 11
		if !inlist("`e(cmd)'", "robit2") {
			error 301
		}

		if _by() {
			error 190
		}
		else Replay `0'

		exit
	}

	if _by() {
		local BY `"by `_byvars'`_byrc0':"'
	}

	version 11
	local version : di "version " string(_caller()) ":"

	`version' `BY' _vce_parserun robit2, mark(OFFset CLuster) : `0'
	if "`s(exit)'" != "" {
		ereturn local cmdline `"robit2 `0'"'
		exit
	}

	`version' `BY' Estimate `0'
	ereturn local cmdline `"robit2 `0'"'
end

program robit2_mle_lf
	args lnf xb df tau
	tempvar p
	qui gen double `p' = 1-ttail(`df',`xb'/`tau')
	qui replace `lnf' = $ML_y1*ln(`p')+(1-$ML_y1)*ln(1-`p')
end

program robit2_mle_lf0
	args todo b lnfj
	tempvar xb df tau p
	mleval `xb' = `b', eq(1)
	mleval `df' = `b', eq(2)
	mleval `tau' = `b', eq(3)
	qui gen double `p' = 1-ttail(`df',`xb'/`tau')
	qui replace `lnfj' = $ML_y1*ln(`p')+(1-$ML_y1)*ln(1-`p')

	// qui replace `g1' = ($ML_y1-`p')*tden(`df',`xb'/`tau')/(`p'*(1-`p'))

end

program Estimate, eclass byable(recall)
	version 11
	syntax varlist(ts fv) [if] [in]		///
		[fw pw iw] [,					///
		df(real 0)						///
		tau(real 1)						///
		FROM(string)					///
		noLOg							/// -ml model- options
		noCONStant						///
		OFFset(varname numeric)			///
		ASIS							///
		TECHnique(passthru)				///
		VCE(passthru)					///
		LTOLerance(passthru)			///
		TOLerance(passthru)				///
		noWARNing						///
		Robust CLuster(passthru)		/// old options
		CRITtype(passthru)				///
		SCORE(passthru)					///
		DOOPT							/// NOT DOCUMENTED
		notable							/// -Replay- options
		noHeader						///
		NOCOEF							///
		GROUPED							///
		*								/// -mlopts- options
	]
		// OR							/// removed

	if `:length local doopt' {
		opts_exclusive "doopt `robust'"
		opts_exclusive "doopt `cluster'"
		opts_exclusive "doopt `score'"
		opts_exclusive "doopt `technique'"
		if `:length local ltolerance' == 0 {
			local ltolerance ltol(0)
		}
		if `:length local tolerance' == 0 {
			local tolerance tol(1e-4)
		}
		local doopt doopt halfsteponly
	}

	local vceopt =	`:length local vce'		|	///
	   		`:length local weight'		|		///
	   		`:length local cluster'		|		///
	   		`:length local robust'
	if `vceopt' {
		_vce_parse, argopt(CLuster) opt(OIM OPG Robust) old	///
			: [`weight'`exp'], `vce' `robust' `cluster'
		local vce
		if "`r(cluster)'" != "" {
			local clustvar `r(cluster)'
			local vce vce(cluster `r(cluster)')
		}
		else if "`r(robust)'" != "" {
			local vce vce(robust)
		}
		else if "`r(vce)'" != "" {
			local vce vce(`r(vce)')
		}
		if !inlist(`"`vce'"', "", "vce(oim)") {
			opts_exclusive "`doopt' `vce'"
		}
	}

	// check syntax
	_get_diopts diopts options, `options'
	mlopts mlopts, `options' `technique' `vce' `tolerance' `ltolerance'
	local coll `s(collinear)'
	if "`weight'" != "" {
		local wgt "[`weight'`exp']"
	}
	if "`offset'" != "" {
		local offopt "offset(`offset')"
	}

	// mark the estimation sample
	marksample touse
	if `:length local offset' {
		markout `touse' `offset'
	}
	if `:length local clustvar' {
		markout `touse' `clustvar', strok
	}

	tempname rules mns
	mat `rules' = J(1,4,0)

	if `:length local log' {
		local skipline noskipline
	}
	_rmcoll `varlist' `wgt' if `touse',	///
		`coll'							///
		`skipline'						///
		`constant'						///
		probit							/// _rmcoll does not recognize robit2
		`offopt'						///
		touse(`touse')					///
		`asis'							///
		expand
	local varlist `"`r(varlist)'"'
	matrix `rules' = r(rules)
	matrix `mns' = r(mns)
	tempname b0
	scalar `b0' = r(b0)
	local n0 = r(n0)
	local n1 = r(n1)
	if `n0' + `n1' == 0 {
		exit 2000
	}
	gettoken lhs rhs : varlist
	_fv_check_depvar `lhs'

	// initial value
	if `"`from'"' == "" {
		if "`constant'" == "" {
			tempname bb
			local k :list sizeof rhs
			local k `k' + 3
			matrix `bb' = J(1,`k',0)
			matrix `bb'[1,`k'] = `b0'
			matrix `bb'[1,2] = 1
			matrix colna `bb' = df:_cons tau:_cons `rhs' xb:_cons
			local initopt init(`bb')
		}
	}
	else {
		local initopt `"init(`from')"'
	}

nobreak {

	tempname perfect
	mata: mopt__pl_init("`perfect'")

capture noisily break {

	qui summ `lhs'
	tempname y_mean sample_size ll_0
	scalar `y_mean' = r(mean)
	scalar `sample_size' = r(N)
	scalar `ll_0' = `sample_size'*`y_mean'*ln(`y_mean')+`sample_size'*(1-`y_mean')*ln(1-`y_mean')

	cap constraint drop 5 6
	if `df' != 0 {
		if `df' < 0 {
			display as error "df must be positive."
			exit
		}
		else {
			constraint 5 _b[df:_cons] = `df'
		}
	}

	constraint 6 _b[tau:_cons] = `tau'

	// fit the full model
	ml model lf robit2_mle_lf				///
		(xb: `lhs' = `rhs',					///
			`constant'						///
			`offopt'						///
			`expopt'						///
		) (df: ) (tau: )					///
		`wgt' if `touse',	///
		constraint(5, 6) 	///
		`doopt'				///
		`initopt'			///
		`log'				///
		`mlopts'			///
		`crittype'			///
		`score'				///
		`warning'			///
		userinfo(`perfect')	///
		noskipline			///
		collinear			///
		missing				///
		nopreserve			///
		maximize

} // capture noisily break
	local rc = c(rc)

	if `rc' {
		capture mata: rmexternal("`perfect'")
		exit `rc'
	}

} // nobreak

	mata: mopt__pl_post("`perfect'")

	// save a title for -Replay- and the name of this command
	ereturn matrix rules `rules'
	ereturn matrix mns `mns'

	ereturn scalar r2_p = 1 - e(ll)/`ll_0'

	ereturn local offset `e(offset1)'
	ereturn local offset1
	ereturn local title "Robit regression"
	ereturn local marginsnotok	stdp		///
					DBeta					///
					DEviance				///
					DX2						///
					DDeviance				///
					Hat						///
					Number					///
					Residuals				///
					RStandard				///
					SCore
	ereturn local predict robit2_p
	ereturn local estat_cmd robit2_estat
	ereturn local cmd robit2

	Replay , `table' `header' `nocoef' `grouped' `diopts' // norules or is removed
end

program Replay
	syntax [, notable noHeader NOCOEF GROUPED *] // noRULES OR is removed
	if "`nocoef'" != "" {
		local table notable
		local header noheader
	}
	if "`grouped'" != "" {
		local title title(Robit regression for grouped data)
	}
	_get_diopts diopts, `options'
	_prefix_display, `table' `header' `rules' `or' `title' `diopts'
end

exit
