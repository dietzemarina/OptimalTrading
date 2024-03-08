import Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
include("src/OptimalTrading.jl")

pld_scenarios = CSV.read("src\\data\\PLD_SE.csv", DataFrame)[:,2:end]
generation_scenarios = CSV.read("src\\data\\simul_pch.csv", DataFrame)[:,2:end]


λ  = 0.99  # risk aversion parameter: λCVaR + (1-λ)Expected_Revenue
α  = 0.95  # VaR and CVaR α
GF = 17.5  # Garantia Fisica of the hydro generation

#max demand of each client restricted to 33% of GF
Qmax_large_corps  = 0.33
Qmax_big_accounts = 0.33
Qmax_trading      = 0.33

#Constracts selling prices
P_large_corps = 180.
P_big_accounts = 170.
P_trading = 160.

trading_year = 2019

seasonal_contract = "trading"


df_Q, df_revenue_scenarios, df_resume = OptimalTrading.optimal_trading(pld_scenarios, generation_scenarios, GF,
                                                            Qmax_large_corps, Qmax_big_accounts, Qmax_trading, 
                                                            P_large_corps, P_big_accounts, P_trading, α, λ, trading_year;
                                                            seasonal_contract = "None", change_pld = 1.0)