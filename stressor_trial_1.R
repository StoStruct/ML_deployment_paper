# Read in the sample data. 
tdata <- read.csv("data/benchmarking_example.csv")
colnames(tdata) <- gsub(colnames(tdata), pattern = "\\..*$", replacement = "")
# t and r are perfectly correlated, so we are going to only retain t
tdata$r <- NULL

# Need to run only once in order to get the Python virtual environment
# installed (remain commented otherwise). 
# stressor::create_virtualenv()

# Ensure that R is pointing to the proper virtual environment. 
# Here, we use the one (and only) virtual environment 
# available on our local machine. 
env_list <- reticulate::virtualenv_list()
reticulate::use_virtualenv(env_list[1])

temp_models <- stressor::mlm_regressor(Vcr ~ ., train_data = tdata)

# Confirm that rf is second model and test the hyperparameters
temp_models$models[[2]]$get_params()

trad_cv <- stressor::cv(temp_models, tdata)
trad_rmse <- stressor::rmse(trad_cv, tdata$Vcr)

# A random forest variable importance check revealed that "t" (or equivalently )
groups <- expand.grid(unique(tdata$t), unique(tdata$Lsl))
colnames(groups) <- c("t", "Lsl")
groups$group_no <- seq_len(nrow(groups))

tdata2 <- dplyr::left_join(tdata, groups, by = c("t", "Lsl"))

preds2 <- stressor:::cv_core(temp_models, data = tdata2, 
                             t_groups = tdata2$group_no)

new_rmse <- stressor::rmse(preds2, tdata$Vcr)

new_rmse

