program robit2_estat, rclass

	if "`e(cmd)'" != "robit2" {
		error 301
	}

	gettoken key rest : 0, parse(", ")
	local lkey = length(`"`key'"')
	if `"`key'"' == substr("classification",1,max(4,`lkey')) {
		robit2_lstat `rest'
	}
	else if `"`key'"' == substr("gof",1,max(3,`lkey')) {
		robit2_lfit `rest'
	}
	else {
		estat_default `0'
	}

end
