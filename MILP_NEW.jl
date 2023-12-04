function MILP_new(arcs_processed,Arcs_output,nodes_output,charger_par,
    vehicle_par,total_num,flag_new_formulation,cputimelimit,MaxCO2,TargetCO2,
    chargerInfo,requestInfo, xyInfo, Resultfolder,nodes_coordinates,CoordinatesInfo, n_type_veh)
       
    # variables passed from dummy_creates function
    nodes_bs_ts = nodes_output.nodes_bs_ts
    n_charger_dummies = nodes_output.n_charger_dummies
    nodes_charger = nodes_output.nodes_charger
    nodes = nodes_output.nodes
    PUnodes = nodes_output.PUnodes
    DOnodes = nodes_output.DOnodes
    nodes_od = nodes_output.nodes_od
    nodes_tw = nodes_output.nodes_tw
    nodes_bs = nodes_output.nodes_bs
    nodes_ts = nodes_output.nodes_ts
    u = nodes_output.u
    NoP_bs_ts_nodes = nodes_output.NoP_bs_ts_nodes
    max_travel_time = nodes_output.max_travel_time
    ## variables passed from Arcs_create function
    dist = Arcs_output.dist
    travel_time = Arcs_output.travel_time
    #variables passsed from preprocessing function
    Arcs = arcs_processed
    #read-Data
    n_charger = charger_par.n_charger
    alpha = charger_par.alpha
    n_c = total_num.n_c
    n_bs = total_num.n_bs
    n_ts = total_num.n_ts

    n_k = total_num.n_k
    n_kg = total_num.n_kg
    x_init = CoordinatesInfo.x_init
    y_init = CoordinatesInfo.y_init
    EnergyP = vehicle_par.EnergyP
    beta = vehicle_par.beta
    Q_max = vehicle_par.Q_max
    PC = vehicle_par.PC
    emission = vehicle_par.emission
    μ = vehicle_par.μ
    E_max = vehicle_par.E_max
    E_min = vehicle_par.E_min
    E_init = vehicle_par.E_init
    T_max = total_num.T_max
    ###############################
    # newly added TY, 2.12.2023
    #################################
    K_all = collect(1:n_k)
    n_type_veh = 2
    vec_K = [collect(1: n_kg),collect(n_kg+1:n_k)]
  
    Arcs_two_directions = Set()
    for (idx, arc) in enumerate(Arcs) 
        i, j = arc[1], arc[2] 
        (j, i) in Arcs &&  push!(Arcs_two_directions, arc)
    end
 
    ###################################

   """
    Prepare parameters
    """
    #Array all to bus stops (used for change of load)
    all_to_bs_ts = [(i, j) for (i, j) in Arcs if j in nodes_bs_ts]
    Arcs_0       = [(i, j) for (i, j) in Arcs if i != 0 && j != last(nodes)]
    M0 = length(Arcs) 
    @show( M0 )  
    # Dictionary charger->its dummies
    charger_dict = Dict()
    for i in 1:n_charger
        cgr = Int64[]
        for j in 1:n_charger_dummies
            push!(cgr, nodes_charger[(i-1)*n_charger_dummies+j])
        end
        charger_dict[i] = cgr
    end

    # other parameters
    VoWT = 1
    #ω = 20 # 20 minutes loss for customers to take public transport
    M1, = findmax(Q_max) # big M
    M2 = T_max # big M
    M3, = findmax(E_max)
    VoWT = 1 # Value of trave time 

    #chargres speed. Needs to be revised when extended to bi-level problem
    charger_speed = Dict(nodes_charger .=> [alpha[1] for i in 1:length(nodes_charger)])
    #time to change the charge from one vehicle to another vehicle 
    veh_switch_time = 5 #[sec]

    #subset of nodes 
    V = nodes[2:end-1] # nodes without depot
    V_0 = nodes[1:end-1] # nodes without destination depot
    V_N = nodes[2:end] # nodes without origin depot
 
    #arcs out of charger
    arcs_out_chargers = [(s, j) for (s, j) in Arcs if s in nodes_charger]


    """
    Code for the model "bi-level fleet size planning_MILP_22112022.pdf"
    """
    m = Model(Gurobi.Optimizer)

    # Decision variables  EQ[37]-[39]
    @variable(m, x[1:n_k, Arcs], Bin)  # EQ[37]routes for each vehicle Bin = binary 
    @variable(m, tau[n_kg+1:n_k, nodes_charger] >= 0) # EQ[39]set of charger node for each vehicle 
    # @variable(m, tau[1:n_k, nodes_charger] >= 0) # EQ[39]set of charger node for each vehicle 
    @variable(m, B[1:n_k, nodes] >= 0) #set of service beginning time of vehicle k at vertex i 
    @variable(m, Q[1:n_k, nodes] >= 0, Int) #current passenger load of each vehicle
    @variable(m, E[n_kg+1:n_k, nodes] >= 0) #charging state of each Vehicle Path 
    # Other variables 
    !flag_new_formulation && @variable(m, h[nodes_charger, nodes_charger, 1:n_k, 1:n_k], Bin)#EQ[36] 

    # @variable(m, E[1:n_k, nodes] >= 0) #charging state of each Vehicle Path 
    #############################################
    # added on 11/3/2023
    # tai-yu
    #############################################

    if flag_new_formulation == true
        Kᵉ = collect(n_kg+1:n_k)
        Pₙ = union(PUnodes, nodes[end])
        @variable(m, v[nodes_charger, Pₙ] >= 0) #charging state of each Vehicle Path 
    end
    Kᵍ = collect(1: n_kg) 

    ##################################################################
    # @variable(m, t >= 0) #set of service beginning time of vehicle k at vertex i 

    #Objective function EQ[8]
    #minimising energy consumption cost + purchasing cost
 
    @objective(m, Min, sum(EnergyP[k] * beta[k] * dist[arc] * x[k, arc] for k in 1:n_k for arc in Arcs) #operational cost 
                       + sum(PC[k] * x[k, (0, j)] for k in 1:n_k for j in V if (0, j) in Arcs))#Daily equivalent of purchasing & maintainance cost
    #EQ[10]-[13]
    @constraint(m, [k = 1:n_k], sum(x[k, (0, j)] for j in [PUnodes; nodes_charger; last(nodes)] if (0, j) in Arcs) == 1) #EQ[10] each vehicle start at the depot 
    @constraint(m, [k = 1:n_k], sum(x[k, (i, last(nodes))] for i in [0; DOnodes; nodes_charger] if (i, last(nodes)) in Arcs) == 1) #EQ[10] each vehicle end at the depot 
    ##users to be picked up by a vehicle EQ[11]
    @constraint(m, [j in PUnodes], sum(x[k, (i, j)] for k in 1:n_k for i in V_0 if (i, j) in Arcs) == 1) # for first-mile
    @constraint(m, [k = n_kg+1:n_k, s in nodes_charger], sum(x[k, (s, j)] for j in nodes if (s, j) in Arcs) <= 1) #EQ[12] only one e-vehicle can use a charger at one time 
    @constraint(m, [k = 1:n_kg, s in nodes_charger], sum(x[k, (s, j)] for j in V_N if (s, j) in Arcs) == 0)#EQ[13] gasolin vehicle cannot use the charger

    ##EQ[14] users picked up and dropped off by the same vehicle   
    @constraint(m, [k = 1:n_k, r = 1:n_c],
        sum(x[k, (i, nodes_od[r][1])] for i in V_0 if (i, nodes_od[r][1]) in Arcs)
        -
        sum(x[k, (nodes_od[r][2], j)] for j in V_N if (nodes_od[r][2], j) in Arcs) == 0)
    
    #EQ[15] Flow conservation
    @constraint(m, [k = 1:n_k, i in V], sum(x[k, (j, i)] for j in V_0 if (j, i) in Arcs)
                                        -
                                        sum(x[k, (i, j)] for j in V_N if (i, j) in Arcs) == 0)

    # Change of load
    # EQ[16][17] the passenger load of k is equl to current load of k + No. of get on/off passnegers at nodes j 
    ## when the vehicle k arrive at pickup/dropoff bs or ts 
    @constraint(m, [k = 1:n_k], Q[k, 0] == 0.0)
    @constraint(m, [k = 1:n_k, (i, j) in all_to_bs_ts],
        Q[k, j] >= Q[k, i] + NoP_bs_ts_nodes[j] - M1 * (1 - x[k, (i, j)]))
    @constraint(m, [k = 1:n_k, (i, j) in all_to_bs_ts],
        Q[k, j] <= Q[k, i] + NoP_bs_ts_nodes[j] + M1 * (1 - x[k, (i, j)]))

    #EQ[18] define the max vehicle load
    @constraint(m, [k = 1:n_k, i in nodes], Q_max[k] >= Q[k, i])

    # Beginning of service time and arrival time [19]-[25]
    @constraint(m, [k = 1:n_k], B[k, 0] == 0.0)   #beginning of the service time at the origin depot is 0
    @constraint(m, [k = 1:n_k, i in nodes], B[k, i] >= nodes_tw[i][1]) #[25] bus k should start the service later than the earliest time window
    @constraint(m, [k = 1:n_k, i in nodes], B[k, i] <= nodes_tw[i][2]) #[25]bus k should start the service earlier than the latest time window 

    @constraint(m, [k = 1:n_k, (i, j) in [(i, j) for (i, j) in Arcs if i ∉ nodes_charger]],
        B[k, j] >= B[k, i] + u[i] + travel_time[(i, j)] - M2 * (1 - x[k, (i, j)])) #[19]service starting time constraints at nodes EXCEPT charging stations          
    @constraint(m, [k in Kᵉ , (s, j) in [(s, j) for (s, j) in Arcs if s in nodes_charger]],
        B[k, j] >= B[k, s] + u[s] + tau[k, s] + travel_time[(s, j)] - M2 * (1 - x[k, (s, j)])) #[20]service starting time constraints at charging stations 
    # @constraint(m, [k = 1:n_k, (s, j) in [(s, j) for (s, j) in Arcs if s in nodes_charger]],
    #     B[k, j] >= B[k, s] + u[s] + tau[k, s] + travel_time[(s, j)] - M2 * (1 - x[k, (s, j)])) #[20]service starting time constraints at charging stations 

    #EQ[26]: Passenger in-vehicle time constraints 
    @constraint(m, [k = 1:n_k, r = 1:n_c], B[k, nodes_od[r][2]] - B[k, nodes_od[r][1]] - μ <= max_travel_time[r])

    # State of charge/gasolin 
    @constraint(m, [k = n_kg+1:n_k], E[k, 0] == E_init[k]) # EQ[24] initial charging state is charged in max
    @constraint(m, [k in Kᵉ, i in nodes], E_max[k] >= E[k, i] >= E_min[k]) #EQ[25] define the max and min state of energy capacity 
    # @constraint(m, [k = 1:n_kg], E[k, 0] == E_max[k])
    # @constraint(m, [k = 1:n_k, i in nodes], E_max[k] >= E[k, i] >= E_min[k]) #EQ[25] define the max and min state of energy capacity 

    ##Energy comsuptions #EQ[26]-EQ[27]
    @constraint(m, [k in Kᵉ, (i, j) in [(i, j) for (i, j) in Arcs if i ∉ nodes_charger]],
        E[k, j] >= E[k, i] - beta[k] * dist[(i, j)] - M3 * (1 - x[k, (i, j)])) #EQ[26] energy level decreases if a vehicle move from i to j 
    @constraint(m, [k in Kᵉ, (i, j) in [(i, j) for (i, j) in Arcs if i ∉ nodes_charger]],
        E[k, j] <= E[k, i] - beta[k] * dist[(i, j)] + M3 * (1 - x[k, (i, j)])) #EQ[27] energy level decreases if a vehicle move from i to j
    # @constraint(m, [k = 1:n_k, (i, j) in [(i, j) for (i, j) in Arcs if i ∉ nodes_charger]],
    #     E[k, j] >= E[k, i] - beta[k] * dist[(i, j)] - M3 * (1 - x[k, (i, j)])) #EQ[26] energy level decreases if a vehicle move from i to j 
    # @constraint(m, [k = 1:n_k, (i, j) in [(i, j) for (i, j) in Arcs if i ∉ nodes_charger]],
    #     E[k, j] <= E[k, i] - beta[k] * dist[(i, j)] + M3 * (1 - x[k, (i, j)])) #EQ[27] energy level decreases if a vehicle move from i to j

    ##Electric vehicle get charged at the charger #EQ[28]-EQ[29]
    @constraint(m, [k = n_kg+1:n_k, (s, j) in [(i, j) for (i, j) in Arcs if i in nodes_charger]],
        E[k, j] >= E[k, s] + charger_speed[s] * tau[k, s] - beta[k] * dist[(s, j)] - M3 * (1 - x[k, (s, j)]))
    @constraint(m, [k = n_kg+1:n_k, (s, j) in [(i, j) for (i, j) in Arcs if i in nodes_charger]],
        E[k, j] <= E[k, s] + charger_speed[s] * tau[k, s] - beta[k] * dist[(s, j)] + M3 * (1 - x[k, (s, j)]))

    # # added on 11/3/2023 tai-yu
    if flag_new_formulation == true
        @constraint(m, [s in nodes_charger, j in Pₙ], v[s, j] == sum(x[k, (s, j)] for k in Kᵉ))
        @constraint(m, [s in nodes_charger], sum(v[s, j] for j in Pₙ if (s, j) in arcs_out_chargers) <= 1)
        for o in 1:n_charger
            for idx_s in 1:n_charger_dummies-1
                l, h = charger_dict[o][idx_s], charger_dict[o][idx_s+1]
                @constraint(m, sum(v[h, j] for j in Pₙ) <= sum(v[l, j] for j in Pₙ))
                @constraint(m, sum(B[k, h] for k in Kᵉ) >= sum(B[k, l] for k in Kᵉ) + sum(tau[k, l] for k in Kᵉ)
                                                           -
                                                           M2 * (2 - sum(v[h, j] for j in Pₙ) - sum(v[l, j] for j in Pₙ)))
            end
        end
        @constraint(m, [s in nodes_charger, k in Kᵉ], tau[k, s] + B[k, s] <= M2 * sum(x[k, (s, j)] for j in Pₙ if (s, j) in arcs_out_chargers))
    else
        for o in 1:n_charger
            for k¹ in 1:n_k
                for k² in 1:n_k
                    if k¹ != k²
                        @constraint(m, [s¹ in charger_dict[o], s² in charger_dict[o]],
                            B[k², s²] >= B[k¹, s¹] + tau[k¹, s¹] - M2 * (1 - h[s¹, s², k¹, k²]))
                        @constraint(m, [s¹ in charger_dict[o], s² in charger_dict[o]],
                            B[k¹, s¹] >= B[k², s²] + tau[k², s²] - M2 * h[s¹, s², k¹, k²])
                        @constraint(m, [s¹ in charger_dict[o], s² in charger_dict[o]],
                            h[s¹, s², k¹, k²] + h[s², s¹, k², k¹] == 1)
                    end
                end
            end
        end
    end

    #CO2 emission constraints
    # @constraint(m, sum(emission[k]*dist[arc]*x[k,arc] for k in 1:n_k for arc in Arcs) <= MaxCO2*TargetCO2*0.01) 
    @constraint(m, sum(emission[k]*dist[arc]*x[k,arc] for k in  Kᵍ for arc in Arcs) <= MaxCO2*TargetCO2*0.01) 
 
     ################################################################
     # new constraints, 2.12.2023
     ################################################################
    #  @show(vec_K[1],vec_K[2],vec_K[1][1])
     for type_v in 1:n_type_veh 
        length_n_veh_type_v = length(vec_K[type_v])
        if length_n_veh_type_v>1
          for ss in 1:length_n_veh_type_v-1
              k, k1 = vec_K[type_v][ss], vec_K[type_v][ss+1]
            #   @show(k, k1)
              @constraint(m, sum(x[k, (0, j)] -  x[k1, (0, j)] for j in V if (0, j) in Arcs)>=0)
          end
       end
     end
     @constraint(m, [k in K_all], M0 * sum(x[k, (0, j)] for j in V if (0, j) in Arcs) >=  sum(x[k, (i, j)] for (i, j) in Arcs_0))
     @constraint(m, [(i, j) in Arcs_two_directions], sum(x[k, (i, j)] + x[k, (j, i)] for k in K_all) <=1 ) # this constr can be replaced by the first precedence constraint of Cordeau 2006

    ####################################################

    """
        Optimisation 
    """
    #Set the time limit
    set_optimizer_attribute(m, "Timelimit", cputimelimit* 60)
    runtime = @elapsed optimize!(m)

    """
       Getting and saving the key  outputs 
    """
    usedbus, total_chg_time, totalCO2 = process_results(
        chargerInfo, nodes_coordinates,
        requestInfo, xyInfo, x_init,y_init,
        n_bs, n_ts, n_c, n_k, n_kg, TargetCO2,
        Arcs, dist, Resultfolder,x,nodes,
        Q,B,E,tau,nodes_charger,emission,nodes_bs,nodes_ts
        )
    bestobj = objective_value(m) 
    gap = MOI.get(m, MOI.RelativeGap())
    used_gv = count(usedbus .> n_k-n_kg) 
    used_ev = count(usedbus .<= n_k-n_kg) 
     # Save to summary of key outputs
    keyoutput_vec = [bestobj, gap, used_gv, used_ev, totalCO2, total_chg_time, runtime]
    
    #save keyoutput_vec to a file just in case
    # rightnow = Dates.format(Dates.now(), "yyyy_mm_dd_HHMMSS")
    # fn_keyout = Resultfolder * string("Keyout_", n_bs, "bs_", n_c, "c_", n_k, "v_", n_kg, "gv_", TargetCO2, "%CO2_", rightnow)
    # writedlm(fn_keyout, keyoutput_vec) #save keyout just in case
  
    return keyoutput_vec

end


