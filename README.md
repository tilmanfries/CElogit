
CElogit
=================================

[Overview](#overview)
| [Installation](#installation)
| [Usage](#usage)
| [Examples](#examples)
| [Further reading](#further-reading)

Take care of the classification error when analyzing data from your lying experiment.

`version 0.1 04feb2022`


Overview
---------------------------------

CElogit is a Stata command that can be used to analyze data from lying experiments where participants roll dice, toss coins or draw from urns.

The command estimates a discrete choice model of the lying rate for a given set of independent variables. A full description of the model and applications are in the [working paper](https://tilmanfries.github.io/PAPER).

I experimented in earlier stages with implementing the model in python. Contact me if you are interested in the python code.

Installation
---------------------------------

The most recent version can be installed from Github with the following Stata command:

```stata
net install CElogit, from("https://raw.githubusercontent.com/tilmanfries/CElogit/master/")
```

Usage
---------------------------------

Documentation for CElogit is available in Stata after installation:
```stata
help CElogit
```

The postestimation command CElogitmargins can be used to calculate marginal effects and predict lying rates:
```stata
help CElogitmargins
```

Examples
---------------------------------
The following example uses data from Fischbacher and Föllmi-Heusi (2013). "Lies in Disguise -- A Theoretical Analysis of Cheating," *Journal of the European Economic Association*, 11, 525-547. The data can be downloaded from the [journal homepage](https://doi.org/10.1111/jeea.12014).

```stata
clear
use LiesInDisguise.dta

* Keep only the data from the BASELINE treatment
keep if FirstParticipation == 1 & Baseline == 1

* Rescale the report variables
gen report = StdPayoff + 1

/* Create the draw probability variable and the stakes variable.
These have to be of a format stub + `p', where `p' goes from
1 - 6. */
forvalues p = 1 / 6 {
    qui gen p_draw`p' = 1 / 6
    qui gen stake`p' = 6 - `p'
}

* Estimate CE model for kstar = 5.
gen kstar = 5
CElogit report GenderF, kstar(kstar) pdraw(p_draw) stake(stake)

/* The following command returns marginal effects.
There are two ways of calculating marg. effects; either
continuously or discretely. The command calculates continuous marg.
effects as a default. To obtain appropriate marg. effects for
binary variables, use the binary() option. Including the stake option
will display the marginal effect of the stake variable in the output.*/
CElogitmargins GenderF, binary(GenderF) includestake

* To obtain the estimated lying rate type the previous command without any options.
CElogitmargins
```

Here's an additional example of how to test whether models with different state partitions generate different estimates. This is equal to what Stata's suest command does to combine estimation results from different models. See Example 3 in the [suest manual](https://www.stata.com/manuals13/rsuest.pdf) for an explanation of the rationale behind the stacking approach implemented below.

```stata
/* To test whether the kstar = 5 model is different from the kstar = 3 model, we
have to estimate a joint covariance matrix of the coefficient estimates.
The code below implements this */
* Two alternative kstar to compare
rename kstar kstarA
gen kstarB = 3

* Duplicate the sample and assign the duplicates the alternative kstar parameter.

** Sample indicators (whether duplicate or not)
gen zero = 0
gen modelB = 1

** Unique ID for each observation
gen id = _n

stack id report GenderF zero kstarA zero p_draw* stake* id report zero GenderF kstarB modelB p_draw* stake*, into(id report GenderFA GenderFB kstar modelB p_draw1-p_draw6 stake1-stake6) clear

/* Estimate the CElogit models on both samples and including Model B interaction terms for
each variable (note that we include the stake interaction through the interact_gamma() option).
Cluster on the id level to account for the duplicated observations.*/
CElogit report GenderFA GenderFB modelB, kstar(kstar) pdraw(p_draw) stake(stake) interact_gamma(modelB) vce(cluster id)

* Test whether coefficients are jointly different.
test (_b[GenderFA] = _b[GenderFB]) (_b[Interaction] = 0) (_b[model]=0)
```

Further reading
---------------------------------

This program builds on the experimental economic literature on lying games. For an introduction, see [preferencesfortruthtelling.com](http://www.preferencesfortruthtelling.com/).

For more background on the estimator and further references and acknowledgements, see the [working paper](https://tilmanfries.github.io/PAPER).
