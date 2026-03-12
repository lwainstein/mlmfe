
#' Bias-corrected multilevel models
#'
#' @description This function implements bias-corrected multilevel models
#'  as described in [Bai et al. (2025)](https://arxiv.org/abs/2411.01723) and [Hazlett and Wainstein (2022)](https://www.cambridge.org/core/journals/political-analysis/article/understanding-choosing-and-unifying-multilevel-and-fixed-effect-approaches/8101D49CFD3B129F5753FC878F416980),
#'  using the [`lme4`](https://cran.r-project.org/web/packages/lme4/index.html) package.
#'
#'  Note: Currently, the `mlmfe` package only allows for two-level models.
#'
#' @param formula A formula in the style of the [`lme4`](https://cran.r-project.org/web/packages/lme4/index.html) package.
#' @param data Dataset to build model on.
#' @param family Family for generalized linear model. If `NULL`, then the function builds a linear model. Default is `NULL`.
#' @param inference Single character determining how to estimate the variance and standard errors of fixed effect coefficients: can be `"default"`, `"crse"`, or `"boot"`.
#' If `inference="default"`, then the standard errors are pulled directly from the `lme4` output.
#' If `inference="crse"`, then cluster-robust standard errors are calculated. This is only allowed for linear models (when `family=NULL`.)
#' If `inference="boot"`, then the variance and standard errors are estimated with a cluster-bootstrap.
#' Defaults to `inference="default"`.
#' @param B Number of bootstrap samples when `inference="boot"`. Defaults to `B=500`.
#' @param ... Additional arguments passed to `lmer()` (if `family=NULL`) or `glmer()` (if GLM `family` is specified) from `lme4`.
#'
#'
#' @returns
#'
#' A list containing various results from the bias-corrected multilevel model.
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

bcmlm <- function(formula, data, family = NULL, inference = "default", B = 500, ...){

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

  ### Fit model
  if(is.null(family)){ # linear model
    lme4_model <- lmer(new_formula, data=data, ...)
  }
  if(!is.null(family)){ # GLM
    lme4_model <- glmer(new_formula, data=data, family = family, ...)
  }

  ### Grab coefficients
  beta <- summary(lme4_model)$coefficients[, "Estimate"]

  ### Grab random effects
  beta_re_names <- retext
  if("1" %in% retext) beta_re_names[beta_re_names=="1"] <- "(Intercept)"
  beta_re <- beta[beta_re_names]

  group_beta <- coef(lme4_model)[[gtext]]
  re <- NULL
  for(g in row.names(group_beta)){
    temp <- as.matrix(group_beta[g, beta_re_names] - beta_re)
    re <- rbind(re, temp)
  }
  row.names(re) <- row.names(group_beta)
  colnames(re) <- beta_re_names

  ### Get inference results
  # Default lme4 inference
  if(inference=="default"){
    vcov <- as.matrix(summary(lme4_model)$vcov)
    se <- sqrt(diag(vcov))
  }

  # CRSE -- only for linear models
  if(inference=="crse"){
    # Error message, if needed
    if(!is.null(family)) stop("CRSEs not available for non-linear models.\n")

    # Order data
    ordered_data <- data[order(data[, gtext]), ]

    # Set up X
    X <- model.matrix(lme4_model)[order(data[, gtext]), ]

    # Get errors matrix
    e <- ordered_data[, ytext] - X %*% beta

    # Get covariacne of random effects
    re_vcov <- as.matrix(summary(lme4_model)$varcor[[gtext]])

    # Get error SD
    sigma <-  summary(lme4_model)$sigma

    # Form meat and bread
    bread <- 0
    meat <- 0
    for(g in unique(ordered_data[, gtext])){
      # Get matrices we need to putgoether
      num_obs <- sum(ordered_data[, gtext]==g)
      if(num_obs > 1) Xsub <- X[ordered_data[, gtext]==g, ]
      if(num_obs == 1) Xsub <- t(as.matrix(X[ordered_data[, gtext]==g, ]))
      Esub <- as.matrix(e[ordered_data[, gtext]==g]) %*% t(as.matrix(e[ordered_data[, gtext]==g]))
      Zsub <- as.matrix(ordered_data[ordered_data[, gtext]==g, retext[retext!="1"]])
      if("1" %in% retext) Zsub <- cbind(1, Zsub)
      Vinv <- solve( Zsub %*% re_vcov %*% t(Zsub) + diag(sigma^2, nrow=sum(ordered_data[, gtext]==g)) )

      # Bread
      bread <- bread + t(Xsub) %*% Vinv %*% Xsub

      # Meat
      meat <- meat + t(Xsub) %*% Vinv %*% Esub %*% Vinv %*% Xsub
    }

    # Create starting matrix
    vcov <- solve(bread) %*% meat %*% solve(bread)

    # Finite sample correction
    G <- length(unique(data[, gtext]))
    n <- nrow(data)
    p <- length(new_regressors)
    c <- G/(G-1) * (n - 1) / (n - (p + G*length(retext)))
    vcov <- c * vcov

    # Get SE
    se <- sqrt(diag(vcov))
  }
  if(inference=="boot"){
    # Get levels of group variable
    glevels <- sort(unique(data[, gtext]))

    # Make a empty matrix that will hold the bootstrap results
    beta_boot <- NULL

    # bootstrap
    for(b in 1:B){
      # Get start time
      start_time <- Sys.time()

      # Sample
      bsample_groups <- sort(sample(glevels, size=length(glevels), replace=T))
      data_boot <- NULL
      for(g in bsample_groups){
        data_boot <- rbind(data_boot, data[data[, gtext]==g, ])
      }

      # Fit model
      if(is.null(family)){
        model_boot <- tryCatch(
          lmer(new_formula, data=data_boot, ...),
          error = function(msg){
            return(NULL)
          }
        )
      }
      if(!is.null(family)){
        model_boot <- tryCatch(
          glmer(new_formula, data=data_boot, family = family, ...),
          error = function(msg){
            return(NULL)
          }
        )
      }

      # Put results together
      if(!is.null(model_boot)) temp <- summary(model_boot)$coefficients[, "Estimate"]
      if(is.null(model_boot)){
        temp <- rep(NA, length(beta))
        names(temp) <- names(beta)
      }
      beta_boot <- rbind(beta_boot, temp)

      # Get elapsed time
      elapsed_time <- difftime(Sys.time(), start_time, units="secs")
      elapsed_time <- round(elapsed_time, 3)

      # Print bootstrap sample and time update
      cat(paste0("Bootstrap Sample ", b, ": ", elapsed_time, " seconds", "\n"))

    }

    # Get variance and SE
    rownames(beta_boot) <- NULL
    vcov <- var(beta_boot, na.rm=TRUE)
    se <- sqrt(diag(vcov))
  }

  # Put together coefficient matrix
  z_value <- beta / se
  p_value <- 2*(1 - pnorm(abs(z_value)))

  coefficients_matrix <- cbind(beta, se, z_value, p_value)
  colnames(coefficients_matrix) <- c("Estimate", "Std. Error", "z value", "Pr(>|z|)")

  # Output
  if(inference!="boot"){
    output <- list(
      "coefficients" = coefficients_matrix,
      "random_effects" = re,
      "vcov" = vcov,
      "inference" = inference,
      "data_new" = data,
      "lme4_model" = lme4_model
    )
  }
  if(inference=="boot"){
    output <- list(
      "coefficients" = coefficients_matrix,
      "random_effects" = re,
      "vcov" = vcov,
      "boot_coefficients" = beta_boot,
      "inference" = inference,
      "data_new" = data,
      "lme4_model" = lme4_model
    )
  }
  return(output)
}




