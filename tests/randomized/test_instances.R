library(selectiveInference)

gaussian_instance = function(n, p, s, sigma=1, rho=0, signal=6, X=NA,
                             random_signs=TRUE, scale=TRUE, center=TRUE, seed=NA){
  if (!is.na(seed)){
    set.seed(seed)
  }
  
  if (is.na(X)){
    X = sqrt(1-rho)*matrix(rnorm(n*p),n, p) + sqrt(rho)*matrix(rep(rnorm(n), p), nrow = n)
    X = scale(X)/sqrt(n)
  }
  beta = rep(0, p)
  if (s>0){
    beta[1:s] = seq(3, 6, length.out=s)
  }
  beta = sample(beta)
  if (random_signs==TRUE & s>0){
    signs = sample(c(-1,1), s, replace = TRUE)
    beta = beta * signs
  }
  y = X %*% beta + rnorm(n)*sigma
  result = list(X=X,y=y,beta=beta)
  return(result)
}


collect_results = function(n,p,s, nsim=100, level=0.9, condition_subgrad=TRUE, lam=1.2){

  rho=0.3
  sigma=1
  sample_pvalues = c()
  sample_coverage = c()
  for (i in 1:nsim){
    data = gaussian_instance(n=n,p=p,s=s, rho=rho, sigma=sigma)
    X=data$X
    y=data$y
    beta=data$beta
    result = selectiveInference:::randomizedLassoInf(X, y, lam, level=level, burnin=2000, nsample=4000, condition_subgrad=condition_subgrad)
    true_beta = beta[result$active_set]
    coverage = rep(0, nrow(result$ci))
    if (length(result$active_set)>0){
      for (i in 1:nrow(result$ci)){
        if (result$ci[i,1]<true_beta[i] & result$ci[i,2]>true_beta[i]){
          coverage[i]=1
        }
        print(paste("ci", toString(result$ci[i,])))
      }
      sample_pvalues = c(sample_pvalues, result$pvalues)
      sample_coverage = c(sample_coverage, coverage)
      print(paste("coverage", mean(sample_coverage)))
    }
  }
  if (length(sample_coverage)>0){
    print(paste("coverage", mean(sample_coverage)))
    jpeg('pivots.jpg')
    plot(ecdf(sample_pvalues), xlim=c(0,1),  main="Empirical CDF of null p-values", xlab="p-values", ylab="ecdf")
    abline(0, 1, lty=2)
    dev.off()
  }
}

set.seed(1)
collect_results(n=200, p=100, s=0, lam=2)


