mata:
	void get_Xb(string scalar intercept, string scalar b) {
		X = st_data(., (intercept, st_local("no_cons")))
		b = st_matrix(b)
		temp_name = st_tempname()
		idx = st_addvar("double", temp_name)
		st_store(., idx, X*b)
		st_local("temp_name", temp_name)
	}
end
