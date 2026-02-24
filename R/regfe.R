
#' Regularized fixed-effects models
#'
#' @description This function implements regularized-fixed effect multilevel models
#'  as described in [Bai et al. (2025)](https://arxiv.org/abs/2411.01723) and [Hazlett and Wainstein (2022)](https://www.cambridge.org/core/journals/political-analysis/article/understanding-choosing-and-unifying-multilevel-and-fixed-effect-approaches/8101D49CFD3B129F5753FC878F416980).
#'  Optimization is done through iterative reweighted least squares. The function uses output from the
#'  [`lme4`](https://cran.r-project.org/web/packages/lme4/index.html) package to estimate regularizing
#'  parameters and starting parameters for optimization. Cluster-robust standard errors are provided,
#'  as suggested by [Bai et al. (2025)](https://arxiv.org/abs/2411.01723).
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
#' A list containing various results from the regularized fixed effects model.
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

regfe <- function(formula, data, regression_type = "linear", rtol = 1e-8, max_iter = 200, ...){

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

  ### Run initial lme4 call
  if(regression_type=="linear"){
    lme4_model <- lmer(formula, data=data, ...)
  }
  if(regression_type=="logistic"){
    lme4_model <- glmer(formula, data=data, family = binomial(link="logit"), ...)
  }
  if(regression_type=="poisson"){
    lme4_model <- glmer(formula, data=data, family = poisson(link="log"), ...)
  }

  ### Get the model-matrix for the formula, so that correct dummy variables are made
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

  ### Sort data to make life easier
  ordered_data <- data[order(data[, gtext]), ]
  ordered_model_matrix <- model_matrix[order(data[, gtext]), ]

  ### Make X Matrix
  X <- as.matrix(ordered_model_matrix[, xtext_extended])
  X <- cbind(1, X)
  colnames(X)[1] <- "(Intercept)"

  ### Make Y vector
  Y <- ordered_data[, ytext]

  ### Make Z
  # Get all the variables we need
  Z_formula <- paste(
    ytext,
    "~",
    "0",
    sep=""
  )
  for(var in retext){
    if(var=="1") Z_formula <- paste(Z_formula, "+as.factor(", gtext, ")", sep="")
    if(var!="1") Z_formula <- paste(Z_formula, "+as.factor(", gtext, "):", var, sep="")
  }
  Z_formula <- as.formula(Z_formula)
  Z <- model.matrix(Z_formula, data=ordered_data)

  # Put the variables in the right order
  Z_order <- NULL
  for(g in unique(ordered_data[, gtext])){
    num_obs <- sum(ordered_data[, gtext]==g)
    if(num_obs>1) data_sub <- Z[ordered_data[, gtext]==g, ]
    if(num_obs==1){
      data_sub <- t(as.matrix(Z[ordered_data[, gtext]==g, ]))
      colnames(data_sub) <- colnames(Z)
    }
    temp_indices <- which(apply(X=data_sub, MARGIN=2, FUN=sum)!=0)
    Z_order <- c(Z_order, temp_indices)
  }
  Z <- Z[, Z_order]

  ### Make Combined matrix
  XZ <- cbind(X, Z)

  ### Make functions and values needed for the weights
  # Linear regression
  if(regression_type=="linear"){
    h <- function(t){
      t
    }

    hprime <- function(t){
      rep(1, length(t))
    }

    hinv <- function(t){
      t
    }

    vfun <- function(t){
      rep(1, length(t))
    }

    phi <- summary(lme4_model)$sigma^2
  }

  # Logistic regression
  if(regression_type=="logistic"){
    h <- function(t){
      log(t / (1 - t))
    }

    hprime <- function(t){
      1 / (t * (1-t))
    }

    hinv <- function(t){
      exp(t) / ( 1 + exp(t))
    }

    vfun <- function(t){
      t * (1 - t)
    }

    phi <- 1
  }

  # Poisson regression
  if(regression_type=="poisson"){
    h <- function(t){
      log(t)
    }

    hprime <- function(t){
      1 / t
    }

    hinv <- function(t){
      exp(t)
    }

    vfun <- function(t){
      t
    }

    phi <- 1
  }

  ### Get Omega Matrix
  Omega_Matrix <- as.matrix(summary(lme4_model)$varcor[[gtext]])

  ### Optimization
  # Get starting value for beta
  beta_start <- summary(lme4_model)$coefficients[, "Estimate"]

  # Get starting value for RE
  beta_re_names <- retext
  if("1" %in% retext) beta_re_names[beta_re_names=="1"] <- "(Intercept)"
  beta_start_re <- beta_start[beta_re_names]

  group_beta <- coef(lme4_model)[[gtext]]
  gamma_start <- NULL
  for(g in row.names(group_beta)){
    temp <- as.numeric(group_beta[g, beta_re_names] - beta_start_re)
    gamma_start <- c(gamma_start, temp)
  }

  # Combine starting values
  theta1 <- c( # define starting parameters
    beta_start,
    gamma_start
  )
  theta1 <- as.vector(theta1)
  names(theta1) <- colnames(XZ)

  if(abs(det(Omega_Matrix))>1e-10){
    # Make regularization matrix
    Zero <- diag(rep(0, ncol(X)))

    Omega_inv <- solve(Omega_Matrix)
    temp <- list()
    for(g in 1:length(unique(ordered_data[, gtext]))){
      temp[[g]] <- Omega_inv
    } # end of g
    Omega_inv_Block <- as.matrix(bdiag(temp))

    Smat <- 2 * phi * as.matrix(bdiag(list(Zero, 0.5 * Omega_inv_Block)))

    # Optimize
    diff <- 100
    opt_num <- 0
    while(diff>rtol & opt_num<=max_iter){
      # Add to conter
      opt_num <- opt_num + 1

      # Reset
      theta0 <- theta1

      # get mu and XZalpha
      XZalpha <- as.vector(XZ %*% as.matrix(theta0))
      mu <- hinv(XZalpha)

      # get weights
      w <- 1 / (  (hprime(mu)^2) * vfun(mu)  )
      Wmat <- diag(w)

      # get A
      A <- XZalpha + (Y - mu)*hprime(mu)

      # get updated parameters
      theta1 <- solve( t(XZ) %*% Wmat %*% XZ + Smat) %*% t(XZ) %*% Wmat %*% A
      theta1 <- as.vector(theta1)
      names(theta1) <- colnames(XZ)

      diff <- abs(sum(theta1 - theta0))
      if(is.na(diff)){
        theta1 <- theta0
        diff <- 0
      }

    } # end of while(diff>1e5)
  }

  ### Grab coefficient results
  beta <- theta1[names(beta_start)]

  temp <- theta1[-match(names(beta), names(theta1))]
  re <- matrix(temp, ncol=length(retext), byrow=T)
  colnames(re) <- retext
  colnames(re)[colnames(re)=="1"] <- "(Intercept)"
  rownames(re) <- rownames(coef(lme4_model)[[gtext]])

  ### Create CRSEs
  # Create meat
  epsilon_star <- A - XZalpha
  emat_list <- list()
  groups_list <- unique(ordered_data[, gtext])
  for(g in 1:length(groups_list)){
    evec <- as.matrix(epsilon_star[ordered_data[, gtext]==groups_list[g]])
    emat <- evec %*% t(evec)
    emat_list[[g]] <- emat
  } # end of g
  meat <- as.matrix(bdiag(emat_list))

  # Create bread
  bread <- solve( t(XZ) %*% Wmat %*% XZ + Smat) %*% t(XZ) %*% Wmat

  # Make matrix
  vcov <- bread %*% meat %*% t(bread)
  vcov <- vcov[names(beta), names(beta)]

  # Get finite sample correction
  n <- nrow(X)
  G <- length(unique(ordered_data[, gtext]))

  p <- 0
  for(var in xtext_extended){
    if(var=="1") next
    if(var %in% retext) next

    tilde_formula <- as.formula(paste(var, "~", paste(retext, collapse="+"), sep=""))

    temp <- NULL
    for(g in unique(ordered_data[, gtext])){
      data_sub <- ordered_data[ordered_data[, gtext]==g, ]
      data_sub[, var] <- ordered_model_matrix[ordered_data[, gtext]==g, var]

      temp_model <- lm(tilde_formula, data=data_sub)
      temp <- c(temp, temp_model$fitted.values)
    }

    check <- sum(abs(ordered_model_matrix[, var] - temp))
    if(check<1e-10){
      next
    }
    else{
      p <- p + 1
    }
  } # end of for(var in xtext)

  temp_formula <- paste(
    ytext,
    "~",
    paste(retext, collapse="+"),
    sep=""
  )
  temp_formula <- as.formula(temp_formula)
  temp <- model.matrix(lm(temp_formula, data=data))
  num_revars <- ncol(temp)
  c <- (G / (G-1)) * ((n - 1) / (n - (p + G*num_revars)))
  vcov <- c * vcov

  # Standard errors
  se <- sqrt(diag(vcov))

  # Put together coefficient matrix
  z_value <- beta / se
  p_value <- 2*(1 - pnorm(abs(z_value)))

  coefficients_matrix <- cbind(beta, se, z_value, p_value)
  colnames(coefficients_matrix) <- c("Estimate", "Std. Error", "z value", "Pr(>|z|)")

  ### Output
  output <- list(
    "coefficients" = coefficients_matrix,
    "random_effects" = re,
    "vcov" = vcov,
    "data" = data,
    "num_iter" = opt_num,
    "iwls_diff" = diff,
    "lme4_model" = lme4_model
  )
  return(output)
}




