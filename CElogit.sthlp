{smcl}
{* *! version 0.1 4feb2022}{...}
{viewerdialog CElogit "dialog CElogit"}{...}
{viewerjumpto "Syntax" "CElogit##syntax"}{...}
{viewerjumpto "Menu" "CElogit##menu"}{...}
{viewerjumpto "Options" "CElogit##options"}{...}
{viewerjumpto "Postestimation" "CElogit##postestimation"}{...}
{viewerjumpto "Description" "CElogit##description"}{...}
{viewerjumpto "Examples" "CElogit##examples"}{...}
{viewerjumpto "Contact" "CElogit##contact"}{...}
{viewerjumpto "Guide" "CElogit##guide"}{...}
{viewerjumpto "Updates" "CElogit##updates"}{...}
{viewerjumpto "References" "CElogit##references"}{...}
{title: Title}

{p2col:{bf:CElogit}}Classification error model to analyze data from lying experiments


{marker syntax}{...}

{title:Syntax}

{p}

{cmd:CElogit} {depvar} [{indepvars}] [if]{cmd:,} {opt prdraw(stub)} {opt kstar(varname)} [{opt stake(stub)} {opt interact_gamma(varname)} {opt fast:reshape} {opt vce(vcetype)}]

{marker options}{...}

{title:Options}

{phang}{opt prdraw(stub)} is the stub for the drawing probability. If there are a maximum of {opt K} states then the data has to contain {opt K} variables from {opt stake1} to {opt stakeK}. Can contain missing values for observations in lying games with fewer than {opt K} states. Drawing probabilities can vary across observations.

{phang}{opt kstar(varname)} is a variable that determines the threshold state of the state space partition. Kstar can vary across observations.

{phang}{opt stake(stub)} is the stub for the stake variable. If there are a maximum of {opt K} states then the data has to contain {opt K} variables from {opt stake1} to {opt stakeK}. Can contain missing values for observations in lying games with fewer than {opt K} states. Stakes can vary across observations.

{phang}{opt interact_gamma(varname)} specifies a variable that is interacted with the stake variable. Requires that the stake variable is specified.

{phang}{opt fast:reshape} causes the command to use the {opt fastreshape} command when reshaping the data from wide to long (observationXstate level). This leads to substantial speed improvements when working with large data sets but requires that the {opt fastreshape} package is installed.

{phang}{opt vce(vcetype)} may be {opt robust} or {opt cluster}. The default is the homoskedastic logit error.


{marker postestimation}{...}
{title:Postestimation Syntax}

{pstd}

{cmd: test} and {cmd: estat summarize} work.

There also is the command {cmd:{help  CElogitmargins}} which calculates marginal effects and lying rates for a given set of estimates.

{cmd: suest} will return results but they will be incorrect. See the {browse "https://tilmanfries.gituhb.io": Github repository} for an example on how to obtain a joint variance-covariance matrix of differently specified CE models.

{marker description}{...}


{marker pitfalls}{...}
{title:Common pitfalls}

{pstd}

1. When using the {cmd: fastreshape} option, the command won't handle variable names that end with a number but are not part of a specified stub (like pdraw or stake) very well and might return an error.
In these cases, either rename the variables or do not use the {cmd: fastreshape} option.

{title:Description}

{pstd}

{cmd:CElogit} fits a logit model for a lying decision by maximum likelihood. It models the probability of lying given a set of regressors, a report variable, classification error probabilities, and a state space partition variable.


{marker examples}{...}

{title:Examples}

{hline}

{pstd}Setup using the Fischbacher and Föllmi-Heusi (2013) data.

{cmd:. use LiesInDisguise.dta}

{cmd:. keep if FirstParticipation == 1 & Baseline == 1}

{cmd:. gen report = StdPayoff + 1}

{pstd}Generate pdraw and stake variables.

{cmd:. forvalues p = 1 / 6 {c -(}}
    {cmd:2.     qui gen p_draw`p' = 1 / 6}
    {cmd:3.     qui gen stake`p' = 6 - `p' }
    {cmd:4. {c )-}}

{pstd}Choose a value for kstar.

{cmd:. gen kstar = 5}

{pstd}Estimation command

{cmd:. CElogit report GenderF, kstar(kstar) pdraw(p_draw) stake(stake)}

{hline}

{marker results}{...}
{title:Stored results}

{synoptset 24 tabbed}{...}
{syntab: Scalars}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(rank)}}rank of the X matrix{p_end}

{synoptset 24 tabbed}{...}
{syntab: Macros}
{synopt:{cmd:e(cmd)}}{cmd: CElogit}{p_end}
{synopt:{cmd:e(stake)}}name of stake variable stub{p_end}
{synopt:{cmd:e(kstar)}}name of kstar variable{p_end}
{synopt:{cmd:e(pdraw)}}name of pdraw variable stub{p_end}
{synopt:{cmd:e(indepvars)}}list of independent variables{p_end}
{synopt:{cmd:e(depvar)}}list of dependent variables{p_end}

{synoptset 24 tabbed}{...}
{syntab: Matrices}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}

{synoptset 24 tabbed}{...}
{syntab: Functions}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}


{marker contact}{...}
{title:Author}

{pstd}Timan Fries{break}
WZB Berlin Social Science Center{break}
Email: {browse "mailto:tilman.fries@wzb.eu":tilman.fries@wzb.eu}
{p_end}

{marker guide}{...}
{title:Guide}

A more detailed guide is included in the {browse "https://github.com/tilmanfries/CElogit":Github repository}. This includes examples and a link to the working paper.

{marker updates}{...}
{title:Updates}
Updates will appear and be able to download on the Github repository. Please write me an email if you find bugs or have ideas for additional features. You can also use the issue tracker on Github.

{marker references}{...}
{title:References}

{phang}
Michael Droste. "fastreshape". {browse "https://github.com/mdroste/stata-fastreshape":[link]}
{p_end}

{phang}
Urs Fischbacher and Franziska Föllmi-Heusi (2013). "Lies in Disguise-an Experimental Study on Cheating".
{it:Journal of the European Economic Association, 11, 525-547.}
{p_end}

{phang}
Tilman Fries (2022). "Estimating lies in lying experiments".
{it:mimeo.}
{browse "https://github.com/tilmanfries/CElogit":[link]}
{p_end}
