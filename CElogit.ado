*! version 1.0.0
program CElogit, eclass
/*
THIS IS THE HELP FILE
*/

	version 15

	syntax varlist(numeric ts fv) [if], ///
	pdraw(name) kstar(varname) ///
	[marksample vce(string) stake(name) touse interact_gamma(varname) FASTreshape noCONStant]

	marksample touse

	preserve
	qui keep if `touse' == 1

	_vce_parse `touse' , optlist(Robust) argoptlist(CLuster) : , vce(`vce')
    local vce        "`r(vce)'"
    local clustervar "`r(cluster)'"
    if "`vce'" == "robust" | "`vce'" == "cluster" {
        local vcetype "Robust"
    }
    if "`clustervar'" != "" {
        capture confirm numeric variable `clustervar'
        if _rc {
            display in red "invalid vce() option"
            display in red "cluster variable {bf:`clustervar'} is " ///
                "string variable instead of a numeric variable"
            exit(198)
        }
        sort `clustervar'
    }

	gettoken depvar indepvars : varlist
	_fv_check_depvar `depvar'

	tempname b mo V N rank id state c high reported high_report stakeXv

	getcinfo `indepvars' , `constant' stake(`stake') noindepvars(`indepvars') interact_gamma(`interact_gamma')

    local  cnames "`r(cnames)'"
    matrix `mo' = r(mo)

	if "`indepvars'" == "" {
		local hold ""
	}
	else {
		fvrevar `indepvars', list
		local hold = r(varlist)
	}

	keep `pdraw'* `stake'* `depvar' `hold' `kstar' `interact_gamma' `clustervar' `touse'

	foreach var in `hold' {
	    qui drop if `var' == .
	}

	qui drop if `depvar' == .
	qui drop if `kstar' == .

	if "`interact_gamma'" != "" {
		local indepvars "`stakeXv' `indepvars'"
	}

	if "`stake'" != "" {
		local indepvars "`stake' `indepvars'"
	}

	di "Reshaping the data..."
	qui gen `id' = _n
	if "`fastreshape'" == "" {
		qui reshape long "`pdraw'" "`stake'", i(`id') j(`state')
	}
	else {
	    qui fastreshape long "`pdraw'" "`stake'", i(`id') j(`state')
	}
	drop if `pdraw' == .

	gen `high' = `state' >= `kstar'
	gen `reported' = `state' == `depvar'
	gen `high_report' = `depvar' >= `kstar'
	gen `c' = `high' * 9999999999999999999

	if "`interact_gamma'" != "" {
		gen `stakeXv' = `stake' * `interact_gamma'
	}

	di "Maximizing the likelihood..."

    mata: mywork("`indepvars'", ///
	   "`id'", "`pdraw'", "`state'", "`high'", "`kstar'", "`reported'", "`high_report'", "`c'", ///
	   "`touse'", "`constant'", ///
       "`b'", "`V'", "`N'", "`rank'", "`mo'", ///
   	   "`vce'", "`clustervar'")

	restore

    if "`constant'" == "" {
        local cnames "`cnames' _cons"
    }

    matrix colnames `b' = `cnames'
    matrix colnames `V' = `cnames'
    matrix rownames `V' = `cnames'

    ereturn post `b' `V', esample(`touse') buildfvinfo
    ereturn scalar N       = `N'
    ereturn scalar rank    = `rank'
	ereturn local  vce      "`vce'"
    ereturn local  vcetype  "`vcetype'"
    ereturn local  clustvar "`clustervar'"
	ereturn local depvar "`depvar'"
	ereturn local indepvars "`indepvars'"
	ereturn local pdraw "`pdraw'"
	ereturn local kstar "`kstar'"
	ereturn local stake "`stake'"
    ereturn local  cmd     "CElogit"

    ereturn display

end

program getcinfo, rclass
    syntax [varlist(ts fv)], [noCONStant stake(name) interact_gamma(name) noindepvars(string)]

	if "`noindepvars'" != "" {
		_rmcoll `varlist' , `constant' expand
	    local cnames `r(varlist)'

	}
    else {
		local cnames ""
    }

	local p : word count `cnames'
	if "`constant'" == "" {
		local p = `p' + 1
		local cons _cons
	}

    tempname b mo mo_part

    matrix `b' = J(1, `p', 0)
    matrix colnames `b' = `cnames' `cons'
    _ms_omit_info `b'
    matrix `mo_part' = r(omit)

	if "`stake'" != "" & "`interact_gamma'" != "" {
		matrix `mo' = J(1, `p' + 2, 0)
		forvalues j = 1 / `p' {
		    matrix `mo'[1, `j' + 2] = `mo_part'[1,`j']
		}
		return local  cnames "Stake Interaction `cnames'"
	    return matrix mo = `mo'
	}

	if "`stake'" != "" & "`interact_gamma'" == "" {
		matrix `mo' = J(1, `p' + 1, 0)
		forvalues j = 1 / `p' {
		    matrix `mo'[1, `j' + 1] = `mo_part'[1,`j']
		}
		return local  cnames "Stake `cnames'"
	    return matrix mo = `mo'
	}

	if "`stake'" == "" {
		return local  cnames "`cnames'"
	    return matrix mo = `mo_part'
	}

end

mata:
void mywork(string scalar indepvars, ///
			string scalar id,  string scalar pdraw, string scalar state,  string scalar high,  string scalar kstar,  string scalar reported,  string scalar high_report,  string scalar c, ///
	        string scalar touse,   string scalar constant, ///
	        string scalar bname,   string scalar Vname, ///
	        string scalar nname,   string scalar rname, ///
			string scalar mo, ///
			string scalar vcetype, string scalar clustervar)
{
    real vector y, y_small, r, states, c_vec, pdraw_vec, b, mo_v, cv, cvarlong, cvec, ID, ID_short, r_lower, Ct, cvar
    real matrix X, V, Cm
    real scalar K, rws, j, p, N, i, rank
    y = st_data(., high_report, touse)
	r = st_data(., reported, touse)
	r_lower = (J(rows(y), 1, 1) - y):*r
	states = st_data(., state, touse)
	c_vec = st_data(., c, touse)
	pdraw_vec = st_data(., pdraw, touse)
	K = max(states)
    rws = rows(y)
    X = st_data(., indepvars, touse)

    if (constant == "") {
        X = X,J(rws, 1, 1)
    }
	p = cols(X)

	Ct = makeCt(mo)

	ID = st_data(., id)
	ID_short = (min(ID) :: max(ID))
	N = rows(ID_short)

	y_small = J(N, 1,0)
	j = 1
	for (i=1;i<=N;i++) {
		while (ID[j] == i) {
			y_small[i] = y[j]
			j = j + 1
			if (j > rws) {
				j = 1
			}
		}
	}



	"Now optimizing."

	S = optimize_init()
	optimize_init_argument(S, 1, y)
	optimize_init_argument(S, 2, X)
	optimize_init_argument(S, 3, c_vec)
	optimize_init_argument(S, 4, r_lower)
	optimize_init_argument(S, 5, pdraw_vec)
	optimize_init_argument(S, 6, ID)
	optimize_init_argument(S, 7, y_small)
	optimize_init_argument(S, 8, N)
	optimize_init_argument(S, 9, p)
	optimize_init_evaluator(S, &plleval())
	optimize_init_evaluatortype(S, "gf1")
	optimize_init_params(S, J(1, p, 0.1))
	optimize_init_constraints(S, Ct)
	optimize_init_conv_maxiter(S,300)

    b    = optimize(S)
	if (vcetype == "robust") {
        V    = optimize_result_V_robust(S)
    }
	else if (vcetype == "cluster") {
		cvar = J(N, 1, 0)
		cvarlong = st_data(., clustervar, touse)
		j = 1
		for(i = 1; i <= N; i++) {
			while (ID[j] == i) {
				cvar[i, 1] = cvarlong[j,1]
				j = j + 1
				if (j > rws) {
					j = 1
				}
			}
		}
        optimize_init_cluster(S, cvar)
        V    = optimize_result_V_robust(S)
    }
    else {
        V    = optimize_result_V_oim(S)
    }
    rank = p - diag0cnt(invsym(V))

    st_matrix(bname, b)
    st_matrix(Vname, V)
    st_numscalar(nname, N)
    st_numscalar(rname, rank)
}

real matrix makeCt(string scalar mo)
{
    real vector mo_v
    real scalar ko, j, p

    mo_v = st_matrix(mo)
    p    = cols(mo_v)
    ko   = sum(mo_v)
    if (ko>0) {
        Ct   = J(0, p, .)
        for(j=1; j<=p; j++) {
            if (mo_v[j]==1) {
                Ct  = Ct \ e(j, p)
            }
        }
        Ct = Ct, J(ko, 1, 0)
    }
    else {
        Ct = J(0,p+1,.)
    }

    return(Ct)
}

void plleval(real scalar todo, real vector b, ///
			 real vector y, real matrix X, real vector c, real vector r_lower, ///
			 real vector pdraw, real vector ID, real vector y_small, real scalar N, real scalar p, ///
			 val, grad, hess)
{

	//b
	real vector xb, highcontr, lowcontr, P, NUM, DEN, H, L, hold_high, hold_low, hold_den
	real scalar j, rws
    xb = X*b' + c

	rws = rows(xb)

	hold_high = pdraw:/(J(rws, 1, 1) + exp( - xb ))

	hold_low = (- xb - log(J(rws, 1, 1) + exp(- xb))):*r_lower
	//lowcontr = lowcontr:*r_lower

	// Calculations for the derivative.
	P = J(rows(xb), 1, 1):/(J(rows(xb), 1, 1) + exp( - xb ))
	hold_num = y:*pdraw:*(J(rows(xb), 1, 1) - P):*P:*X
	hold_den = pdraw:*P
	hold_L = P:*X:*r_lower

	// Collapse the N*KX1 vectors into NX1 vectors.
	j = 1
	highcontr = J(N, 1, 0)
	lowcontr = J(N, 1, 0)
	NUM = J(N,p,0)
	DEN = J(N,1,0)
	L = J(N,p,0)
	for (i=1;i<=N;i++) {
		while (ID[j] == i) {
			highcontr[i] = highcontr[i] + hold_high[j]
			lowcontr[i] = lowcontr[i] + hold_low[j]
			NUM[i,.] = NUM[i,.] + hold_num[j,.]
			DEN[i] = DEN[i] + hold_den[j]
			L[i,.] = L[i,.] + hold_L[j,.]
			j = j + 1
			if (j > rws) {
				j = 1
			}
		}
	}

    val = log(highcontr):*y_small + lowcontr

	if (todo >= 1) {

		DEN = DEN*J(1, cols(NUM), 1)
		H = NUM:/DEN

		grad = H - L

	}

}

end
