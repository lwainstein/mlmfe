##### SET-UP
### Clear environment
rm(list=ls())

### Libraries
library(usethis)

### Set a seed
set.seed(6)

### Set sample sizes
n <- 11255 # total sample sizes
G <- 200 # Max number of schools







##### ASSIGN STUDENTS TO SCHOOLS
school_probs <- runif(G)
school_probs <- school_probs / sum(school_probs)

school <- sample(1:G, size=n, replace=T, prob=school_probs)





### COVARIATES
### Female
# Generate values
p_female <- 0.5317
possibilities <- c(rep(1, round(n * p_female)), rep(0, round(n * (1-p_female))))
female <- sample(possibilities, size=n)

# Check mean
mean(female) # about same as LAERI report

### Race/Ethnicity
# Assign probabilities
p_asian <- 0.0476
p_black <- 0.0777
p_fil <- 0.0357
p_lat <- 0.7554
p_white <- 0.0762
p_other <- 1 - (p_asian + p_black + p_fil + p_lat + p_white)

# Generate values
possibilities <- c(
  rep("Asian", round(n * p_asian)),
  rep("Black", round(n * p_black)),
  rep("Filipinx", round(n * p_fil)),
  rep("Latinx", round(n * p_lat)),
  rep("White", round(n * p_white)),
  rep("Other", round(n * p_other))
)
ethnic <- sample(possibilities, size=n)
ethnic <- factor(
  ethnic,
  levels = c("Asian", "Black", "Filipinx", "Latinx", "White", "Other")
)

# Check averages
table(ethnic) / n # about same as LAERI report

### FRL
# Generate values
p_frl <- 0.9230
possibilities <- c(rep(1, round(n * p_frl)), rep(0, round(n * (1-p_frl))))
frl <- sample(possibilities, size=n)

# Check mean
mean(frl) # about the same as LAERI report

### GPA at end of 11th grade
# Generate values
gpa11th <- rnorm(n, mean=2.87, sd=0.56) # using mean and SD from LAERI report
gpa11th[gpa11th>=4] <- 4
gpa11th[gpa11th<=0] <- 0

# Check mean and SD
mean(gpa11th) # about the same as LAERI report
sd(gpa11th)

### Math standardized test scores
# Generate values
mathtestz <- sqrt(0.75) * (gpa11th - mean(gpa11th)) / sd(gpa11th) + sqrt(1 - 0.75) * rnorm(n)
  # here GPA is very influential in math test scores

# Check mean, SD, and R2 with GPA
mean(mathtestz) # standardized, so should be about 0
sd(mathtestz) # standardized, so should be about 1
summary(lm(mathtestz~gpa11th))$r.squared # should be about R2=0.75




##### MATH COURSE TAKING (TREATMENT)
### Generate values
# Want a school-specific random intercept
re_school <- rnorm(G)

# Generate values
beta0 <- 0.940 # intercept term, so that % of math-takers is about 66.5% (same % as Group 4 in LAERI report)
p_tookmath <- plogis( beta0 + re_school[school] +0.85*mathtestz + 0.15*(gpa11th - mean(gpa11th))/sd(gpa11th) ) # Math course-taking is only determined by school, math test score, and 11th Grade GPA
tookmath <- 1*(runif(n)<=p_tookmath)

# Check mean
mean(tookmath)






##### OUTCOMES
### End-of-highschool GPA
# Make variable
re_gpa <- rnorm(G, mean=re_school, sd=0.05)
finalgpa <- gpa11th + -0.04*tookmath + 0.05*re_gpa[school] + rnorm(n, mean=0, sd=0.02) # True effect of math course-taking is about -0.04 GPA points, same as estimated in LAERI report.
finalgpa[finalgpa>=4] <- 4
finalgpa[finalgpa<=0] <- 0

# Check FE estimator
lm(finalgpa ~ tookmath + female + ethnic + frl + gpa11th + mathtestz + as.factor(school))$coefficients["tookmath"] # Hopefully near -0.04

### Any College Enrollment
# Generate values
re_cenrl <- rnorm(G, mean=re_school, sd=0.05)
beta0 <- 1.55 # intercept term, so that % of college-going in non-math takers is about 76% (same % as Group 4 in LAERI report)
beta1 <- 0.375 # coefficient on math-taking, so that effect of treatment is about +0.049 (same % as Group 4 in LAERI report)
p_enrl0 <- plogis( beta0 + re_cenrl[school] + 0.40*mathtestz + 0.60*(gpa11th - mean(gpa11th))/sd(gpa11th) )
p_enrl1 <- plogis( beta0 + re_cenrl[school] + 0.40*mathtestz + 0.60*(gpa11th - mean(gpa11th))/sd(gpa11th) + beta1)
p_enrl <- tookmath*p_enrl1 + (1-tookmath)*p_enrl0

cenrl <- 1*(runif(n) <= p_enrl)

# Check that averages and treatment effect are about the same as LAERI report
mean(p_enrl0) # should be about 76%
mean(p_enrl1) - mean(p_enrl0) # should be about +4.9%

# Check FE estimator
glm(cenrl ~ tookmath + female + ethnic + frl + gpa11th + mathtestz + as.factor(school), family=binomial(link="logit"))$coefficients["tookmath"] # Hopefully near beta1

### College Credits
# Random effect for credits
re_ccred <- rnorm(G, mean=re_school, sd=0.05)

# Generate base values
beta0 <- 3.09 # intercept term, so that average credits attempted is about 29 (same average for analytical sample in LAERI report)
beta1 <- 0 # Coefficient on math-taking. Making the effect 0, since LAERI did not find a stat sig effect on overall credits for Group 4.
lambda_ccred <- exp(beta0 + beta1*tookmath + 0.45 * (re_ccred[school] + 0.30*mathtestz + 0.70*(gpa11th - mean(gpa11th))/sd(gpa11th)))
ccred <- rpois(n, lambda=lambda_ccred)

# Fix tail of distribution
ccred[ccred>=80] <- 80 + sample(-5:5, size=sum(ccred>=80), replace=T) # shrinking extreme values
boxplot(ccred) # Shouldn't have too extreme values anymore

# Should make NA if student did not enroll in college
ccred[cenrl==0] <- NA

# Check average
mean(ccred, na.rm=T) # should be about 29

# Check FE estimator
glm(ccred ~ tookmath + female + ethnic + frl + gpa11th + mathtestz + as.factor(school), family=poisson(link="log"))$coefficients["tookmath"] # Hopefully near beta1




##### COMPILE AND EXPORT
### Put everything into a dataframe
mockmath12th <- data.frame(
  finalgpa, cenrl, ccred,
  tookmath,
  school,
  female, ethnic, frl, mathtestz, gpa11th
)

### Save
usethis::use_data(mockmath12th, overwrite = TRUE)
