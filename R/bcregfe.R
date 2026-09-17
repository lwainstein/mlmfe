
#' Bias-corrected regularized fixed-effect models
#'
#' @description This function implements bias-corrected regularized-fixed effect multilevel models
#'  as described in [Bai et al. (2026)](https://arxiv.org/abs/2411.01723).
#'  Optimization is done through iterative reweighted least squares. The function uses output from the
#'  [`lme4`](https://cran.r-project.org/web/packages/lme4/index.html) package to estimate regularizing
#'  parameters and starting parameters for optimization. Cluster-robust standard errors are provided,
#'  as suggested by [Bai et al. (2026)](https://arxiv.org/abs/2411.01723).
#'
#'  Note: Currently, the `mlmfe` package only allows for two-level models.
#'
#' @param formula A formula in the style of the [`lme4`](https://cran.r-project.org/web/packages/lme4/index.html) package.
#' @param data Dataset to build model on.
#' @param regression_type Character that determines what kind of model is built. Can be `"linear"`,
#' `"logistic"` (logit link function), or `"poisson"` (log link function). Default is `"linear"`.
#' @param rtol Tolerance level for optimization -- maximum difference between current and previous step parameters, such that optimization will continue. Defaults to `rtol = 1e-8`.
#' @param max_iter Maximum number of iterations for optimization. Defaults to`max_iter = 200`.
#' @param ... Additional arguments passed to `lmer()` (if `regression_type="linear"`) or `glmer()` (if `regression_type` is not `"linear"`) from `lme4`.
#'
#'
#' @returns
#' A list containing various results from the bias-corrected regularized fixed effects model.
#'
#'
#'
#' @import lme4
#' @import Matrix
#'
#' @export
#'
#'
#'

bcregfe <- function(formula, data, regression_type = "linear", rtol = 1e-8, max_iter = 50, ...){

  ### Get vectors of variable names from the data
  ftext <- paste(format(formula), collapse="")
  ftext <- gsub("\\ ", "", ftext)

  # Get variable names
  ytext <- strsplit(ftext, split="~")[[1]][1]

  xtext <- strsplit(strsplit(
    strsplit(ftext, split="~")[[1]][2], split = "\\("
  )[[1]][1], split="\\+")[[1]]

  gtext <- gsub("\\)", "", strsplit(
    strsplit(ftext, split="~")[[1]][2], split = "\\|"
  )[[1]][2])

  retext <- strsplit(strsplit(strsplit(
    strsplit(ftext, split="~")[[1]][2], split = "\\("
  )[[1]][2], split="\\|")[[1]][1], split="\\+")[[1]]

  ### Remove missing values from dataset
  allvars <- c(ytext, xtext, gtext, retext)
  if("1" %in% allvars) allvars <- allvars[-match("1", allvars)]
  for(var in allvars){
    data <- data[!is.na(data[, var]), ]
    data <- data[!is.infinite(data[, var]), ]
  }

  ### Add variables to the data needed for bcMLM
  # Get the model-matrix for the formula, so that correct dummy variables are made
  formula_short <- paste(
    ytext,
    "~",
    paste(xtext, collapse="+"),
    sep=""
  )
  formula_short <- as.formula(formula_short)
  model_matrix <- model.matrix(lm(formula_short, data=data))
  if("(Intercept)" %in% colnames(model_matrix)) model_matrix <- model_matrix[, -match("(Intercept)", colnames(model_matrix))]
  model_matrix <- data.frame(model_matrix)
  xtext_extended <- colnames(model_matrix)

  # Make a new dataset
  new_regressors <- NULL
  for(var in xtext_extended){
    if(var=="1") next
    if(var %in% retext) next
    newvarname <- paste(var, "_tilde", sep="")
    if(length(retext)==1 & retext[1]=="1") newvarname <- paste(var, "_", gtext, "mean", sep="")

    data[, newvarname] <- NA
    group_levels <- sort(unique(data[, gtext]))
    tilde_formula <- as.formula(paste(var, "~", paste(retext, collapse="+"), sep=""))
    for(g in group_levels){
      data_sub <- data[data[, gtext]==g, ]
      data_sub[, var] <- model_matrix[data[, gtext]==g, var]
      temp_model <- lm(tilde_formula, data=data_sub)
      data[data[, gtext]==g, newvarname] <- temp_model$fitted.values
    }
    check <- sum(abs(model_matrix[, var] - data[, newvarname]))
    if(check<1e-10){
      data <- data[, -ncol(data)]
    }
    else{
      new_regressors <- c(new_regressors, newvarname)
    }
  } # end of for(var in xtext)

  ### Make new formula
  new_formula <- paste(
    ytext,
    "~",
    paste(c(xtext, new_regressors), collapse="+"),
    "+(",
    paste(retext, collapse="+"),
    "|",
    gtext,
    ")",
    sep=""
  )
  new_formula <- as.formula(new_formula)

  ### Run regFE
  regfe_output <- regfe(new_formula, data, regression_type = regression_type, rtol = rtol, max_iter = max_iter, ...)

  ### Output
  output <- list(
    "coefficients" = regfe_output$coefficients,
    "random_effects" = regfe_output$random_effects,
    "vcov" = regfe_output$vcov,
    "data_new" = data,
    "num_iter" = regfe_output$num_iter,
    "iwls_diff" = regfe_output$iwls_diff,
    "lme4_model" = regfe_output$lme4_model
  )
  return(output)
}
