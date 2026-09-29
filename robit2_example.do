clear all
set more off
set linesize 150
set seed 1234

cd "C:\Users\ml\Desktop\Robit2\"
// cd "Z:\Desktop\code\stata\robit2\"

// test from mac

local adofiles  : dir "." files "*.ado"
local matafiles : dir "." files "*.mata"
local combinedfiles : list adofiles | matafiles

foreach file in `combinedfiles' {
    run "`file'"
}

* Testing data
program get_data
	clear
	set obs 1000
	gen x1 = rnormal()
	gen x2 = rnormal()
	// gen x1 = 0+int((5-0+1)*runiform())
	// gen x2 = 0+int((5-0+1)*runiform())
	gen y = (0.5 + 0.5*x1 + 0.2*x2 + rt(4) > 0)
end

get_data

* Example
* Estimate the degree of freedom with 10-fold Cross-Validation
robit2_cv y x1 x2, k(10) min_val(0.5) max_val(20)

* Estimate the degree of freedom with Profile Likelihood
robit2_pl y x1 x2, min_val(0.5) max_val(20)

* Estimate the degree of freedom with MLE
robit2 y x1 x2, nocnsreport vce(robust)

* Compare with Probit
robit2 y x1 x2, nocnsreport vce(robust) df(99999)
estat class
estat gof
estat gof, group(10)
estat auc
robit2_lroc
predict robit2p
predict robit2xb, xb
robit2_margins, atmeans
linktest

probit y x1 x2, vce(robust)
estat class
estat gof
estat gof, group(10)
estat auc
lroc
predict probitp
predict probitxb, xb
margins, dydx(*) atmeans
linktest

* Simulation
program sim_df_mle
	get_data
	robit2 y x1 x2
end

program sim_df_pl
	get_data
	robit2_pl y x1 x2, min_val(0.5) max_val(10) nograph
end

program sim_df_cv
	get_data
	robit2_cv y x1 x2, k(5) min_val(0.5) max_val(10) nograph
end

simulate df_mle = _b[df:_cons], reps(100): sim_df_mle
summ df_mle, detail

simulate df_pl = r(pl_opt_df), reps(100): sim_df_pl
summ df_pl, detail

simulate df_cv = r(cv_opt_df), reps(100): sim_df_cv
summ df_cv, detail