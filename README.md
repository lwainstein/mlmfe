
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mlmfe

Please contact Leonard Wainstein (<lwainstein@reed.edu>) with questions.

## Overview

The `mlmfe` package implements bias-corrected multilevel models (bcMLM),
fixed effects models (FE), regularized fixed effects models (RegFE), and
bias-corrected RegFE models (bcRegFE) as recommended by [Bai et
al. (2025)](https://arxiv.org/abs/2411.01723) and [Hazlett and Wainstein
(2022)](https://www.cambridge.org/core/journals/political-analysis/article/understanding-choosing-and-unifying-multilevel-and-fixed-effect-approaches/8101D49CFD3B129F5753FC878F416980).

To demonstrate the functions included in `mlmfe`, we provide the
following tutorial through an application to a simulated, mock dataset
that is included in the `mlmfe` package. While the data is simulated, it
is meant to mimic the setting and certain characteristics of the data
analyzed by [Wainstein et
al. (2023a)](https://laeri.luskin.ucla.edu/12thgrademathandcollegeaccess/)
and [Wainstein et
al. (2023b)](https://laeri.luskin.ucla.edu/12thgrademathandcollegesuccess/),
for the [Los Angeles Education Research Institute
(LAERI)](https://laeri.luskin.ucla.edu/) at the University of California
Los Angeles, who investigated the effects of taking math in 12th grade
on end-of-high school and college outcomes in the Los Angeles Unified
School District. This real data will be re-analyzed by [Bai et
al. (2025)](https://arxiv.org/abs/2411.01723) in an upcoming version of
their paper, and this README is meant to replicate their re-analysis on
simulated, mock data.

Finally, note that the `mlmfe` package **currently** only allows for
two-level models.

## Installation

You can install the development version of `mlmfe` from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("lwainstein/mlmfe")
```

## Data

One can access the data for this README through the `mlmfe` package
with:

``` r
data(mockmath12th) 
```

Taking a look at the data,

``` r
dplyr::glimpse(mockmath12th) # To read more about the dataset, type help(mockmath12th) into the R Console.
#> Rows: 11,255
#> Columns: 10
#> $ finalgpa  <dbl> 2.2488510, 2.4810441, 3.1219463, 3.9899728, 2.9247080, 2.0874022, 2.7670754, 2.2226965, 3.5390010, 2.8936590, 3.5474459, 4.0000000, 3.5133363, 2.4148894, 3.4766464, 2.4449963, 3.3842441, 2.8980572, 1.8045990, 2.9095281, 2.9448330, 2.4005647, 2.6768323, 2.8334415, 2.3919194, 2.879…
#> $ cenrl     <dbl> 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1…
#> $ ccred     <dbl> NA, 20, 60, 68, 18, 14, 36, 13, 24, 19, NA, 83, 27, 15, 60, 19, 38, 35, NA, 42, NA, 19, NA, 43, 25, 15, 17, 24, 18, NA, 45, 13, 29, NA, 35, 41, 17, NA, 44, 35, 53, NA, 27, 30, 40, 18, NA, NA, 39, 4, 20, 27, 16, 46, 21, 37, NA, 66, 14, 23, 23, 26, 36, NA, NA, 13, 22, 18, 33, 12, 2…
#> $ tookmath  <dbl> 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0, 1, 1…
#> $ school    <int> 75, 113, 73, 158, 90, 164, 33, 107, 15, 12, 187, 68, 156, 188, 106, 186, 108, 152, 75, 105, 150, 147, 44, 73, 68, 43, 149, 166, 155, 31, 189, 63, 110, 189, 72, 144, 116, 187, 132, 28, 193, 54, 20, 8, 5, 162, 155, 194, 173, 111, 157, 125, 184, 58, 30, 4, 172, 80, 68, 81, 139, 170,…
#> $ female    <dbl> 1, 1, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 1, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0…
#> $ ethnic    <fct> Latinx, White, Latinx, Latinx, Latinx, Latinx, White, White, Black, Black, Latinx, Latinx, Filipinx, Latinx, Latinx, Black, Latinx, Latinx, Latinx, Latinx, Latinx, Latinx, Latinx, Latinx, Latinx, Filipinx, Latinx, Latinx, Latinx, Latinx, Latinx, Latinx, Latinx, Latinx, Latinx, Bl…
#> $ frl       <dbl> 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1…
#> $ mathtestz <dbl> -0.78144596, -0.65213864, 1.09783569, 1.86269363, -0.24644745, -1.18829270, 0.32808864, -1.34149642, 0.71076348, 0.24375328, 0.94662812, 1.44564484, 0.66861975, -0.69281161, 1.22440563, -1.22194891, 0.90335300, 0.90495773, -2.21392643, 0.09545605, 1.29191537, -0.96813825, -0.9595…
#> $ gpa11th   <dbl> 2.2859707, 2.4788350, 3.0643559, 4.0000000, 3.0077438, 2.1144375, 2.7640683, 2.2627364, 3.5747922, 3.0026133, 3.6588816, 4.0000000, 3.5558473, 2.4256267, 3.4646420, 2.4354599, 3.3706793, 2.9238788, 1.8885046, 2.8947612, 3.0383945, 2.4566534, 2.7130895, 2.8447658, 2.3585124, 2.936…
```

we see the data has 11,225 rows (which represent students) and 10
columns:

-   `finalgpa` (Outcome variable): Cumulative GPA at the end of high
    school.
-   `cenrl` (Outcome variable): Whether or not student enrolled in a
    two-year or four-year college within one year of highschool
    graduation (1=yes, 0=no).
-   `ccred` (Outcome variable): Number of credits accumulated in college
    after two years. Is `NA` if `cenrl=0`.
-   `tookmath` (Treatment variable): Whether or not student took math in
    12th grade (1=yes, 0=no).
-   `school` (Covariate): School student attended (numbered 1-200).
-   `female` (Covariate): Whether or not student is female (1=yes,
    0=no).
-   `ethnic` (Covariate): Race/Ethnicity of the student.
-   `frl` (Covariate): Whether or not student qualifies for free or
    reducted price lunch (1=yes, 0=no).
-   `gpa11th` (Covariate): Cumulative GPA at the end of 11th grade.
-   `mathtestz` (Covariate): Math standardized test score (Z-Score).

In this applied example, we will use the modeling functions in the
`mlmfe` package to estimate the effect of taking math in 12th grade
(`tookmath`) on three outcomes: (1) cumulative GPA at the end of high
school (`finalgpa`); (2) whether or not a student enrolled in a two-year
or four-year college within one year of high school graduation
(`cenrl`); and (3) number of credits accumulated in college after two
years (`ccred`). In the data generating process for the simulated
`mockmath12th` data, whether or not a student takes math in 12th grade
depends heavily on what school the student goes to (e.g., perhaps
certain schools offer more math classes than others) and students’
grades and math skills. Thus, when teasing out the relationships between
12th grade math and the outcomes here, it will be key to account for
student characteristics (`female`, `ethnic`, `frl`, `gpa11th`, and
`mathtestz`) and school (`school`) in our models for the outcomes. (Note
that the simulated demographic variables (gender, race/ethnicity, and a
free or reduced-price lunch indicator) were generated completely at
random, and do *not* have any relationship with other variables in the
data (e.g., the outcomes, math course-taking, school, or academic
achievement) — these demographic variables are included purely to
simulate the experience of working with an education-related dataset, as
these variables are often information collected on students.)

## Functions

The `mlmfe` package has four modeling functions:

-   `bcmlm()`: Bias-corrected multilevel models (bcMLM)

-   `fe()`: Fixed effects models (FE)

-   `regfe()`: Regularized fixed effects models (RegFE)

-   `bcregfe()`: Bias-corrected regularized fixed effects models
    (bcRegFE)

At a minimum, these functions require (i) a dataset to analyze, and (ii)
an `R` formula in the style of the
[`lme4`](https://cran.r-project.org/web/packages/lme4/index.html)
package, which implements multilevel models (the `bcmlm()`, `regfe()`,
and `bcregfe()` functions in `mlmfe` all rely on the `lme4` package to
fit (preliminary) multilevel models). For example, the following code
creates a linear bcMLM for `finalgpa`:

``` r
model <- bcmlm(
  formula = finalgpa ~ tookmath + female + ethnic + frl + mathtestz + gpa11th +  (1 | school), 
  data = mockmath12th
)
```

In the above code, the formula
`finalgpa ~ tookmath + female + ethnic + frl + mathtestz + gpa11th +  (1 | school)`
indicates that:

-   The outcome variable is `finalgpa`.

-   The regressors are `tookmath`, `female`, `ethnic`, `frl`,
    `mathtestz`, and `gpa11th`.

-   By specifying `+ (1 | school)`, we are allowing varying intercepts
    (`1`) by `school`. Were we to include, for example, a varying slope
    for `mathtestz`, we would instead specify
    `+ (1 + mathtestz | school)`.

By default, the modeling functions in the `mlmfe` package produce linear
models. However, this can be changed by specifying the `family` argument
for `bcmlm()` and `fe()`, and the `regression_type` argument for
`regfe()` and `bcregfe()`. The `bcmlm()` and `fe()` functions also allow
for different methods of estimating standard errors for the model, by
specifying the `inference` argument. The `regfe()` and `bcregfe()`
functions only allow for cluster-robust standard errors, as described in
[Bai et al. (2025)](https://arxiv.org/abs/2411.01723).

We demonstrate these functions below, but note that `help()` files are
also available for these functions with:

``` r
help(bcmlm)
help(fe)
help(regfe)
help(bcregfe)
```

### Outcome 1: `finalgpa`

We first investigate the relationship, in this simulated dataset,
between 12th grade math course-taking (`tookmath`) and cumulative GPA at
the end of high school (`finalgpa`). Because `finalgpa` is a continuous
variable (taking any value from 0-4), we will use linear models for this
outcome.

We first estimate a bcMLM using the `bcmlm()` function, and estimate
standard errors with cluster-robust standard errors by setting
`inference="crse"`:

``` r
bcmlm_model <- bcmlm(
  formula = finalgpa ~ tookmath + female + ethnic + frl + mathtestz + gpa11th +  (1 | school), 
  data = mockmath12th,
  inference = "crse"
)
```

We can view the estimated coefficients, along with their estimated
standard errors and p-values, with:

``` r
bcmlm_model$coefficients
#>                                Estimate   Std. Error       z value  Pr(>|z|)
#> (Intercept)               -3.829731e-02 0.1276437823 -3.000327e-01 0.7641522
#> tookmath                  -4.026517e-02 0.0004661047 -8.638654e+01 0.0000000
#> female                    -2.517498e-04 0.0004043383 -6.226217e-01 0.5335331
#> ethnicBlack                1.211594e-05 0.0010741529  1.127953e-02 0.9910004
#> ethnicFilipinx            -1.096291e-05 0.0014307507 -7.662346e-03 0.9938864
#> ethnicLatinx               5.945592e-04 0.0009332726  6.370691e-01 0.5240798
#> ethnicWhite                1.450885e-03 0.0011199088  1.295539e+00 0.1951344
#> ethnicOther                2.840469e-04 0.0023197023  1.224497e-01 0.9025429
#> frl                       -4.008110e-05 0.0007487122 -5.353340e-02 0.9573069
#> mathtestz                  1.902827e-04 0.0004100746  4.640197e-01 0.6426336
#> gpa11th                    9.991053e-01 0.0007478910  1.335897e+03 0.0000000
#> tookmath_schoolmean        2.426230e-01 0.0104679587  2.317768e+01 0.0000000
#> female_schoolmean          4.452863e-03 0.0268974833  1.655494e-01 0.8685115
#> ethnicBlack_schoolmean     1.239181e-02 0.0626631312  1.977527e-01 0.8432385
#> ethnicFilipinx_schoolmean -3.395557e-02 0.0713793536 -4.757057e-01 0.6342841
#> ethnicLatinx_schoolmean   -1.766741e-02 0.0576859655 -3.062688e-01 0.7594000
#> ethnicWhite_schoolmean     2.995864e-02 0.0554105722  5.406666e-01 0.5887374
#> ethnicOther_schoolmean    -1.425896e-01 0.1173221787 -1.215368e+00 0.2242259
#> frl_schoolmean             1.728751e-02 0.0406589880  4.251829e-01 0.6707034
#> mathtestz_schoolmean      -1.510763e-02 0.0208847268 -7.233818e-01 0.4694454
#> gpa11th_schoolmean        -4.407785e-02 0.0345639253 -1.275256e+00 0.2022187
```

The bcMLM estimates that, in this mock setting, taking math in 12th
grade decreases one’s cumulative end-of-high school GPA by about -0.04
GPA points, on average. (This is about what [Wainstein et
al. (2023a)](https://laeri.luskin.ucla.edu/12thgrademathandcollegeaccess/)
estimated in their real setting for a subset of the students they
examined.) Additionally, this estimate is statistically significant at
many of the usual thresholds (e.g., 0.05, 0.01, and 0.001), with a
minuscule p-value.

Note that the `bcmlm()` function has created extra regressors than were
specified in the formula for the function call: the variables with the
suffix `_schoolmean`. Because the bcMLM only has school-varying
intercepts, these new variables are the school-level averages of *all*
the original regressors (including the required indicator variables
needed for the `ethnic` categorical/factor variable). Were one to
implement bcMLM from scratch with the `lme4` package, one would need to
create these variables themselves, like so:

``` r
# Read in the "dplyr" package -- we will use it to wrangle the data
library(dplyr)

# First make race/ethnicity indicator variables, and start a new dataset: data_new
data_new <- mockmath12th %>%
  mutate(
    ethnicBlack = 1*(ethnic=="Black"),
    ethnicFilipinx = 1*(ethnic=="Filipinx"),
    ethnicLatinx = 1*(ethnic=="Latinx"),
    ethnicWhite = 1*(ethnic=="White"),
    ethnicOther = 1*(ethnic=="Other"),
  ) # Here, Asian is the "held out" group for the indicator variables.

# Calculate school-level averages, and add them to data_new
school_means <- data_new %>%
  group_by(school) %>%
  summarize(
    tookmath_schoolmean = mean(tookmath),
    female_schoolmean = mean(female),
    ethnicBlack_schoolmean = mean(ethnicBlack),
    ethnicFilipinx_schoolmean = mean(ethnicFilipinx),
    ethnicLatinx_schoolmean = mean(ethnicLatinx),
    ethnicWhite_schoolmean = mean(ethnicWhite),
    ethnicOther_schoolmean = mean(ethnicOther),
    frl_schoolmean = mean(frl),
    mathtestz_schoolmean = mean(mathtestz),
    gpa11th_schoolmean = mean(gpa11th)
  )
data_new <- merge(data_new, school_means)
  
# Fit model with lme4
manual_bcmlm <- lmer(
  formula = finalgpa ~ tookmath + female + ethnic + frl + mathtestz + gpa11th +  tookmath_schoolmean + female_schoolmean + ethnicBlack_schoolmean + ethnicFilipinx_schoolmean + ethnicLatinx_schoolmean + ethnicWhite_schoolmean + ethnicOther_schoolmean + frl_schoolmean + mathtestz_schoolmean + gpa11th_schoolmean + (1 | school),
  data = data_new
)
```

We can see that the coefficient estimates from `manual_bcmlm` are
exactly the same as from the `bcmlm()` function:

``` r
comparison <- cbind(
  bcmlm_model$coefficients[, "Estimate"], 
  summary(manual_bcmlm)$coefficients[, "Estimate"]
)
colnames(comparison) <- c("bcMLM - function", "bcMLM - manual")
comparison
#>                           bcMLM - function bcMLM - manual
#> (Intercept)                  -3.829731e-02  -3.829730e-02
#> tookmath                     -4.026517e-02  -4.026517e-02
#> female                       -2.517498e-04  -2.517498e-04
#> ethnicBlack                   1.211594e-05   1.211594e-05
#> ethnicFilipinx               -1.096291e-05  -1.096291e-05
#> ethnicLatinx                  5.945592e-04   5.945592e-04
#> ethnicWhite                   1.450885e-03   1.450885e-03
#> ethnicOther                   2.840469e-04   2.840469e-04
#> frl                          -4.008110e-05  -4.008110e-05
#> mathtestz                     1.902827e-04   1.902827e-04
#> gpa11th                       9.991053e-01   9.991053e-01
#> tookmath_schoolmean           2.426230e-01   2.426230e-01
#> female_schoolmean             4.452863e-03   4.452863e-03
#> ethnicBlack_schoolmean        1.239181e-02   1.239181e-02
#> ethnicFilipinx_schoolmean    -3.395557e-02  -3.395557e-02
#> ethnicLatinx_schoolmean      -1.766741e-02  -1.766741e-02
#> ethnicWhite_schoolmean        2.995864e-02   2.995864e-02
#> ethnicOther_schoolmean       -1.425896e-01  -1.425896e-01
#> frl_schoolmean                1.728751e-02   1.728750e-02
#> mathtestz_schoolmean         -1.510763e-02  -1.510763e-02
#> gpa11th_schoolmean           -4.407785e-02  -4.407785e-02
```

However, fitting the model by scratch is much more work! And this gets
more complicated with more school-varying coefficients (see [Bai et
al. (2025)](https://arxiv.org/abs/2411.01723) and [Hazlett and Wainstein
(2022)](https://www.cambridge.org/core/journals/political-analysis/article/understanding-choosing-and-unifying-multilevel-and-fixed-effect-approaches/8101D49CFD3B129F5753FC878F416980)).
Meanwhile, with `bcmlm()`, these are automatically added. For example,
the following function call creates a bcMLM with school-varying
intercepts *and* slopes for `mathtestz`:

``` r
bcmlm_model_slopes <- bcmlm(
  formula = finalgpa ~ tookmath + female + ethnic + frl + mathtestz + gpa11th + (1 + mathtestz | school), 
  data = mockmath12th,
  inference = "crse"
)
#> boundary (singular) fit: see help('isSingular')
bcmlm_model_slopes$coefficients
#>                           Estimate   Std. Error      z value     Pr(>|z|)
#> (Intercept)          -0.0063893019 0.0164926083   -0.3874040 6.984572e-01
#> tookmath             -0.0404589433 0.0004768516  -84.8459835 0.000000e+00
#> female               -0.0004077732 0.0004103131   -0.9938099 3.203154e-01
#> ethnicBlack           0.0001611344 0.0010842529    0.1486133 8.818588e-01
#> ethnicFilipinx        0.0002881072 0.0014510539    0.1985503 8.426145e-01
#> ethnicLatinx          0.0006769787 0.0009398126    0.7203337 4.713195e-01
#> ethnicWhite           0.0014289792 0.0011364358    1.2574218 2.086009e-01
#> ethnicOther           0.0008301621 0.0023082564    0.3596490 7.191096e-01
#> frl                  -0.0002496998 0.0007639108   -0.3268704 7.437659e-01
#> mathtestz            -0.0011953159 0.0023696016   -0.5044375 6.139540e-01
#> gpa11th               0.9991756983 0.0007639374 1307.9287643 0.000000e+00
#> tookmath_tilde        0.0119620042 0.0029651711    4.0341700 5.479564e-05
#> female_tilde          0.0092503540 0.0034574038    2.6755203 7.461336e-03
#> ethnicBlack_tilde    -0.0123158415 0.0071657199   -1.7187166 8.566599e-02
#> ethnicFilipinx_tilde -0.0182673466 0.0100675462   -1.8144785 6.960408e-02
#> ethnicLatinx_tilde   -0.0082405440 0.0068661205   -1.2001747 2.300715e-01
#> ethnicWhite_tilde    -0.0021764423 0.0082482045   -0.2638686 7.918812e-01
#> ethnicOther_tilde    -0.0305420708 0.0225992985   -1.3514610 1.765478e-01
#> frl_tilde             0.0084877010 0.0055240585    1.5364973 1.244165e-01
#> gpa11th_tilde        -0.0011525044 0.0050334514   -0.2289690 8.188930e-01
```

Here, the added variables are the variables with the `_tilde` suffix,
echoing the notation in [Bai et
al. (2025)](https://arxiv.org/abs/2411.01723) and [Hazlett and Wainstein
(2022)](https://www.cambridge.org/core/journals/political-analysis/article/understanding-choosing-and-unifying-multilevel-and-fixed-effect-approaches/8101D49CFD3B129F5753FC878F416980).

Finally, as [Hazlett and Wainstein
(2022)](https://www.cambridge.org/core/journals/political-analysis/article/understanding-choosing-and-unifying-multilevel-and-fixed-effect-approaches/8101D49CFD3B129F5753FC878F416980)
note, for linear models, the coefficient estimates and cluster-robust
standard errors from a bcMLM and the corresponding FE model should
coincide. To confirm this, we estimate a FE model with the `fe()`
function:

``` r
fe_model <- fe(
  formula = finalgpa ~ tookmath + female + ethnic + frl + mathtestz + gpa11th +  (1 | school), 
  data = mockmath12th,
  inference = "crse"
)
```

As expected, we see that the models’ coefficients (that they share) are
exactly equal:

``` r
coef_comparison <- as.matrix(bcmlm_model$coefficients[, "Estimate"])
coef_comparison <- cbind(
  coef_comparison, 
  (fe_model$coefficients[, "Estimate"])[names(bcmlm_model$coefficients[, "Estimate"])]
)
colnames(coef_comparison) <- c("bcMLM", "FE")
coef_comparison
#>                                   bcMLM            FE
#> (Intercept)               -3.829731e-02            NA
#> tookmath                  -4.026517e-02 -4.026517e-02
#> female                    -2.517498e-04 -2.517498e-04
#> ethnicBlack                1.211594e-05  1.211594e-05
#> ethnicFilipinx            -1.096291e-05 -1.096291e-05
#> ethnicLatinx               5.945592e-04  5.945592e-04
#> ethnicWhite                1.450885e-03  1.450885e-03
#> ethnicOther                2.840469e-04  2.840469e-04
#> frl                       -4.008110e-05 -4.008110e-05
#> mathtestz                  1.902827e-04  1.902827e-04
#> gpa11th                    9.991053e-01  9.991053e-01
#> tookmath_schoolmean        2.426230e-01            NA
#> female_schoolmean          4.452863e-03            NA
#> ethnicBlack_schoolmean     1.239181e-02            NA
#> ethnicFilipinx_schoolmean -3.395557e-02            NA
#> ethnicLatinx_schoolmean   -1.766741e-02            NA
#> ethnicWhite_schoolmean     2.995864e-02            NA
#> ethnicOther_schoolmean    -1.425896e-01            NA
#> frl_schoolmean             1.728751e-02            NA
#> mathtestz_schoolmean      -1.510763e-02            NA
#> gpa11th_schoolmean        -4.407785e-02            NA
```

as are the cluster-robust standard errors:

``` r
se_comparison <- as.matrix(bcmlm_model$coefficients[, "Std. Error"])
se_comparison <- cbind(
  se_comparison, 
  (fe_model$coefficients[, "Std. Error"])[names(bcmlm_model$coefficients[, "Std. Error"])]
)
colnames(se_comparison) <- c("bcMLM", "FE")
se_comparison
#>                                  bcMLM           FE
#> (Intercept)               0.1276437823           NA
#> tookmath                  0.0004661047 0.0004661047
#> female                    0.0004043383 0.0004043383
#> ethnicBlack               0.0010741529 0.0010741529
#> ethnicFilipinx            0.0014307507 0.0014307507
#> ethnicLatinx              0.0009332726 0.0009332726
#> ethnicWhite               0.0011199088 0.0011199088
#> ethnicOther               0.0023197023 0.0023197023
#> frl                       0.0007487122 0.0007487122
#> mathtestz                 0.0004100746 0.0004100746
#> gpa11th                   0.0007478910 0.0007478910
#> tookmath_schoolmean       0.0104679587           NA
#> female_schoolmean         0.0268974833           NA
#> ethnicBlack_schoolmean    0.0626631312           NA
#> ethnicFilipinx_schoolmean 0.0713793536           NA
#> ethnicLatinx_schoolmean   0.0576859655           NA
#> ethnicWhite_schoolmean    0.0554105722           NA
#> ethnicOther_schoolmean    0.1173221787           NA
#> frl_schoolmean            0.0406589880           NA
#> mathtestz_schoolmean      0.0208847268           NA
#> gpa11th_schoolmean        0.0345639253           NA
```

### Outcome 2: `cenrl`

Next, we investigate the relationship, in this simulated dataset,
between `tookmath` and enrolling in a 2-year or 4-year college within
one year of graduating high school (`cenrl`). Because `cenrl` is a
binary variable (0=no, 1=yes), we use logistic regression for this
outcome. We compare results across five models:

-   FE, with `fe()`

-   bcMLM, with `bcmlm()`

-   bcRegFE, with `bcregfe()`

-   RegFE, with `regfe()`

-   Uncorrected multilevel model (MLM), with `glmer()` from the `lme4`
    package

Because `school` influences both `tookmath` and the outcomes, we should
expect that the uncorrected RegFE model and the uncorrected MLM should
show bias, even in a finite sample. Meanwhile FE, bcMLM, and bcRegFE
should be closer to the truth.

We fit the FE and bcMLM logistic regression models similarly to how the
linear models were fit for the `finalgpa` outcome, except we now specify
`family = binomial(link="logit")`:

``` r
bcmlm_model <- bcmlm(
  formula = cenrl ~ tookmath + female + ethnic + frl + mathtestz + gpa11th +  (1 | school), 
  data = mockmath12th,
  family = binomial(link="logit"),
  inference = "boot",
  B=200
)
fe_model <- fe(
  formula = cenrl ~ tookmath + female + ethnic + frl + mathtestz + gpa11th +  (1 | school), 
  data = mockmath12th,
  family = binomial(link="logit"),
  inference = "crse"
)
```

We apply a cluster bootstrap (with `B=200` bootstrap samples) for
inference with the bcMLM (with `inference="boot"`) and cluster-robust
standard errors for the FE model (`inference="crse"`). To fit the RegFE
and bcRegFE models, we run:

``` r
bcregfe_model <- bcregfe(
  formula = cenrl ~ tookmath + female + ethnic + frl + mathtestz + gpa11th +  (1 | school), 
  data = mockmath12th,
  regression_type = "logistic"
)
regfe_model <- regfe(
  formula = cenrl ~ tookmath + female + ethnic + frl + mathtestz + gpa11th +  (1 | school), 
  data = mockmath12th,
  regression_type = "logistic"
)
```

Note that we specify logistic regression with
`regression_type = "logistic"` with both `regfe()` and `bcregfe()`. By
default, these functions apply cluster-robust standard errors for
inference. Finally, we can fit the uncorrected MLM with:

``` r
mlm_model <- glmer( # from lme4
  formula = cenrl ~ tookmath + female + ethnic + frl + mathtestz + gpa11th +  (1 | school), 
  data = mockmath12th,
  family = binomial(link="logit")
)
```

Below is a table that compares the estimated coefficients from each
model, where double stars (\*\*) indicate statistical significance at
the 0.05 level:

    #>                                          FE              bcMLM            bcRegFE                MLM              RegFE
    #> (Intercept)                            <NA> -8.9199** (3.5038) -8.9136** (2.4281) -1.1610** (0.3281) -1.1583** (0.3533)
    #> tookmath                  0.3731** (0.0576)  0.3667** (0.0587)  0.3629** (0.0561)  0.4697** (0.0581)  0.4589** (0.0555)
    #> female                     -0.0402 (0.0661)   -0.0385 (0.0542)   -0.0378 (0.0646)   -0.0388 (0.0540)   -0.0375 (0.0639)
    #> ethnicBlack                -0.0814 (0.1655)   -0.0823 (0.1553)   -0.0809 (0.1606)   -0.0615 (0.1549)   -0.0619 (0.1601)
    #> ethnicFilipinx              0.1096 (0.2069)    0.1116 (0.1928)    0.1119 (0.2016)    0.1215 (0.1920)    0.1179 (0.1992)
    #> ethnicLatinx               -0.0056 (0.1442)   -0.0096 (0.1262)   -0.0086 (0.1405)    0.0029 (0.1258)    0.0016 (0.1394)
    #> ethnicWhite                -0.0245 (0.1577)   -0.0249 (0.1568)   -0.0236 (0.1540)   -0.0200 (0.1561)   -0.0205 (0.1526)
    #> ethnicOther                 0.2936 (0.3187)    0.2418 (0.3636)    0.2418 (0.3118)    0.2766 (0.3624)    0.2726 (0.3079)
    #> frl                        -0.0177 (0.1098)   -0.0221 (0.1007)   -0.0218 (0.1081)   -0.0038 (0.1002)   -0.0043 (0.1066)
    #> mathtestz                 0.5518** (0.0582)  0.5378** (0.0558)  0.5331** (0.0565)  0.5161** (0.0554)  0.5084** (0.0560)
    #> gpa11th                   0.9736** (0.1025)  0.9461** (0.0986)  0.9362** (0.1004)  0.9503** (0.0982)  0.9346** (0.0995)
    #> tookmath_schoolmean                    <NA>  5.0598** (0.2651)  4.9916** (0.1367)               <NA>               <NA>
    #> female_schoolmean                      <NA>    0.1963 (0.5753)    0.1962 (0.4550)               <NA>               <NA>
    #> ethnicBlack_schoolmean                 <NA>    1.7093 (1.6816)    1.7349 (0.9339)               <NA>               <NA>
    #> ethnicFilipinx_schoolmean              <NA>   -0.2656 (1.8133)   -0.2417 (1.0565)               <NA>               <NA>
    #> ethnicLatinx_schoolmean                <NA>    1.2349 (1.3284)    1.2512 (0.8515)               <NA>               <NA>
    #> ethnicWhite_schoolmean                 <NA>    2.6103 (1.6176)  2.6183** (0.9597)               <NA>               <NA>
    #> ethnicOther_schoolmean                 <NA>   -0.7961 (3.6700)   -0.7674 (1.9373)               <NA>               <NA>
    #> frl_schoolmean                         <NA>    0.8117 (1.0110)    0.8288 (0.6698)               <NA>               <NA>
    #> mathtestz_schoolmean                   <NA> -1.2707** (0.5531) -1.2654** (0.3761)               <NA>               <NA>
    #> gpa11th_schoolmean                     <NA>    0.8228 (1.0254)    0.8279 (0.7280)               <NA>               <NA>

All models estimate that `tookmath` has a positive, and statistically
significant, relationship with `cenrl`. The FE, bcMLM, and bcRegFE
models all produce similar coefficients and standard errors. However,
the RegFE and uncorrected MLM produce noticeably larger estimates. In
fact, because the data is simulated, the true coefficient on `tookmath`
is known, and is 0.375, which MLM and RegFE are much further from (i.e.,
are more biased) than are FE, bcMLM, and bcRegFE. (The coefficient of
0.375 was chosen because it results in an effect of 12th grade math
course-taking of about +4.9 percentage points more likely to enroll in
college, as was estimated by [Wainstein et
al. (2023a)](https://laeri.luskin.ucla.edu/12thgrademathandcollegeaccess/)
for a subset of students in their real study.)

### Outcome 3: `ccred`

Next, we investigate the relationship, in this mock dataset, between
`tookmath` and college credits accumulated two years into college
(`ccred`). Because `cenrl` is a count variable here, only taking
positive integer values, we will use poisson regression for this
outcome. We again compare results across five models:

-   FE, with `fe()`

-   bcMLM, with `bcmlm()`

-   bcRegFE, with `bcregfe()`

-   RegFE, with `regfe()`

-   Uncorrected multilevel model (MLM), with `glmer()` from the `lme4`
    package

The following code runs these models, requiring changes to the `family`
argument for `bcmlm()`, `fe()`, and `glmer()` (from `lme4`), and the
`regression_type` argument for `regfe()` and `bcregfe()`:

``` r
bcmlm_model <- bcmlm(
  formula = ccred ~ tookmath + female + ethnic + frl + mathtestz + gpa11th +  (1 | school), 
  data = mockmath12th,
  family = poisson(link="log"),
  inference = "boot",
  B = 200
)
fe_model <- fe(
  formula = ccred ~ tookmath + female + ethnic + frl + mathtestz + gpa11th +  (1 | school), 
  data = mockmath12th,
  family = poisson(link="log"),
  inference = "crse"
)
bcregfe_model <- bcregfe(
  formula = ccred ~ tookmath + female + ethnic + frl + mathtestz + gpa11th +  (1 | school), 
  data = mockmath12th,
  regression_type = "poisson"
)
regfe_model <- regfe(
  formula = ccred ~ tookmath + female + ethnic + frl + mathtestz + gpa11th +  (1 | school), 
  data = mockmath12th,
  regression_type = "poisson"
)
mlm_model <- glmer( # from lme4
  formula = ccred ~ tookmath + female + ethnic + frl + mathtestz + gpa11th +  (1 | school), 
  data = mockmath12th,
  family = poisson(link="log")
)
```

The following table then compares the estimated coefficients (and
standard errors) across the five models, with double stars (\*\*)
indicating statistical significance at the 0.05 level:

    #>                                          FE              bcMLM            bcRegFE                MLM             RegFE
    #> (Intercept)                            <NA>    1.3094 (0.8758)  1.3131** (0.1703)  1.5223** (0.0381) 1.5234** (0.0269)
    #> tookmath                    0.0085 (0.0058)    0.0084 (0.0055)    0.0084 (0.0059)    0.0103 (0.0056)   0.0103 (0.0059)
    #> female                     -0.0050 (0.0043)   -0.0050 (0.0040)   -0.0050 (0.0044)   -0.0050 (0.0040)  -0.0050 (0.0044)
    #> ethnicBlack                -0.0128 (0.0128)   -0.0126 (0.0117)   -0.0126 (0.0129)   -0.0126 (0.0117)  -0.0126 (0.0129)
    #> ethnicFilipinx             -0.0201 (0.0159)   -0.0200 (0.0139)   -0.0200 (0.0161)   -0.0197 (0.0139)  -0.0197 (0.0161)
    #> ethnicLatinx               -0.0071 (0.0096)   -0.0069 (0.0096)   -0.0069 (0.0097)   -0.0070 (0.0096)  -0.0070 (0.0097)
    #> ethnicWhite                -0.0079 (0.0114)   -0.0078 (0.0117)   -0.0079 (0.0116)   -0.0078 (0.0117)  -0.0078 (0.0116)
    #> ethnicOther                -0.0519 (0.0304) -0.0517** (0.0244)   -0.0517 (0.0308) -0.0517** (0.0244)  -0.0517 (0.0308)
    #> frl                         0.0000 (0.0073)   -0.0001 (0.0075)   -0.0001 (0.0074)    0.0004 (0.0075)   0.0004 (0.0074)
    #> mathtestz                 0.1305** (0.0050)  0.1306** (0.0040)  0.1306** (0.0051)  0.1303** (0.0040) 0.1303** (0.0051)
    #> gpa11th                   0.5498** (0.0080)  0.5499** (0.0073)  0.5499** (0.0081)  0.5496** (0.0073) 0.5496** (0.0081)
    #> tookmath_schoolmean                    <NA>  1.9274** (0.1005)  1.9237** (0.0234)               <NA>              <NA>
    #> female_schoolmean                      <NA>    0.1808 (0.1439)  0.1791** (0.0429)               <NA>              <NA>
    #> ethnicBlack_schoolmean                 <NA>   -0.1375 (0.4276)   -0.1409 (0.0940)               <NA>              <NA>
    #> ethnicFilipinx_schoolmean              <NA>    0.1546 (0.4493)    0.1547 (0.1006)               <NA>              <NA>
    #> ethnicLatinx_schoolmean                <NA>   -0.2112 (0.3169) -0.2118** (0.0741)               <NA>              <NA>
    #> ethnicWhite_schoolmean                 <NA>   -0.0160 (0.3879)   -0.0152 (0.1499)               <NA>              <NA>
    #> ethnicOther_schoolmean                 <NA>   -0.7260 (1.1128) -0.7341** (0.1217)               <NA>              <NA>
    #> frl_schoolmean                         <NA>    0.1118 (0.2466)    0.1115 (0.0954)               <NA>              <NA>
    #> mathtestz_schoolmean                   <NA> -0.4488** (0.1340) -0.4508** (0.0366)               <NA>              <NA>
    #> gpa11th_schoolmean                     <NA>   -0.3758 (0.2699) -0.3751** (0.0569)               <NA>              <NA>

All models estimate that `tookmath` does *not* have a statistically
significant relationship with `ccred`, and the coefficients are small.
Again, the FE, bcMLM, and bcRegFE models all produce similar
coefficients and standard errors. The RegFE and uncorrected MLM produce
slightly larger estimates, but they are still small like the other three
models. In truth, the data is simulated such that `tookmath` has no
relationship with `ccred` (i.e., the true coefficient is 0). (An effect
of 0 was chosen because [Wainstein et
al. (2023b)](https://laeri.luskin.ucla.edu/12thgrademathandcollegesuccess/)
did not find a statistically significant relationship between 12th grade
math and overall college credits for a subset of students in their real
study.) Thus all models correctly imply that there is little to no
relationship between these variables, after accounting for student
characteristics and school.

## References

Bai, H., Ferguson, A., Wainstein, L., & Wells, J. (2025). Comparing
multilevel and fixed effect approaches in the generalized linear model
setting. *arXiv preprint arXiv:2411.01723*.

Hazlett, C. & Wainstein, L. (2022). Understanding, Choosing, and
Unifying Multilevel and Fixed Effect Approaches. *Political Analysis,
30*(1), 46-65. <doi:10.1017/pan.2020.41>

Wainstein, L., Miller, C., Phillips, M., Yamashiro, K., & Melguizo, T.
(2023a). Twelfth Grade Math and College Access. Los Angeles Education
Research Institute, Los Angeles, CA, USA.
<https://laeri.luskin.ucla.edu/12thgrademathandcollegeaccess/>.

Wainstein, L., Miller, C., Phillips, M., Yamashiro, K., & Melguizo, T.
(2023b). Twelfth Grade Math and College Success. Los Angeles Education
Research Institute, Los Angeles, CA, USA.
<https://laeri.luskin.ucla.edu/12thgrademathandcollegesuccess/>.
