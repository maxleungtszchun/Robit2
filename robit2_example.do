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

set obs 1000
set seed 1234
gen x1 = rnormal()
gen x2 = rnormal()
// gen x1 = 0+int((5-0+1)*runiform())
// gen x2 = 0+int((5-0+1)*runiform())
gen y = (0.5 + 0.5*x1 + 0.2*x2 + rt(4) > 0)
gen group = (runiform() < 0.5)

// bysort group: robit2 y x1 x2, nocnsreport vce(robust) df(99999) nolog noheader difficult
// robit2 y x1 x2 if group == 1, nocnsreport vce(robust) df(99999) nolog noheader difficult
// robit2 y x1, nocnsreport vce(robust) df(99999) offset(x2)
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

// bysort group: probit y x1 x2, vce(robust) nolog noheader difficult
// probit y x1 x2 if group == 1, vce(robust) nolog noheader difficult
// probit y x1, vce(robust) offset(x2)
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
