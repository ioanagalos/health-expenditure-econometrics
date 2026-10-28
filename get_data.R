# Downloads the 2022 World Bank data used in the project and saves it to data/.
# Only needed if you want to rebuild data/date_sanatate_2022.xlsx from scratch.
# Note: the World Bank revises its series, so a new download may differ slightly
# from the file in this repository (downloaded in 2026).

library(WDI); library(dplyr); library(writexl)

raw <- WDI(
  indicator = c(
    sanatate_pib = "SH.XPD.CHEX.GD.ZS",  # current health expenditure, % of GDP
    gdp_capita   = "NY.GDP.PCAP.CD",     # GDP per capita, current USD
    pop_65plus   = "SP.POP.65UP.TO.ZS",  # population aged 65+, % of total
    urbanizare   = "SP.URB.TOTL.IN.ZS",  # urban population, %
    somaj        = "SL.UEM.TOTL.ZS"      # unemployment rate, %
  ),
  country = "all", start = 2022, end = 2022, extra = TRUE
)

eu27 <- c("AT","BE","BG","CY","CZ","DE","DK","EE","ES","FI","FR","GR","HR","HU",
          "IE","IT","LT","LU","LV","MT","NL","PL","PT","RO","SE","SI","SK")

countries <- raw %>%
  filter(region != "Aggregates",
         !is.na(sanatate_pib), !is.na(gdp_capita), !is.na(pop_65plus)) %>%
  select(country, iso2c, region, income, sanatate_pib, gdp_capita,
         pop_65plus, urbanizare, somaj) %>%
  mutate(UE = ifelse(iso2c %in% eu27, 1, 0))

dir.create("data", showWarnings = FALSE)
write_xlsx(countries, "data/date_sanatate_2022.xlsx")
cat("Saved", nrow(countries), "countries to data/date_sanatate_2022.xlsx\n")
