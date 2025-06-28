# Code and Data for ML Deployment Paper
# 1. Overview
This repository contains the code and data needed to reproduce two examples of the following paper: 
> 📌 **Please cite the following paper if you use this repository**  
>  
> Zaker Esteghamati, M., Bean, B., Burton, H. V., & Naser, M. Z. (2025).  
> *Beyond development: Challenges in deploying machine-learning models for structural engineering applications.*  
> *Journal of Structural Engineering, 151*(6), 04025059.  
> [https://doi.org/10.1061/JSENDH.STENG-12345](https://doi.org/10.1061/JSENDH.STENG-12345)


# 2. Example 1: Model overfitting and adaptive cross-validation
This example uses a published dataset on shear capacity of cold-formed steel channels and compares classic linear regression models and random forests using two methods
of cross-validation: (1) conventional approach by using randomized samples, (2) applying feature importance and creating samples that capture regions of an influential 
parameter for the model (Here, $L_{sl}$ and $t$).

## 2.1 Files in the repository
- **Benchmarking_example.csv & results.csv:** Includes copies of the dataset used in Example 1 of the paper. 

- **stressor_trial_1.R:** Includes unpublished stressor trial results, which were used to 
  inform the selection of Random Forests as a comparison model. 

- **1_variable_explorations.R:** Includes the code necessary to reproduce Figures 3 and 4 as 
  well as Table 1 in the paper
  
# 3. Example 2: Model Underspecification and explainability
This example uses a published experimental result of shearwalls, and aims to understand how model generalizability and interpretation change when (1) the analyst omits
an important feature, (2) add several features to improve model accuracy, where different combinations of features yeild similar accuracy during training but perform 
differently on unseen data (underspecification). The main Jupyter notebook contains all the code used to train models, perform Shapley analysis to explain models, and re-create
plots of the paper for the second example. Therefore, users can simply changes the features of the model, and perform the same experiments as shown in the original paper (e.g., omitting 
$\lambda_b$)

## 3.1 Files in the repository
- **210611 Shear Wall Drift Capacity Dataset.xlsx:** The dataset that contains experimental data on the drift capacity of shear walls
- **Interpretation_Code_ShearWalls.ipynb:** The Jupyter notebook for the second example that contains the main code for model fitting and interpretation
