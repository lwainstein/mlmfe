#' Mock, simulated dataset on 12th grade math course-taking
#'
#' This is a mock, simulated dataset for use with `mlmfe`.
#' The `mockmath12th` dataset is completely simulated, but is based on the real data examined by [Wainstein et al. (2023a)](https://laeri.luskin.ucla.edu/12thgrademathandcollegeaccess/) and [Wainstein et al. (2023b)](https://laeri.luskin.ucla.edu/12thgrademathandcollegesuccess/),
#' for the [Los Angeles Education Research Institute (LAERI)](https://laeri.luskin.ucla.edu/) at the University of California Los Angeles, who investigated the effects of taking math in 12th grade on end-of-high school and college outcomes in the Los Angeles Unified School District.
#' This real data is re-analyzed by [Bai et al. (2026)](https://arxiv.org/abs/2411.01723) in their paper.
#' One can see how the `mockmath12th` dataset was simulated by viewing the `mockmath12th.R` file in the `data-raw/` folder.
#' Note that the simulated demographic variables (gender, race/ethnicity, and a free or reduced-price lunch indicator) were generated completely at random, and do NOT have any relationship
#' with other variables in the data (e.g., the outcomes, math course-taking, school, or academic achievement). These demographic variables are included purely to simulate
#' the experience of working with an education-related dataset, as these variables are often information collected on students.
#' Average values for the variables are meant to mimic the data in the LAERI reports. The effects of taking 12th grade math on the outcomes are specified
#' to mimic the estimated effects found in the LAERI reports.
#'
#' @format ## `mockmath12th`
#' A dataframe with 11,225 rows, which represent students, and 10 columns:
#' \describe{
#'   \item{finalgpa}{Outcome variable: Cumulative GPA at the end of high school.}
#'   \item{cenrl}{Outcome variable: Whether or not student enrolled in a two-year or four-year college within one year of highschool graduation (1=yes, 0=no).}
#'   \item{ccred}{Outcome variable: Number of credits accumulated in college after two years. Is `NA` if `cenrl=0`.}
#'   \item{tookmath}{Treatment variable: Whether or not student took math in 12th grade (1=yes, 0=no).}
#'   \item{school}{Covariate: School student attended (numbered 1-200).}
#'   \item{female}{Covariate: Whether or not student is female (1=yes, 0=no).}
#'   \item{ethnic}{Covariate: Race/Ethnicity of the student.}
#'   \item{frl}{Covariate: Whether or not student qualifies for free or reducted price lunch (1=yes, 0=no).}
#'   \item{gpa11th}{Covariate: Cumulative GPA at the end of 11th grade.}
#'   \item{mathtestz}{Covariate: Math standardized test score (Z-Score).}
#' }
"mockmath12th"
