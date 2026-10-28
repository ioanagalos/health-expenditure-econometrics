# Health expenditure across countries

This is our econometrics project from the second year at ASE Bucharest. We wanted to see what explains how much of their GDP countries spend on health. We used World Bank data for 2022 on 168 countries and looked at three things: GDP per capita, the share of people aged 65 and over, and EU membership.

GDP per capita has a positive and significant effect on its own, but it explains less than 10% of the differences between countries. When we added the share of people over 65, this became the significant variable and GDP was no longer significant. The two are quite strongly correlated (0.695), so part of what looked like a GDP effect was actually the effect of an older population. Being in the EU did not make a significant difference.

## Results

| Model | R² | Adj. R² |
|---|---|---|
| Simple (log GDP per capita) | 0.097 | 0.091 |
| Multiple (+ population 65+, EU) | 0.161 | 0.146 |
| With interaction GDP x EU | 0.166 | 0.146 |

In the simple model, a country with twice the GDP per capita spends on average about 0.55 percentage points more of its GDP on health. In the multiple model, one more percentage point of people over 65 means 0.155 points more health spending. We also tried an interaction between GDP and the EU dummy, but it was not significant, so we kept the model without it.

![Health expenditure vs. GDP per capita](figures/figure1_scatter.png)

![EU vs. non-EU](figures/figure3_eu_interaction.png)

## How we did it

All models were estimated with OLS in R. We tested for heteroscedasticity (White, Breusch-Pagan, Glejser), autocorrelation (Durbin-Watson, Breusch-Godfrey), normality of the residuals (Jarque-Bera, Shapiro-Wilk) and multicollinearity (VIF). The only assumption that did not hold was normality, because of a few countries with very high spending, like the US. With 168 observations this is not a big problem, but we also checked the simple model with robust standard errors and the result stayed the same.

## Files

analysis.R contains the full analysis and the data is in the data folder. It was downloaded from the World Bank with get_data.R. The full report, in Romanian, is in the report folder.

## References

Baltagi, B. H., Moscone, F. and Tosetti, E. (2012) Medical technology and the production of health care. Empirical Economics, 42(2), 395-411.

Gerdtham, U. G., Søgaard, J., Andersson, F. and Jönsson, B. (1992) An econometric analysis of health care expenditure: a cross-section study of the OECD countries. Journal of Health Economics, 11(1), 63-84.

Getzen, T. E. (2000) Health care is an individual necessity and a national luxury. Journal of Health Economics, 19(2), 259-270.

Gujarati, D. N. and Porter, D. C. (2009) Basic Econometrics. 5th ed. McGraw-Hill.

Nghiem, S. H. and Connelly, L. B. (2017) Convergence and determinants of health expenditures in OECD countries. Health Economics Review, 7(29).

Galoș Ioana, Florea Iulia Elena and Ene Maria Sara, Faculty of Cybernetics, Statistics and Economic Informatics, ASE Bucharest, 2026. Coordinator: Prof. Mihaela Covrig.
