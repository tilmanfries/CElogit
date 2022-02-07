{smcl}
{* *! version 0.1 4feb2022}{...}
{viewerdialog CElogitmargins "dialog CElogitmargins"}{...}
{viewerjumpto "Syntax" "CElogitmargins##syntax"}{...}
{viewerjumpto "Menu" "CElogitmargins##menu"}{...}
{viewerjumpto "Options" "CElogitmargins##options"}{...}
{viewerjumpto "Postestimation" "CElogitmargins##postestimation"}{...}
{viewerjumpto "Description" "CElogitmargins##description"}{...}
{viewerjumpto "Examples" "CElogitmargins##examples"}{...}
{viewerjumpto "Contact" "CElogitmargins##contact"}{...}
{viewerjumpto "Guide" "CElogitmargins##guide"}{...}
{viewerjumpto "Updates" "CElogitmargins##updates"}{...}
{viewerjumpto "References" "CElogitmargins##references"}{...}
{title: Title}

{p2col:{bf:CElogitmargins}}Classification error model to analyze data from lying experiments


{marker syntax}{...}

{title:Syntax}

{p}

{cmd:CElogitmargins} [marginlist] [if]{cmd:,} [{opt binary(varlist)} {opt inc:ludestake} {opt fast:reshape} {opt post}]

where {it: marginlist} is a list of factor variables or interactions that appear in the current estimation results. If {it: marginlist} and {it: includestake} are not specified, the command will return an estimate of the average lying rate.

{marker options}{...}

{title:Options}

{phang}{opt binary(varlist)} specify variables for which the estimator should return the discrete marginal effect. I.e., if {it: x} is a dummy variable then specifying {cmd: binary(x)} will return the estimate of P(lie | x = 1) - P(lie | x = 0). Only works if the binary variable either takes on values 0 or 1. If not specified, then {cmd: CElogitmargins} will treat every variable as continuous and report the marginal effects based on the derivatives.

{phang}{opt includestake} return a marginal effect for the stake variable.

{phang}{opt fast:reshape} causes the command to use the {opt fastreshape} command when reshaping the data from wide to long (observationXstate level).
 This leads to substantial speed improvements when working with large data sets but requires that the {opt fastreshape} package is installed.

{phang}{opt post} post margins and their VCE as estimation results.


{marker description}{...}
{title:Description}

{pstd}

{cmd:CElogitmargins} calculates predictions from previously obtained {cmd:{help  CElogit}} estimation results. It predicts the average marginal effect or the average lying rate.


{marker examples}{...}

{title:Examples}

{hline}

{pstd} Return marginal effects for {it: GenderF} and {it: Stake}.

{cmd:. CElogitmargins GenderF, binary(GenderF) includestake}

{pstd} Predict the lying rate

{cmd:. CElogitmargins}

{hline}

{marker results}{...}
{title:Stored results}

{cmd: CElogitmargins} with the {cmd: post} option stores the following in {cmd: e()}:

{synoptset 24 tabbed}{...}
{syntab: Scalars}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(rank)}}rank of the X matrix{p_end}

{synoptset 24 tabbed}{...}
{syntab: Macros}
{synopt:{cmd:e(cmd)}}{cmd: CElogitmargins}{p_end}
{synopt:{cmd:e(stake)}}name of stake variable stub{p_end}
{synopt:{cmd:e(kstar)}}name of kstar variable{p_end}
{synopt:{cmd:e(pdraw)}}name of pdraw variable stub{p_end}
{synopt:{cmd:e(indepvars)}}list of independent variables{p_end}
{synopt:{cmd:e(depvar)}}list of dependent variables{p_end}

{synoptset 24 tabbed}{...}
{syntab: Matrices}
{synopt:{cmd:e(b)}}coefficient vector of the marginal effects{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the marginal effects{p_end}

{marker contact}{...}
{title:Author}

{pstd}Timan Fries{break}
WZB Berlin Social Science Center{break}
Email: {browse "mailto:tilman.fries@wzb.eu":tilman.fries@wzb.eu}
{p_end}

{marker guide}{...}
{title:Guide}

A more detailed guide is included in the {browse "https://https://github.com/tilmanfries/CElogit":Github repository}. This includes examples and a link to the working paper.

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
