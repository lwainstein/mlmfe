
#' Fixed effects models
#'
#' @description This function implements fixed effects models, and uses the
#'  [`sandwich`](https://cran.r-project.org/web/packages/sandwich/index.html) package to form
#'  cluster-robust standard errors.
#'
#'  Note: Currently, the `mlmfe` package only allows for two-level models.
#'
#' @param formula A formula in the style of the [`lme4`](https://cran.r-project.org/web/packages/lme4/index.html) package.
#' @param data Dataset to build model on.
#' @param family Family for generalized linear model. If `NULL`, then the function builds a linear model. Default is `NULL`.
#' @param inference Single character determining how to estimate the variance and standard errors of coefficients: can be `"default"` or `"crse"`.
#' If `inference="default"`, then the standard errors are pulled directly from the `lm()` (if `family=NULL`) or `glm()` (if if GLM `family` is specified) output.
#' If `inference="crse"`, then cluster-robust standard errors are calculated, using the `vcovCL()` function from the `sandwich` package.
#' Defaults to `inference="default"`.
#' @param ... Additional arguments passed to `lm()` (if `family=NULL`) or `glm()` (if GLM `family` is specified).
#'
#' @returns
#'
#' A list containing various results from the fixed effects model.
#'
#'
#'
#' @import lme4
#' @import Matrix
#' @import sandwich
#'
#' @export
#'
#'
#'

fe <- function(formula, data, family = NULL, inference = "default", ...){

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

  fetext <- strsplit(strsplit(strsplit(
    strsplit(ftext, split="~")[[1]][2], split = "\\("
  )[[1]][2], split="\\|")[[1]][1], split="\\+")[[1]]

  ### Remove missing values from dataset
  allvars <- c(ytext, xtext, gtext, fetext)
  if("1" %in% allvars) allvars <- allvars[-match("1", allvars)]
  for(var in allvars){
    data <- data[!is.na(data[, var]), ]
    data <- data[!is.infinite(data[, var]), ]
  }

  ### Remove variables from xtext that will be collinear
  # Remove variables
  xtext_new <- xtext
  for(var in xtext){
    if(var %in% fetext) xtext_new <- xtext_new[-match(var, xtext_new)]
    if(!(var %in% fetext)){
      if(!is.factor(data[, var]) & !is.character(data[, var])){
        temp <- NA
        group_levels <- sort(unique(data[, gtext]))
        tilde_formula <- as.formula(paste(var, "~", paste(fetext, collapse="+"), sep=""))
        for(g in group_levels){
          data_sub <- data[data[, gtext]==g, ]
          temp_model <- lm(tilde_formula, data=data_sub)
          temp[data[, gtext]==g] <- temp_model$fitted.values
        }
        check <- sum(abs(data[, var] - temp))
        if(check<1e-10) xtext_new <- xtext_new[-match(var, xtext_new)]
      } # end of !is.factor(data[, var]) & !is.character(data[, var])
      if(is.factor(data[, var]) | is.character(data[, var])){
        temp_formula <- paste(
          ytext,
          "~",
          var,
          sep=""
        )
        temp_formula <- as.formula(temp_formula)
        temp_modelmat <- model.matrix(lm(temp_formula, data=data))
        if("(Intercept)" %in% colnames(temp_modelmat)) temp_modelmat <- temp_modelmat[, -match("(Intercept)", colnames(temp_modelmat))]
        temp_modelmat <- data.frame(temp_modelmat)
        temp_catvars <- colnames(temp_modelmat)
        check <- 0
        for(cat_var in temp_catvars){
          group_levels <- sort(unique(data[, gtext]))
          tilde_formula <- as.formula(paste(cat_var, "~", paste(fetext, collapse="+"), sep=""))
          for(g in group_levels){
            data_sub <- data[data[, gtext]==g, ]
            data_sub[, cat_var] <- temp_modelmat[data[, gtext]==g, cat_var]
            temp_model <- lm(tilde_formula, data=data_sub)
            temp[data[, gtext]==g] <- temp_model$fitted.values
          }
          check <- check + sum(abs(temp_modelmat[, cat_var] - temp))
        }
        if(check<1e-10) xtext_new <- xtext_new[-match(var, xtext_new)]
      } # end of !is.factor(data[, var]) & !is.character(data[, var])
    } # end of if(!(var %in% fetext))
  } # end of for(var in xtext)

  ### Remove intercept term
  if("1" %in% fetext) xtext_new <-c("0", xtext_new)

  ### Get the fetext for the formula in the right format
  fetext_new <- NULL
  for(var in fetext){
    if(var=="1") fetext_new <- c(fetext_new, paste("as.factor(", gtext, ")", sep=""))
    if(var!="1") fetext_new <- c(fetext_new, paste("as.factor(", gtext, "):", var, sep=""))
  }

  ### Make new formula
  new_formula <- paste(
    ytext,
    "~",
    paste(c(fetext_new, xtext_new), collapse="+"),
    sep=""
  )
  new_formula <- as.formula(new_formula)

  ### Fit model
  if(is.null(family)){
    model <- lm(new_formula, data=data, ...)
  }
  if(!is.null(family)){
    model <- glm(new_formula, data=data, family = family, ...)
  }

  ### Grab coefficients
  beta <- summary(model)$coefficients[, "Estimate"]
  names(beta) <- sub(paste("as.factor\\(", gtext, "\\)", sep=""), gtext, names(beta))

  ### Get model matrix
  model_matrix <- model.matrix(model)
  colnames(model_matrix) <- sub(paste("as.factor.", gtext, ".", sep=""), gtext, colnames(model_matrix))

  ### Get inference results
  # homoscedastic
  if(inference=="default"){
    vcov <- vcov(model)
    colnames(vcov) <- names(beta)
    rownames(vcov) <- names(beta)
    se <- sqrt(diag(vcov))
  }

  # CRSE
  if(inference=="crse"){
    vcov <- vcovCL(model, cluster=data[, gtext])
    colnames(vcov) <- names(beta)
    rownames(vcov) <- names(beta)
    se <- sqrt(diag(vcov))
  }

  ### Rearrange order of results
  temp_formula <- as.formula(paste(
    ytext,
    "~",
    "0+",
    paste(fetext_new, collapse="+"),
    sep=""
  ))
  temp_modelmat <- model.matrix(lm(temp_formula, data=data))
  colnames(temp_modelmat) <- sub(paste("as.factor.", gtext, ".", sep=""), gtext, colnames(temp_modelmat))
  fe_indices <- match(colnames(temp_modelmat), names(beta))
  xtext_indices <- c(1:length(beta))[-fe_indices]
  new_order <- c(xtext_indices, fe_indices)

  beta <- beta[new_order]
  se <- se[new_order]
  vcov <- vcov[new_order, new_order]
  model_matrix <- model_matrix[, new_order]

  # Put together coefficient matrix
  z_value <- beta / se
  p_value <- 2*(1 - pnorm(abs(z_value)))

  coefficients_matrix <- cbind(beta, se, z_value, p_value)
  colnames(coefficients_matrix) <- c("Estimate", "Std. Error", "z value", "Pr(>|z|)")

  ### Output
  output <- list(
    "coefficients" = coefficients_matrix,
    "vcov" = vcov,
    "inference" = inference,
    "data" = data,
    "model_matrix" = model_matrix,
    "model" = model
  )
  return(output)
}




