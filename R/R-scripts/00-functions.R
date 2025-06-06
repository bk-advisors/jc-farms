jc_dashboard_kpis <- function(data, batch_num, num_birds) {
  
  # KPI-1 - Total Revenues
  
  # Filter data for selected batch only
  
  filtered_data <- data |> 
    filter(Batch_Number == batch_num) |> 
    
    # Filter for Revenue only
    filter(Select.Account.Type == "Revenues")
  
  # Revenues by Batch Number
  revenues_by_batch <- filtered_data %>%
    group_by(Batch_Number) %>%
    summarise(Total_Revenue = sum(Amount_UGX, na.rm = TRUE))
  
  batch_rev <- revenues_by_batch %>% 
    select(Total_Revenue) %>% 
    pull()
  
  batch_rev_final <- format(batch_rev, big.mark = ",", scientific = FALSE)
  
  
  # KPI-2 - Total Cost (of Production)
  
  # Filter data for selected batch only
  
  filtered_data <- data |> 
    filter(Batch_Number == batch_num) |> 
    
    # Filter for COGS and OPEX
    filter(Select.Account.Type == "Cost of Goods Sold (COGS)" | Select.Account.Type == "Operating Expenditure (OPEX)" )
  
  # Total Cost by Batch Number
  cost_by_batch <- filtered_data %>%
    group_by(Batch_Number) %>%
    summarise(Total_Cost = sum(Amount_UGX, na.rm = TRUE))
  
  batch_cost <- cost_by_batch %>% 
    select(Total_Cost) %>% 
    pull()
  
  batch_cost_final <- format(batch_cost, big.mark = ",", scientific = FALSE)
  
  
  # KPI-3 - Net Profit
  
  
  net_profit <- batch_rev - batch_cost  
  net_profit_final <- format(net_profit, big.mark = ",", scientific = FALSE)
  
  
  # KPI-4 Cost Per Bird
  
  total_birds <- num_birds
  
  cost_per_bird <- round(batch_cost/total_birds,digits = 0)
  
  cost_per_bird_final <- format(cost_per_bird, big.mark = ",", scientific = FALSE)
  
  
  # KPI-5 Profit per Bird
  
  profit_per_bird <- round(net_profit/total_birds,digits = 0)
  
  profit_per_bird_final <- format(profit_per_bird, big.mark = ",", scientific = FALSE)
  
  # Create a list of KPIs
  
  kpi_list <- c(batch_rev_final,batch_cost_final,net_profit_final,cost_per_bird_final,profit_per_bird_final)
  
  kpi_list
  
}

jc_pnl_by_batch <- function(data, batch_num) {
  
  # Read CSV data
  transactions <- data
  
  # Filter and aggregate Batch_4 data
  batch <- transactions %>%
    filter(Select.Batch.Number == batch_num) %>%
    mutate(
      Category = case_when(
        Select.Account.Type == "Revenues" ~ Select.Category.3,
        Select.Account.Type == "Cost of Goods Sold (COGS)" ~ Select.Category.2,
        Select.Account.Type == "Operating Expenditure (OPEX)" ~ Select.Category.1,
        TRUE ~ NA_character_
      ),
      Amount = as.numeric(gsub(",", "", Amount..UGX.))
    ) %>%
    filter(!is.na(Category)) %>%
    group_by(Category) %>%
    summarise(Batch_X = sum(Amount, na.rm = TRUE))
  
  #Sub-setting the 1 cell I want to change
  batch$Category[5] <- "Sales Revenue"
  
  # Create full category structure
  categories <- data.frame(
    Category = c(
      "Revenues", "Sales Revenue", "Cost of Goods Sold (COGS)", "Feed Costs",
      "Veterinary Supplies", "Chicks Purchased", "Other Direct Costs",
      "Operating Expenses (OPEX)", "Salaries and Wages", "Utilities (Electricity, Water, etc.)",
      "Transportation Costs", "Marketing Expenses", "Other Operating Expenses",
      "Net Profit/Loss"
    )
  )
  
  # Merge with categories and fill missing values
  
  batch_full <- categories %>%
    left_join(batch, by = "Category") %>%
    mutate(Batch_X = coalesce(Batch_X, 0)) %>%
    # Calculate totals
    mutate(Batch_X = case_when(
      Category == "Revenues" ~ sum(Batch_X[Category == "Sales Revenue"]),
      Category == "Cost of Goods Sold (COGS)" ~ sum(Batch_X[Category %in% c("Feed Costs", "Veterinary Supplies", "Chicks Purchased", "Other Direct Costs")]),
      Category == "Operating Expenses (OPEX)" ~ sum(Batch_X[Category %in% c("Salaries and Wages", "Utilities (Electricity, Water, etc.)", "Transportation Costs", "Marketing Expenses", "Other Operating Expenses")]),
      TRUE ~ Batch_X
    ))
  
  # Calculate Net Profit/Loss
  
  batch_full <- batch_full |> 
    mutate(
      Batch_X = ifelse(
        Category == "Net Profit/Loss",
        Batch_X[Category == "Revenues"] - 
          (Batch_X[Category == "Cost of Goods Sold (COGS)"] + 
             Batch_X[Category == "Operating Expenses (OPEX)"]),
        Batch_X
      )
    )
  
  colnames(batch_full)[2] <- batch_num
  
  batch_full
  
  
}
