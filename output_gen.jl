# Result of x


function get_bus_path(n_k, Arcs,x,nodes)
    #get bus arcs
    bus_arcs = Dict{Int64,Array}()
    for k in 1:n_k
        active_arcs = []
        for arc in Arcs
            if value.(x[k, arc]) >= 0.99
                # println("vehicle $k visit arc $arc")
                push!(active_arcs, arc)
            end
        end
        bus_arcs[k] = active_arcs
    end
    #get bus paths 
    bus_path = Dict()
    for k in 1:n_k
        path = [0]
        path_id = [0]
        while path[end] != nodes[end]
            for arc in bus_arcs[k]
                if arc[1] == path[end]
                    push!(path, arc[2])
                    continue
                end
            end
        end
        bus_path[k] = path
    end
    usedbus = []
    for k in 1:n_k
    if length(bus_path[k]) > 2
        push!(usedbus, k)
    end
    end

    return bus_arcs, bus_path,usedbus
end

function get_output(dist,n_k,bus_path,Q,B,E,tau,nodes_charger,x,emission)
    # Result of change of load and arrival time
    change_of_load = Dict()
    service_begin_time = Dict()
    state_of_charge = Dict()
    charge_time = Dict()
    dist_path = Dict()
    total_chg_time = 0
    ##extract the id for used buses 
usedbus = []
for k in 1:n_k
    if length(bus_path[k]) > 2
        push!(usedbus, k)
    end
end

    for k in 1:n_k
        load = []
        sbt = []
        soc = []
        c_time = []

        dist_p = []
        for node in bus_path[k]
            push!(load, value.(Q[k, node]))
            push!(sbt, value.(B[k, node]))
            push!(soc, value.(E[k, node]))
            if node in nodes_charger
                push!(c_time, value.(tau[k, node]))
                total_chg_time +=value.(tau[k, node])
            end
        end
        change_of_load[k] = load
        service_begin_time[k] = sbt
        state_of_charge[k] = soc
        charge_time[k] = c_time

        for k in usedbus
            dist_p = []
            for i in 1:length(bus_path[k])-1
                push!(dist_p, dist[(bus_path[k][i], bus_path[k][i+1])])
            end
            dist_p = reduce(vcat, [0, dist_p])
            dist_path[k] = dist_p
        end

        dist_path[k] = dist_p
    end
    #estiamte the total CO2 emission 
    totalCO2 = value.(sum(emission[k]*dist[arc]*x[k,arc] for k in 1:n_k for arc in Arcs))
    return change_of_load, service_begin_time, state_of_charge, charge_time, dist_path,total_chg_time,totalCO2
end


