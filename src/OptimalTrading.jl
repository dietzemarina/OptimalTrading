module OptimalTrading

    using JuMP
    using CSV
    using DataFrames
    using Dates
    using Statistics
    using Cbc

    include("optimization.jl")

    function optimal_trading(pld_scenarios::DataFrame, generation_scenarios::DataFrame, GF::Float64,
                                Qmax_large_corps::Float64, Qmax_big_accounts::Float64, Qmax_trading::Float64, 
                                P_large_corps::Float64, P_big_accounts::Float64, P_trading::Float64, α::Float64, λ::Float64, trading_year::Int64;
                                seasonal_contract::String = "None", change_pld::Float64 = 1.0)

        Q_large_corps, Q_big_accounts, Q_trading, 
            expected_revenue, cvar_revenue, revenue_scenarios = OptimalTrading.solve_model(pld_scenarios, generation_scenarios, GF,
                                                                                Qmax_large_corps, Qmax_big_accounts, Qmax_trading, 
                                                                                P_large_corps, P_big_accounts, P_trading, α, λ, trading_year;
                                                                                seasonal_contract = seasonal_contract, change_pld = change_pld)

        var_revenue    = quantile(sum(revenue_scenarios, dims =1)[:], 1 - α)
        median_revenue = median(sum(revenue_scenarios, dims = 1))
        metric         = λ * cvar_revenue + (1 - λ) * expected_revenue

        df_Q                 = DataFrame("Q_large_corps" => Q_large_corps, "Q_big_accounts" => Q_big_accounts, "Q_trading" => Q_trading)
        df_revenue_scenarios = DataFrame(revenue_scenarios, :auto)        
        df_resume            = DataFrame("Expected Revenue" => expected_revenue, "Median Revenue" => median_revenue,
                                         "CVaR" => cvar_revenue, "VaR" => var_revenue, "Risk" => expected_revenue - cvar_revenue,
                                         "Metric" => metric)      
                                        
        CSV.write("optimal_Q.csv", df_Q, delim = ";")
        CSV.write("revenue_scenarios.csv", df_revenue_scenarios, delim = ";")
        CSV.write("resume.csv", df_resume, delim = ";")

        return df_Q, df_revenue_scenarios, df_resume
    end

end 
