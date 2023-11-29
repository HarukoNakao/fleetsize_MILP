#######################################
#[last update] 08/02/2023
# by Haruko nakao
# Aim: preprocess and delete some unnecceasry arcs based on time window constraints 
#Based on Cordeau et al. 2003 A Branch-and-Cut Algorithm for the Dial-a-Ride Problem 
#######################################
#find the index of infeasible arcs 
"""
Old preprocessing function 

"""
function preprocess(Arcs_output, nodes_tw)
    Arcs = Arcs_output.Arcs
    travel_time = Arcs_output.travel_time
    index_delete = Int64[]
    #Preprocessing 1 
    for i in 1:length(Arcs)
        early_origin = nodes_tw[Arcs[i][1]][1]
        late_dest = nodes_tw[Arcs[i][2]][2]
        if late_dest < travel_time[Arcs[i][1], Arcs[i][2]] + early_origin
            push!(index_delete, i)
        end
    end

    sorted_index = sort(unique(index_delete))
    #delete those arcs from the Arc
    deleteat!(Arcs, sorted_index)
    return Arcs
end

"""
NEW preprocessing function 

"""

function preprocess_new(Arcs_output, nodes_tw, PUnodes, nodes_od, max_travel_time, DOnodes)
    Arcs = Arcs_output.Arcs
    travel_time = Arcs_output.travel_time
    index_delete = Int64[]
    #Preprocessing 1 
    for i in 1:length(Arcs)
        early_origin = nodes_tw[Arcs[i][1]][1]
        late_dest = nodes_tw[Arcs[i][2]][2]
        if late_dest < travel_time[Arcs[i][1], Arcs[i][2]] + early_origin
            push!(index_delete, i)
        end
    end

    #preprocessing 2
    for ite in 1:length(Arcs)
        if Arcs[ite][1] in PUnodes && Arcs[ite][2] in PUnodes
            i = Arcs[ite][1]
            j = Arcs[ite][2]
            n_i, key = find_second_element(nodes_od, i)
            if (j, n_i) in Arcs
                #Check if the travel time from i to j + from j to n_i and service time exceed max ride time
                if travel_time[(i, j)] + travel_time[(j, n_i)] > max_travel_time[key]
                    push!(index_delete, ite)
                    index_2 = findfirst(==((j, n_i)), Arcs)
                    push!(index_delete, index_2)
                end
            end
        end
    end

    #preproessing 3 
    for ite in 1:length(Arcs)
        if Arcs[ite][1] in PUnodes && Arcs[ite][2] in DOnodes
            i = Arcs[ite][1]
            n_j = Arcs[ite][2]
            n_i, key_1 = find_second_element(nodes_od, i)
            j, key_2 = find_first_element(nodes_od, n_j)
            if (j, i) in Arcs && (i, n_j) in Arcs && (n_j, n_i) in Arcs
                #Check if the travel time from i to j + from j to n_i and service time exceed max ride time
                if travel_time[(j, i)] + travel_time[(i, n_j)] + travel_time[(n_j, n_i)] > max_travel_time[key_1]
                    push!(index_delete, ite)
                end
            else
                push!(index_delete, ite)
            end
        end
    end
#=
    #preproessing 4 ; synmetry of preprocessing 3
    index_delete_4 = Int64[]
    for ite in 1:length(Arcs)

        if Arcs[ite][1] in DOnodes && Arcs[ite][2] in PUnodes
            n_i = Arcs[ite][1]
            j = Arcs[ite][2]
            i, key_1 = find_first_element(nodes_od, n_i)
            n_j, key_2 = find_second_element(nodes_od, j)
                #Check if the travel time from i to j + from j to n_i and service time exceed max ride time
                if travel_time[(i, n_i)] + travel_time[(n_i, j)] + travel_time[(j, n_j)] > max_travel_time[key_1]
                    push!(index_delete_4, ite)
                end
        end
    end
=#
    #preproessing 5
    for ite in 1:length(Arcs)
        if Arcs[ite][1] in PUnodes && Arcs[ite][2] in PUnodes
            i = Arcs[ite][1]
            j = Arcs[ite][2]
            n_i, key_1 = find_second_element(nodes_od, i)
            n_j, key_2 = find_second_element(nodes_od, j)
            if (j, n_i) in Arcs && (n_i, n_j) in Arcs && (n_j, n_i) in Arcs 
                #Check if the travel time from i to j + from j to n_i and service time exceed max ride time
                if travel_time[(i, j)] + travel_time[(j, n_i)] + travel_time[(n_i, n_j)] > max_travel_time[key_1] &&
                   travel_time[(i, j)] + travel_time[(j, n_j)] + travel_time[(n_j, n_i)] > max_travel_time[key_1]
                    push!(index_delete, ite)
                end
            else
                push!(index_delete, ite)
            end
        end
    end

    # preprocessing 6 :synmetry of preprocessing 5
    for ite in 1:length(Arcs)
        if Arcs[ite][1] in DOnodes && Arcs[ite][2] in DOnodes
            n_i = Arcs[ite][1]
            n_j = Arcs[ite][2]
            i, key_1 = find_first_element(nodes_od, n_i)
            j, key_2 = find_first_element(nodes_od, n_j)
            if (j, n_i) in Arcs && (i, n_j) in Arcs && (j,i) in Arcs && (i,j) in Arcs
                #Check if the travel time from i to j + from j to n_i and service time exceed max ride time
                if travel_time[(i, j)] + travel_time[(j, n_i)] + travel_time[(n_i, n_j)] >  max_travel_time[key_1] &&
                  travel_time[(j,i)] + travel_time[(i, n_j)] + travel_time[(n_i, n_j)] > max_travel_time[key_1]

                    push!(index_delete, ite)
                end
            else
                push!(index_delete, ite)
            end
        end
    end


    sorted_index = sort(unique(index_delete))
    #delete those arcs from the Arc
    deleteat!(Arcs, sorted_index)
    return Arcs
end

#fnction to find the second element of the tuple
function find_second_element(nodes_od, target_first_element)
    for (key, (first, second)) in nodes_od
        if first == target_first_element
            return second, key #return the second element and the key
        end
    end
    return nothing  # Return nothing if the element is not found
end

#fnction to find the first element of the tuple
function find_first_element(nodes_od, target_second_element)
    for (key, (first, second)) in nodes_od
        if second == target_second_element
            return first, key #return the first element and the key
        end
    end
    return nothing  # Return nothing if the element is not found
end

