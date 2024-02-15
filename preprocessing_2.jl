#########################
#   This script is used to find the infeasible requests pair to be served by the same vehicle 
#   based on Cordeau (2006)
#
#    by Haruko 
#    on 05th Feb 2024
#########################

#there will be some pairs of requests which cannot be served by the same vehicle
#becuase of the detour factor 

function incompatible_requests(Arcs_output, nodes_od, max_travel_time)
    Arcs = Arcs_output.Arcs
    travel_time = Arcs_output.travel_time
    infeasible_pair = []
    
    for req_1 = 1:length(nodes_od)
        for req_2 = 1:length(nodes_od)
            if req_1 == req_2
                continue 
            end
            i = nodes_od[req_1][1]
            i_n = nodes_od[req_1][2]
            j = nodes_od[req_2][1]
            j_n = nodes_od[req_2][2]

            if (i,j) in Arcs && (j,i_n) in Arcs &&
                travel_time[(i,j)]+travel_time[(j,i_n)] > max_travel_time[req_1]
                @show(req_1,req_2)
                push!(infeasible_pair, (req_1,req_2))
            elseif (j,i) in Arcs && (i,j_n) in Arcs && 
                travel_time[(j,i)]+travel_time[(i,j_n)] > max_travel_time[req_2]
                @show(req_1,req_2)
                push!(infeasible_pair, (req_1,req_2))
                
            end

        end 
    end
    return infeasible_pair
end

function incompatible_req_chr(Arcs_output, nodes_od, nodes_charger,nodes_tw,arcs_processed)
    Arcs = arcs_processed
    travel_time = Arcs_output.travel_time
    incomp_req_chr = Tuple{Int64, Int64}[]
    
    for req_1 = 1:length(nodes_od)
        for req_2 = 1:length(nodes_od)
            if req_1 == req_2
                continue 
            end
            i = nodes_od[req_1][1]
            i_n = nodes_od[req_1][2]
            j = nodes_od[req_2][1]
            j_n = nodes_od[req_2][2]
            s = nodes_charger[1]

            early_i_n = nodes_tw[i_n][1]
            late_j = nodes_tw[j][2]
            early_j_n = nodes_tw[j_n][1]
            late_i = nodes_tw[i][2]

            if (i_n,s) in Arcs && (s,j) in Arcs && (j_n,s) in Arcs && (s,i) in Arcs &&
                early_i_n+travel_time[(i_n,s)]+travel_time[(s,j)] >late_j &&
                early_j_n+travel_time[(j_n,s)]+travel_time[(s,i)] >late_i
                @show(req_1,req_2)
                push!(incomp_req_chr, (req_1,req_2))               
            end

        end 
    end
    return incomp_req_chr
end