function solve_model(pld_scenarios::DataFrame, generation_scenarios::DataFrame, 
                     Dmax_large_corps::Float64, Dmax_big_accounts::Float64, Dmax_trading::Float64, 
                     P_large_corps::Float64, P_big_accounts::Float64, P_trading::Float64, α::Float64, λ::Float64, trading_year::Int64;
                     seasonal_contract::String = "None", change_pld::Float64 = 1.0)
                   
    h = Dict{Int64,Int64}(i => Dates.daysinmonth(Date(trading_year, i)) * 24 for i in 1:12)
    
    T, num_scenarios = size(pld_scenarios)
    p                = ones(num_scenarios)/num_scenarios
    
    if !isequal(seasonal_contract, "None")
        Q_seasonal = (mean(Matrix(generation_scenarios), dims = 2)[:]).*.33
    end

    model = Model(Cbc.Optimizer)
    
    @variables(model, begin
        0 <= Q_large_corps[t in 1:T] 
        0 <= Q_big_accounts[t in 1:T] 
        0 <= Q_trading[t in 1:T]
        z
        δ[s in 1:nScen] >= 0
        R[t in 1:T, s in 1:nScen]
    end)

    if isequal(seasonal_contract, "large_corps")
        @constraint(model, [t = 1:T], 0 <= Q_large_corps[t] <= Q_seasonal[t])
    else
        @constraint(model, [t = 1:T - 1], Q_large_corps[t] == Q_large_corps[t + 1])
        @constraint(model, [t = 1:T], Q_large_corps <= Dmax_large_corps)
    end

    if isequal(seasonal_contract, "big_accounts")
        @constraint(model, [t = 1:T], 0 <= Q_big_accounts[t] <= Q_seasonal[t])
    else
        @constraint(model, [t = 1:T - 1], Q_big_accounts[t] == Q_big_accounts[t + 1])
        @constraint(model, [t = 1:T], Q_big_accounts <= Dmax_big_accounts)
    end

    if isequal(seasonal_contract, "trading")
        @constraint(model, [t = 1:T], 0 <= Q_trading[t] <= Q_seasonal[t])
    else
        @constraint(model, [t = 1:T - 1], Q_trading[t] == Q_trading[t + 1])
        @constraint(model, [t = 1:T], Q_trading <= Dmax_trading)
    end


    #@variable(VarModel, Q_tr[1:T])
    #@constraint(VarModel, [t = 1:T], 0 <= Q_tr[t] <= Q_tot_sazo[t])


    @constraint(VarModel, Revenue[t in 1:T, s in 1:nScen], R[t,s] == h[t]*((Pv_lc-pld_se[t,s])*Q_lc +
                                                                            (Pv_ba-pld_se[t,s])*Q_ba +
                                                                            (Pv_tr-pld_se[t,s])*Q_tr + 
                                                                            (g_pch[t,s])*pld_se[t,s]))
    @constraint(VarModel, Rest1[s in 1:nScen], δ[s] >= z - sum(R[t,s] for t in 1:T));

    Receita_media  = sum((R[t,s]*p[s]) for s in 1:nScen, t in 1:T)
    Receita_Cvar   = z - (1/(1-α))*sum(δ[s]*p[s] for s in 1:nScen);
    @objective(VarModel, Max, (1-λ)*Receita_media + λ*Receita_Cvar);

    optimize!(VarModel)
    stat = termination_status(VarModel)      

    Q_lc = value(Q_lc) 
    Q_ba = value(Q_ba)
    Q_tr = value.(Q_tr) 
    Receita_media = value(Receita_media)
    Receita_Cvar  = value.(Receita_Cvar)
    R_t  = value.(R)
    return Q_lc, Q_ba, Q_tr, Receita_media, Receita_Cvar, R_t

end