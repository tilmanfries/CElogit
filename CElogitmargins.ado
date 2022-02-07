*! version 1.0.0
program CElogitmargins, eclass
	version 15

	syntax [varlist(fv)] [if], [binary(varlist) touse INCludestake FASTreshape post]

	if "`e(cmd)'" != "CElogit" {
        error 301
    }

	if ("`1'" == "" | "`1'" == ",") & "`includestake'" == "" {
		CElyingrate, `fastreshape' `post'
	}

	else {

	marksample touse, novarlist

	local pdraw = e(pdraw)
	local stake = e(stake)
	local kstar = e(kstar)
	local indepvars = e(indepvars)
	local depvar = e(depvar)

	tempname b1 b2 mo V1 V2 N id state high b V

	local hold: list indepvars - stake

	if "`hold'" == "" {
		local hold ""
	}
	else {
		fvrevar `hold', list
		local hold = r(varlist)
	}

	preserve

	if "`stake'" == "." {
		keep `pdraw'* `depvar' `hold' `kstar' `touse'
	}

	else {
		keep `pdraw'* `stake'* `depvar' `hold' `kstar' `touse'
	}

	foreach var in `hold' {
	    qui drop if `var' == .
	}

	qui drop if `depvar' == .
	qui drop if `kstar' == .

	di "Reshaping the data..."
	qui gen `id' = _n
	if "`fastreshape'" == "" {
		if "`stake'" == "." {
			qui reshape long "`pdraw'", i(`id') j(`state')
		}
		else {
		    qui reshape long "`pdraw'" "`stake'", i(`id') j(`state')
		}
	}
	else {
		if "`stake'" == "." {
			qui fastreshape long "`pdraw'", i(`id') j(`state')
		}
		else {
		    qui fastreshape long "`pdraw'" "`stake'", i(`id') j(`state')
		}
	}

	qui drop if `pdraw' == .
	qui gen `high' = `state' >= `kstar'
	qui drop if `high' == 1
    mata: mywork("`indepvars'",  ///
	   "`id'", "`pdraw'", "`state'", ///
	   "`touse'", "`constant'", ///
       "`b1'", "`V1'", "`b2'", "`V2'", "`N'" ///
   	   )

	restore

	if "`1'" != "," {
		local varlist: list varlist - stake
		_rmcoll `varlist', expand
		local cnames `r(varlist)'
		if "`includestake'" != "" {
			local cnames = "`stake' `cnames'"
		}
	}

	else {
		local cnames = "`stake'"
	}


	local n_vars =  `=wordcount("`cnames'")'

	matrix `b' = J(1,`n_vars',0)
	matrix `V' = J(`n_vars',`n_vars',0)

	local indepvars: list indepvars - stake
	_rmcoll `indepvars', expand
	local indepvars_extended `r(varlist)'
	if "`stake'" != "." {
		local indepvars_extended = "`stake' `indepvars_extended'"
	}

	_rmcoll `binary', expand
	local binary `r(varlist)'

	local j = 0
	foreach var in `indepvars_extended' {
		local ++j
		local k = 0
		foreach displ in `cnames' {
			local ++k
			if "`var'" == "`displ'" {
				matrix `b'[1,`k'] = `b1'[1,`j']
				matrix `V'[`k',`k'] = `V1'[`j',`j']

				foreach bin in `binary' {
					if "`var'" == "`bin'" {
						matrix `b'[1,`k'] = `b2'[1,`j']
						matrix `V'[`k',`k'] = `V2'[`j',`j']
					}
				}

			}
		}
	}

    matrix colnames `b' = `cnames'
    matrix colnames `V' = `cnames'
    matrix rownames `V' = `cnames'

    _estimates clear
	_estimates hold CEestimates

	ereturn post `b' `V', esample(`touse') buildfvinfo
	ereturn scalar N       = `N'
	ereturn local  cmd     "CElogitmargins"
	ereturn local pdraw = "`pdraw'"
	ereturn local stake = "`stake'"
	ereturn local kstar = "`kstar'"
	ereturn local indepvars = "`indepvars'"
	ereturn local depvar = "`depvar'"

    ereturn display

	if "`post'" == "" {
		_estimates unhold CEestimates
	}

}
end

mata:
mata set matalnum on

void mywork(string scalar indepvars, ///
			string scalar id,  string scalar pdraw, string scalar state, ///
	        string scalar touse,   string scalar constant, ///
	        string scalar b1name,   string scalar V1name, ///
			string scalar b2name,   string scalar V2name, ///
	        string scalar nname)
{
    real vector xb, x0b, x1b, pdraw_vec, states, b1, b2, C_vec, ID, ID_short
    real matrix X, IDM, V, Cm, INT, V1, V2
    real scalar K, rws, p, q
	states = st_data(., state, touse)
	pdraw_vec = st_data(., pdraw, touse)
	K = max(states)
    X = st_data(., indepvars, touse)
	rws = rows(X)
	b = st_matrix("e(b)")
	V = st_matrix("e(V)")

    if (constant == "") {
        X = X,J(rws, 1, 1)
    }
	p = cols(X)

	xb = X*b'

	ID = st_data(., id)
	ID_short = (min(ID) :: max(ID))
	N = rows(ID_short)

	P = J(rows(xb), 1, 1):/(J(rows(xb), 1, 1) + exp( - xb ))
	MFX = (J(rows(xb), 1, 1) - P):*P
	MFX = pdraw_vec:*MFX

	j = 1
	hold_mfx = J(N, 1, 0)
	hold_den = J(N, 1, 0)
	for (i=1;i<=N;i++) {
		while (ID[j] == i) {
			hold_mfx[i] = hold_mfx[i] + MFX[j]
			hold_den[i] = hold_den[i] + pdraw_vec[j]
			j = j + 1

			if (j > rws) {
				j = 1
			}
		}
	}

	MFX = hold_mfx
	DEN = hold_den
	MFX = MFX:/DEN
	MFX = 1 / N * sum(MFX)
	b1 = MFX:*b'

	PinvP = (J(rows(xb), 1, 1) - P):*P
	PinvP = pdraw_vec:*PinvP

	P2 = (J(rows(xb), 1, 1) - 2*P)
	P2 = pdraw_vec:*P2
	JAC = J(p,p,0)
	for (i=1; i<=p; i++) {
		for (j=1; j<=p; j++) {
			hold = PinvP:*P2:*b[1,i]:*X[.,j]
			l = 1
			hold2 = J(N, 1, 0)
			for (k=1;k<=N;k++) {
				while (ID[l] == k) {
					hold2[k] = hold2[k] + hold[l]
					l = l + 1

					if (l > rws) {
						l = 1
					}
				}
			}
			hold = hold2
			hold = hold:/DEN
			JAC[i,j] = 1 / N * sum(hold)
			if (i == j) {
				l = 1
				hold2 = J(N, 1, 0)
				for (k=1;k<=N;k++) {
					while (ID[l] == k) {
						hold2[k] = hold2[k] + PinvP[l]
						l = l + 1

						if (l > rws) {
							l = 1
						}
					}
				}
				hold = hold2
				hold = hold:/DEN
				JAC[i,j] = JAC[i,j] + 1/N * sum(hold)
			}
		}
	}

	V1 = JAC*V*JAC'
	MFX = J(rws, p, 0)
	JAC = J(p,p,0)
	for (i=1; i<= p; i++) {
		X1 = X
		X1[.,i] = J(rws,1,1)
		X0 = X
		X0[.,i] = J(rws,1,0)
		x1b = X1*b'
		x0b = X0*b'
		P1 = J(rows(x1b), 1, 1):/(J(rows(x1b), 1, 1) + exp( - x1b ))
		P0 = J(rows(x0b), 1, 1):/(J(rows(x0b), 1, 1) + exp( - x0b ))
		MFX[.,i] = P1 - P0

		for (j=1; j<=p; j++) {
			hold = (P1:*(J(rows(P1),1,1)-P1) - P0:*(J(rows(P1),1,1)-P0)):*X[.,j]
			hold = pdraw_vec:*hold
			l = 1
			hold2 = J(N, 1, 0)
			for (k=1;k<=N;k++) {
				while (ID[l] == k) {
					hold2[k] = hold2[k] + hold[l]
					l = l + 1

					if (l > rws) {
						l = 1
					}
				}
			}
			hold = hold2
			hold = hold:/DEN
			JAC[i,j] = 1 / N * sum(hold)
			if (i == j) {
				hold = P1:*(J(rows(P1),1,1)-P1)
				hold = pdraw_vec:*hold
				l = 1
				hold2 = J(N, 1, 0)
				for (k=1;k<=N;k++) {
					while (ID[l] == k) {
						hold2[k] = hold2[k] + hold[l]
						l = l + 1

						if (l > rws) {
							l = 1
						}
					}
				}
				hold = hold2
				hold = hold:/DEN
				JAC[i,j] = 1 / N * sum(hold)
			}
		}

	}

	MFX = pdraw_vec:*MFX
	j = 1
	hold_mfx = J(N, p, 0)
	for (i=1;i<=N;i++) {
		while (ID[j] == i) {
			hold_mfx[i,.] = hold_mfx[i,.] + MFX[j,.]
			j = j + 1

			if (j > rws) {
				j = 1
			}
		}
	}
	MFX = hold_mfx
	MFX = MFX:/DEN
	MFX = J(1,N,1) * MFX
	b2 = 1 / N :* MFX

	V2 = JAC*V*JAC'

	b1 = b1'
	st_matrix(b1name, b1)
    st_matrix(V1name, V1)
	st_matrix(b2name, b2)
    st_matrix(V2name, V2)
    st_numscalar(nname, N)

}

end

program CElyingrate, eclass
	version 15

	syntax, [FASTreshape touse post]

	marksample touse

	local pdraw = e(pdraw)
	local stake = e(stake)
	local kstar = e(kstar)
	local indepvars = e(indepvars)
	local depvar = e(depvar)

	tempname b1 b2 mo V1 V2 N id state high b V

	local hold: list indepvars - stake

	if "`hold'" == "" {
		local hold ""
	}
	else {
		fvrevar `hold', list
		local hold = r(varlist)
	}

	preserve
	qui keep if `touse' == 1

	if "`stake'" == "." {
		keep `pdraw'* `depvar' `hold' `kstar' `touse'
	}

	else {
		keep `pdraw'* `stake'* `depvar' `hold' `kstar' `touse'
	}

	foreach var in `hold' {
	    qui drop if `var' == .
	}

	qui drop if `depvar' == .
	qui drop if `kstar' == .

	di "Reshaping the data..."
	qui gen `id' = _n
	if "`fastreshape'" == "no" {
		if "`stake'" == "." {
			qui reshape long "`pdraw'", i(`id') j(`state')
		}
		else {
		    qui reshape long "`pdraw'" "`stake'", i(`id') j(`state')
		}
	}
	else {
		if "`stake'" == "." {
			qui fastreshape long "`pdraw'", i(`id') j(`state')
		}
		else {
		    qui fastreshape long "`pdraw'" "`stake'", i(`id') j(`state')
		}
	}

	qui drop if `pdraw' == .

	qui gen `high' = `state' >= `kstar'
	qui drop if `high' == 1

    mata: mywork2("`indepvars'",  ///
	   "`id'", "`pdraw'", "`state'", ///
	   "`touse'", "`constant'", ///
       "`b'", "`V'", "`N'" ///
   	   )

	restore

    matrix colnames `b' = "Lying rate"
    matrix colnames `V' = "Lying rate"
    matrix rownames `V' = "Lying rate"

	_estimates clear
	_estimates hold CEestimates

	ereturn post `b' `V'
	ereturn scalar N       = `N'
	ereturn local  cmd     "CElogitmargins"
	ereturn local pdraw = "`pdraw'"
	ereturn local stake = "`stake'"
	ereturn local kstar = "`kstar'"
	ereturn local indepvars = "`indepvars'"
	ereturn local depvar = "`depvar'"

    ereturn display

	if "`post'" == "" {
		_estimates unhold CEestimates
	}

end

mata:
mata set matalnum on

void mywork2(string scalar indepvars, ///
			string scalar id,  string scalar pdraw, string scalar state, ///
	        string scalar touse,   string scalar constant, ///
	        string scalar bname,   string scalar Vname, ///
	        string scalar nname)
{
    real vector xb, x0b, x1b, pdraw_vec, states, b1, b2, C_vec, ID, ID_short
    real matrix X, IDM, V, Cm, INT, V1, V2
    real scalar K, rws, p, q
	states = st_data(., state, touse)
	pdraw_vec = st_data(., pdraw, touse)
	K = max(states)
    X = st_data(., indepvars, touse)
	rws = rows(X)
	b = st_matrix("e(b)")
	V = st_matrix("e(V)")

    if (constant == "") {
        X = X,J(rws, 1, 1)
    }
	p = cols(X)

	xb = X*b'

	ID = st_data(., id)
	ID_short = (min(ID) :: max(ID))
	N = rows(ID_short)

	P = J(rows(xb), 1, 1):/(J(rows(xb), 1, 1) + exp( - xb ))
	hold_num = pdraw_vec:*(J(rows(xb), 1, 1) - P):*P:*X
	hold_den = pdraw_vec
	hold_mfx = P
	hold_mfx = pdraw_vec:*hold_mfx

	j = 1
	NUM = J(N,p,0)
	DEN = J(N,1,0)
	MFX = J(N,1,0)
	for (i=1;i<=N;i++) {
		while (ID[j] == i) {
			NUM[i,.] = NUM[i,.] + hold_num[j,.]
			DEN[i] = DEN[i] + hold_den[j]
			MFX[i] = MFX[i] + hold_mfx[j]
			j = j + 1

			if (j > rws) {
				j = 1
			}
		}
	}
	MFX = MFX:/DEN
	b = 1 / N * sum(MFX)

	DEN = DEN*J(1, cols(NUM), 1)
	hold_JAC = NUM:/DEN

	JAC = J(1, p, 0)
	for (j=1; j<=p; j++) {
		JAC[1,p] = 1/N * sum(hold_JAC[.,p])
	}

	V = JAC * V * JAC'

	st_matrix(bname, b)
    st_matrix(Vname, V)
    st_numscalar(nname, N)

}

end
