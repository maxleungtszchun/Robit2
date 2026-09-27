clear all
set more off
set linesize 150

cd "C:\Users\ml\Desktop\Robit2\"
// cd "Z:\Desktop\code\stata\robit2\"

local adofiles  : dir "." files "*.ado"
local matafiles : dir "." files "*.mata"
local combinedfiles : list adofiles | matafiles

foreach file in `combinedfiles' {
    run "`file'"
}

program get_data
	// set seed 1234
	clear
	set obs 1000
	gen x1 = rnormal()
	gen x2 = rnormal()
	// gen x1 = 0+int((5-0+1)*runiform())
	// gen x2 = 0+int((5-0+1)*runiform())
	gen y = (0.5 + 0.5*x1 + 0.2*x2 + rt(4) > 0)
end

program sim_df_mle
	get_data
	robit2 y x1 x2
end

program sim_df_pl
	get_data
	robit2_pl y x1 x2, min_val(0.5) max_val(30)
end

simulate df_mle = _b[df:_cons], reps(50): sim_df_mle
summ df_mle, detail

simulate df_pl = r(opt_df), reps(50): sim_df_pl
summ df_pl, detail

get_data
robit2_pl y x1 x2, min_val(0.5) max_val(30) graph
robit2 y x1 x2, nocnsreport vce(robust)
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
