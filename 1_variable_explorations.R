library(ggplot2)

# This script does preliminary checks of the data. 
tdata <- read.csv("data/benchmarking_example.csv")

# Remove periods and units from the column names
colnames(tdata) <- gsub(colnames(tdata), pattern = "\\..*$", replacement = "")

# t and r are perfectly correlated, so we are going to only retain t
# cor(tdata$t, tdata$r)
tdata$r <- NULL

# Compute a spearman correlation matrix. 
tmat <- cor(tdata, method = "spearman")
ggcorrplot::ggcorrplot(tmat,
                       method = "square", show.diag = FALSE, hc.order = TRUE, 
                       tl.cex = 20, type = "lower", lab_size = 3,  
                       lab = TRUE) + 
  theme(text = element_text(size = 20),
        legend.key.height = unit(1, "cm"))

# ^ Confirms that t and Lsl are far and away the most correlated with the 
# variable of interest. Confirms little correlation due to the fact that this 
# is a generated dataset. 

# Check to see if there is any interesting interactions in a regression tree. 
rtree_test <- rpart::rpart(Vcr ~ ., data = tdata)
rpart.plot::rpart.plot(rtree_test)

# ^ Confirms that t and Lsl are most important. 

# See results of ranger variable importance. 
test_rf <- ranger::ranger(Vcr ~ .,  data = tdata, importance = "permutation",
                          mtry = 14)

importance_scores <- test_rf$variable.importance

importance_df <- data.frame(
  Variable = names(importance_scores),
  Importance = importance_scores
)

# Create the variable importance plot
vi_plot <- ggplot(importance_df, aes(y = reorder(Variable, Importance), 
                                     x = Importance)) +
  geom_point() +
  labs(y = "Variable", x = "Importance", title = "Variable Importance Plot") +
  theme_bw() + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# jpeg(width = 7, height = 5, units = "in", res = 600, 
#      file = "figs/rf_importance_plot.jpg")
# vi_plot
# dev.off()

# Make a plot of the unique combinations of t and Lsl
grid_unique <- tdata |>
  dplyr::group_by(t, Lsl) |>
  dplyr::summarize(Vcr = mean(Vcr), 
                   n = dplyr::n())
un_plot <- grid_unique |>
  ggplot(aes(x = t, y = Lsl)) + 
  geom_point(aes(color = Vcr/100), size = 6) + 
  geom_text(aes(label = n), vjust = -1, size = 5) + 
  #scale_size_continuous(range = c(2, 15)) + 
  scale_color_continuous(expression(V[cr] ~ " / 100"), 
                         limits = c(15, 1200),
                         breaks = c(15, 30, 60, 120, 240, 
                                    480, 960),
                         type = "viridis", trans = "log2") + 
  scale_x_continuous(breaks = c(1, 2, 3)) + 
  scale_y_continuous(breaks = c(60, 75, 90), limits = c(60, 93)) +
  theme_bw() + 
  ylab(expression(L[sl])) + 
  theme(panel.grid.minor = element_blank(),
        text = element_text(size = 16,
                            family = "serif")) 


jpeg(width = 7, height = 5, units = "in", res = 600,
     file = "figs/un_combo_plot.jpg")
un_plot
dev.off()

# Function to compare three candidate models: 
# (1) rf, (2) OLS (all variables), (3) refined OLS (two variables + interaction)
cv_compare_core <- function(tdata, groups, 
                            tformula = log(Vcr) ~ t + Lsl + t*Lsl,
                            ...){
  
  preds <- matrix(0, nrow = nrow(tdata), ncol = 4)
  for(i in seq_len(length(unique(groups)))){
    test <- tdata[groups == i, ]
    train = tdata[groups != i, ]
    
    tmodel1 <- ranger::ranger(Vcr ~ ., data = train, ...)
    tmodel1_2 <- ranger::ranger(Vcr ~ ., data = train, mtry = ncol(train) - 1)
    tmodel2 <- lm(Vcr ~ ., data = train)
    tmodel3 <- lm(tformula, data = train)
    
    preds[groups == i, 1] <- predict(tmodel1, test)$predictions
    preds[groups == i, 2] <- predict(tmodel1_2, test)$predictions
    preds[groups == i, 3] <- predict(tmodel2, test)
    preds[groups == i, 4] <- exp(predict(tmodel3, test))
  }
  
  preds <- as.data.frame(preds)
  colnames(preds) <- c("RF", "RF-Tuned", "LM-Full", "LM-Select")
  preds
}

# Traditional cross validation
set.seed(90211)
groups_trad <- rep(1:9, length = nrow(tdata))
groups_trad <- sample(groups_trad)
preds1 <- cv_compare_core(tdata, groups = groups_trad)

# Adapted cross validation
tgroups <- expand.grid(unique(tdata$t), unique(tdata$Lsl))
colnames(tgroups) <- c("t", "Lsl")
tgroups$group_no <- seq_len(nrow(tgroups))

new_groups <- dplyr::left_join(tdata, tgroups, by = c("t", "Lsl")) |>
  dplyr::pull(group_no)
preds2 <- cv_compare_core(tdata, groups = new_groups)

# Combine the final results into a table and write to csv
results_csv <- 
  data.frame(trad_rmse = sqrt(apply((preds1 - tdata$Vcr)^2, 2, mean)),
             trad_mae = apply(abs(preds1 - tdata$Vcr), 2, median),
             new_rmse = sqrt(apply((preds2 - tdata$Vcr)^2, 2, mean)),
             new_mae = apply(abs(preds2 - tdata$Vcr), 2, median)
  )

write.csv(cbind(model = colnames(preds1), round(results_csv)), 
          file = "results.csv", row.names = FALSE)

resid1 <- as.data.frame(abs(preds1 - tdata$Vcr))
resid1$t <- tdata$t
resid1$Lsl <- tdata$Lsl
resid1$Method = "Traditional"

resid2 <- as.data.frame(abs(preds2 - tdata$Vcr))
resid2$t <- tdata$t
resid2$Lsl <- tdata$Lsl
resid2$Method = "Adapted"

resid_final <- dplyr::bind_rows(resid1, resid2) |>
  tidyr::pivot_longer(cols = c("RF", 'RF-Tuned', "LM-Full", "LM-Select"),
                      names_to = "Model", 
                      values_to = "Residuals") |>
  dplyr::mutate(t = paste0("t == ", t),
                Lsl = paste0("L[sl] == ", Lsl)) |>
  dplyr::mutate(Lsl = factor(Lsl, levels = rev(unique(Lsl))))

final_ae_plot <- 
  ggplot(data = resid_final, aes(x = Model, y = Residuals / 1000, 
                                 color = Method)) + 
  geom_boxplot() + 
  scale_y_sqrt() + 
  facet_grid(Lsl ~ t, labeller = label_parsed) + 
  scale_color_manual(values = c("red", "blue")) + 
  ylab("|Residuals| (Thousands)") + 
  theme_bw() + 
  theme(legend.position = "top",
        text = element_text(size = 16, 
                            family = "serif"),
        axis.text.x = element_text(angle = -25, vjust = 0.5))

jpeg(width = 7, height = 6, units = "in", res = 600,
     file = "figs/final_ae_plot.jpg")
final_ae_plot
dev.off()


