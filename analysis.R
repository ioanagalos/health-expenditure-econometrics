# Determinants of public health expenditure (% of GDP), cross-section 2022
# Author: Galoș Ioana, ASE Bucharest, Faculty of Cybernetics, Statistics and Economic Informatics
#
# Run from the project folder: source("analysis.R")
# Data: data/date_sanatate_2022.xlsx (World Bank WDI, 2022; rebuilt by get_data.R)

library(readxl); library(dplyr); library(ggplot2)
library(lmtest); library(sandwich); library(car)
library(moments); library(gridExtra)

dir.create("figures", showWarnings = FALSE)

# ---- 1. Data ----------------------------------------------------------------
# Countries with GDP per capita under 1,000 USD are excluded (extreme outliers),
# which leaves 168 countries out of 188.

df <- read_excel("data/date_sanatate_2022.xlsx") %>%
  filter(!is.na(sanatate_pib), !is.na(gdp_capita), !is.na(pop_65plus),
         gdp_capita > 1000, sanatate_pib > 1) %>%
  mutate(log_gdp = log(gdp_capita),
         UE      = as.factor(UE))

cat("=== DATA ===\n")
cat("Observations:", nrow(df), "| EU:", sum(df$UE == 1), "| Non-EU:", sum(df$UE == 0), "\n")
print(summary(df[, c("sanatate_pib", "gdp_capita", "pop_65plus")]))

# ---- 2. Simple regression ---------------------------------------------------

cat("\n=== SIMPLE REGRESSION ===\n")
model_uni <- lm(sanatate_pib ~ log_gdp, data = df)
print(summary(model_uni))

b1 <- coef(model_uni)[2]
cat("Slope:", round(b1, 4), "| a 1% rise in GDP per capita adds about",
    round(b1 / 100, 5), "pp to health spending (% of GDP)\n")

p1 <- ggplot(df, aes(x = log_gdp, y = sanatate_pib)) +
  geom_point(aes(color = UE), size = 2.5, alpha = 0.8) +
  geom_smooth(method = "lm", se = TRUE, color = "#1F497D", linewidth = 1) +
  scale_color_manual(values = c("0" = "#E07B39", "1" = "#2E86AB"),
                     labels = c("0" = "Non-EU", "1" = "EU")) +
  labs(title = "Figure 1. Health expenditure vs. log(GDP per capita)",
       x = "log(GDP per capita, USD)", y = "Health expenditure (% of GDP)", color = "") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(size = 10, face = "bold"), legend.position = "bottom")
ggsave("figures/figure1_scatter.png", p1, width = 7, height = 5, dpi = 150)

# F test and t tests
fs <- summary(model_uni)$fstatistic
cat("\nF =", round(fs[1], 4), "| p =",
    format(pf(fs[1], fs[2], fs[3], lower.tail = FALSE), digits = 3), "\n")

ct <- summary(model_uni)$coefficients
ci95 <- confint(model_uni, level = 0.95)
cat("Two-sided t test: t =", round(ct[2, 3], 4), "| p =", format(ct[2, 4], digits = 4), "\n")
cat("95% CI for slope: [", round(ci95[2, 1], 4), ";", round(ci95[2, 2], 4), "]\n")

p_right <- pt(ct[2, 3], df = model_uni$df.residual, lower.tail = FALSE)
cat("Right-tailed test (H1: slope > 0): p =", format(p_right, digits = 4), "\n")

# ---- 3. Diagnostics ---------------------------------------------------------

cat("\n=== DIAGNOSTICS ===\n")
white <- bptest(model_uni, ~ fitted(model_uni) + I(fitted(model_uni)^2))
bp    <- bptest(model_uni)
df$res_abs <- abs(residuals(model_uni))
glj_f <- summary(lm(res_abs ~ log_gdp, data = df))$fstatistic
glj_p <- pf(glj_f[1], glj_f[2], glj_f[3], lower.tail = FALSE)
cat("White:         p =", round(white$p.value, 4), "\n")
cat("Breusch-Pagan: p =", round(bp$p.value, 4), "\n")
cat("Glejser:       p =", round(glj_p, 4), "\n")

dw <- dwtest(model_uni)
bg <- bgtest(model_uni, order = 2)
cat("Durbin-Watson:   DW =", round(dw$statistic, 4), "| p =", round(dw$p.value, 4), "\n")
cat("Breusch-Godfrey: p =", round(bg$p.value, 4), "\n")

res <- residuals(model_uni)
cat("Jarque-Bera:  p =", round(jarque.test(res)$p.value, 4), "\n")
cat("Shapiro-Wilk: p =", round(shapiro.test(res)$p.value, 4), "\n")

ph <- ggplot(data.frame(r = res), aes(x = r)) +
  geom_histogram(aes(y = after_stat(density)), bins = 20, fill = "#2E86AB", color = "white", alpha = 0.8) +
  stat_function(fun = dnorm, args = list(mean = mean(res), sd = sd(res)), color = "#E07B39", linewidth = 1.2) +
  labs(title = "Figure 2a. Residual histogram", x = "Residuals", y = "Density") +
  theme_minimal(base_size = 10)
pq <- ggplot(data.frame(r = res), aes(sample = r)) +
  stat_qq(color = "#2E86AB", size = 1.5) + stat_qq_line(color = "#E07B39", linewidth = 1) +
  labs(title = "Figure 2b. Q-Q plot", x = "Theoretical quantiles", y = "Sample quantiles") +
  theme_minimal(base_size = 10)
pr <- ggplot(data.frame(fit = fitted(model_uni), r = res), aes(x = fit, y = r)) +
  geom_point(color = "#2E86AB", alpha = 0.7, size = 2) +
  geom_hline(yintercept = 0, color = "#E07B39", linewidth = 1, linetype = "dashed") +
  labs(title = "Figure 2c. Residuals vs. fitted", x = "Fitted values", y = "Residuals") +
  theme_minimal(base_size = 10)
ggsave("figures/figure2_diagnostics.png", arrangeGrob(ph, pq, pr, ncol = 2),
       width = 10, height = 7, dpi = 150)

cat("\nRobust standard errors (HC3):\n")
print(coeftest(model_uni, vcov = vcovHC(model_uni, type = "HC3")))

# ---- 4. Forecast ------------------------------------------------------------

cat("\n=== FORECAST (max GDP per capita + 10%) ===\n")
nd <- data.frame(log_gdp = log(max(df$gdp_capita) * 1.10))
print(predict(model_uni, nd, interval = "prediction", level = 0.95))
print(predict(model_uni, nd, interval = "confidence", level = 0.95))

# ---- 5. Multiple regression -------------------------------------------------

cat("\n=== MULTIPLE REGRESSION ===\n")
model_multi <- lm(sanatate_pib ~ log_gdp + pop_65plus + UE, data = df)
print(summary(model_multi))

cat("\nVIF:\n"); print(round(vif(model_multi), 3))
cat("\nCorrelation of predictors:\n")
print(round(cor(df[, c("log_gdp", "pop_65plus")]), 3))

cat("\nBreusch-Pagan:   p =", round(bptest(model_multi)$p.value, 4), "\n")
cat("Breusch-Godfrey: p =", round(bgtest(model_multi, order = 2)$p.value, 4), "\n")
cat("Shapiro-Wilk:    p =", round(shapiro.test(residuals(model_multi))$p.value, 4), "\n")
if (bptest(model_multi)$p.value < 0.05) {
  cat("Heteroscedasticity detected, robust standard errors (HC3):\n")
  print(coeftest(model_multi, vcov = vcovHC(model_multi, type = "HC3")))
}

# ---- 6. Interaction model ---------------------------------------------------

cat("\n=== INTERACTION MODEL (log_gdp x EU) ===\n")
model_inter <- lm(sanatate_pib ~ log_gdp * UE + pop_65plus, data = df)
print(summary(model_inter))

ci <- coef(model_inter)
cat("Slope of log_gdp, non-EU:", round(ci["log_gdp"], 4), "\n")
cat("Slope of log_gdp, EU:    ", round(ci["log_gdp"] + ci["log_gdp:UE1"], 4), "\n")

p3 <- ggplot(df, aes(x = log_gdp, y = sanatate_pib, color = UE, shape = UE)) +
  geom_point(size = 2.5, alpha = 0.8) +
  geom_smooth(method = "lm", se = TRUE, aes(fill = UE), alpha = 0.15) +
  scale_color_manual(values = c("0" = "#E07B39", "1" = "#2E86AB"), labels = c("0" = "Non-EU", "1" = "EU")) +
  scale_fill_manual(values = c("0" = "#E07B39", "1" = "#2E86AB"), labels = c("0" = "Non-EU", "1" = "EU")) +
  scale_shape_manual(values = c("0" = 16, "1" = 17), labels = c("0" = "Non-EU", "1" = "EU")) +
  labs(title = "Figure 3. Health expenditure vs. log(GDP per capita), EU vs. non-EU",
       x = "log(GDP per capita, USD)", y = "Health expenditure (% of GDP)",
       color = "", fill = "", shape = "") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(size = 10, face = "bold"), legend.position = "bottom")
ggsave("figures/figure3_eu_interaction.png", p3, width = 7, height = 5, dpi = 150)

# ---- 7. Model comparison ----------------------------------------------------

cat("\n=== MODEL COMPARISON ===\n")
cat(sprintf("%-15s | %6s | %8s | %8s\n", "Model", "R2", "Adj. R2", "F"))
for (m in list(list(model_uni, "Simple"), list(model_multi, "Multiple"),
               list(model_inter, "Interaction"))) {
  s <- summary(m[[1]])
  cat(sprintf("%-15s | %6.4f | %8.4f | %8.2f\n",
              m[[2]], s$r.squared, s$adj.r.squared, s$fstatistic[1]))
}
