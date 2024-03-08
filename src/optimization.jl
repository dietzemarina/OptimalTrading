function solve_model(pld_scenarios::DataFrame, generation_scenarios::DataFrame, GF::Float64,
                     Qmax_large_corps::Float64, Qmax_big_accounts::Float64, Qmax_trading::Float64, 
                     P_large_corps::Float64, P_big_accounts::Float64, P_trading::Float64, α::Float64, λ::Float64, trading_year::Int64;
                     seasonal_contract::String = "None", change_pld::Float64 = 1.0)
                   
    
    #getting the simulation horizon and number of scenarios
    T, num_scenarios = size(pld_scenarios)

    #calculating the number of hours of each month in the year of simulation
    h = Dict{Int64,Int64}(i => Dates.daysinmonth(Date(trading_year, i)) * 24 for i in 1:T)

    #probability of each scenarios (equiprobable scenarios)
    p = ones(num_scenarios)/num_scenarios
    
    #defines the seasonality of contracts
    if !isequal(seasonal_contract, "None")
        Q_seasonal = (mean(Matrix(generation_scenarios), dims = 2)[:])
    end

    #define some change in pld scenarios (shift all the scenrios up or downwards)
    pld_scenarios = pld_scenarios .* change_pld

    model = Model(Cbc.Optimizer)
    
    @variables(model, begin
        0 <= Q_large_corps[t in 1:T] 
        0 <= Q_big_accounts[t in 1:T] 
        0 <= Q_trading[t in 1:T]
        z
        δ[s in 1:num_scenarios] >= 0
        R[t in 1:T, s in 1:num_scenarios]
    end)

    #limits the maximum Q to contract for each client
    if isequal(seasonal_contract, "large_corps")
        @constraint(model, [t = 1:T], 0 <= Q_large_corps[t] <= Q_seasonal[t]*Qmax_large_corps)
    else
        @constraint(model, [t = 1:T - 1], Q_large_corps[t] == Q_large_corps[t + 1])
        @constraint(model, [t = 1:T], Q_large_corps[t] <= Qmax_large_corps * GF)
    end

    if isequal(seasonal_contract, "big_accounts")
        @constraint(model, [t = 1:T], 0 <= Q_big_accounts[t] <= Q_seasonal[t]*Qmax_big_accounts)
    else
        @constraint(model, [t = 1:T - 1], Q_big_accounts[t] == Q_big_accounts[t + 1])
        @constraint(model, [t = 1:T], Q_big_accounts[t] <= Qmax_big_accounts * GF)
    end

    if isequal(seasonal_contract, "trading")
        @constraint(model, [t = 1:T], 0 <= Q_trading[t] <= Q_seasonal[t] * Qmax_trading)
    else
        @constraint(model, [t = 1:T - 1], Q_trading[t] == Q_trading[t + 1]*Qmax_trading)
        @constraint(model, [t = 1:T], Q_trading[t] <= Qmax_trading * GF)
    end
    
    #revenue calculation for each month and scenario
    @constraint(model, Revenue[t in 1:T, s in 1:num_scenarios], R[t, s] == h[t] * ((P_large_corps-pld_scenarios[t,s])*Q_large_corps[t] +
                                                                            (P_big_accounts-pld_scenarios[t,s])*Q_big_accounts[t] +
                                                                            (P_trading-pld_scenarios[t,s])*Q_trading[t] + 
                                                                            (generation_scenarios[t,s])*pld_scenarios[t,s]))
    #CVaR constraint
    @constraint(model, Rest_cvar[s in 1:num_scenarios], δ[s] >= z - sum(R[t,s] for t in 1:T));

    #expected revenue calculation
    expected_revenue = sum((R[t,s] * p[s]) for s in 1:num_scenarios, t in 1:T)
    
    #CVaR calculation
    cvar_revenue     = z - (1/(1 - α)) * sum(δ[s] * p[s] for s in 1:num_scenarios);
    
    #objective value of the model as being a convex combination between CVaR and Expected Revenue
    @objective(model, Max, (1 - λ)*expected_revenue + λ * cvar_revenue);

    optimize!(model)
    if termination_status(model) == MOI.OPTIMAL
        printstyled("Optimization was successfully solved!\n"; color = :green) 
    else
        printstyled("Error in the optimization problem!\n"; color = :red)
    end

    Q_large_corps     = value.(Q_large_corps) 
    Q_big_accounts    = value.(Q_big_accounts)
    Q_trading         = value.(Q_trading) 
    expected_revenue  = value(expected_revenue)
    cvar_revenue      = value.(cvar_revenue)
    revenue_scenarios = value.(R)
    
    return Q_large_corps, Q_big_accounts, Q_trading, expected_revenue, cvar_revenue, revenue_scenarios
end

using CSV, DataFrames
