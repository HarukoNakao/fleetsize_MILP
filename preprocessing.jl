#######################################
#[last update] 08/02/2023
# by Haruko nakao
# Aim: preprocess and delete some unnecceasry arcs based on time window constraints 
#Based on Cordeau et al. 2003 A Branch-and-Cut Algorithm for the Dial-a-Ride Problem 
#######################################
#find the index of infeasible arcs 
function preprocess(Arcs_output, nodes_tw)
    Arcs = Arcs_output.Arcs; travel_time = Arcs_output.travel_time
index_delete = Int64[]

for i in 1:length(Arcs)
    early_origin = nodes_tw[Arcs[i][1]][1]
    late_dest = nodes_tw[Arcs[i][2]][2]
    if late_dest < travel_time[Arcs[i][1], Arcs[i][2]] + early_origin
        push!(index_delete, i)
    end
end

#delete those arcs from the Arc
deleteat!(Arcs, index_delete)
return Arcs
end


#= 
for i in od_FM_LM[:,1]
    i_dest = od_FM_LM[findall(x -> x == i, od_FM_LM)[1][1], 2]
    for j in od_FM_LM[:,1]
        j_dest = od_FM_LM[findall(x -> x == j, od_FM_LM)[1][1], 2]
       
        ###Preprosessing 1 
        if (i,j_dest) in Arcs && i_dest !=j_dest
            early_tw_orgin = nodes_tw[j][1]
            late_dest = nodes_tw[i_dest][2]
            if (j, i) in Arcs && (i, j_dest) in Arcs && (j_dest, i_dest) in Arcs
              tt = travel_time[j, i] + travel_time[i, j_dest] + travel_time[j_dest, i_dest]
                #push!(candidate,i)
                if early_tw_orgin + tt > late_dest
                    temp_delete = findall(x -> x == (j, i_dest), Arcs)[1]
                    index_delete = reduce(vcat,[index_delete, temp_delete])
                elseif travel_time[j, i] + travel_time[i, j_dest] >max_travel_time[request_od[(j,j_dest)]]
                    index_delete = reduce(vcat,[index_delete, temp_delete])
                end
            end
        ###Preprosessing 2 
                elseif (i_dest,j) in Arcs && i!=j
            early_tw_orgin = nodes_tw[i][1]
            late_dest = nodes_tw[j_dest][2]
         if (i, i_dest) in Arcs && (i_dest, j) in Arcs && (j,j_dest) in Arcs
                tt = travel_time[i, i_dest] + travel_time[i_dest, j] + travel_time[j,j_dest]
                if early_tw_orgin + tt > late_dest
                    temp_delete = findall(x -> x == (i_dest, j), Arcs)[1]
                    push!(index_delete, temp_delete)
                end
            end
        ###Preprocessing 3
        elseif (i,j) in Arcs && i!=j
           if (i, j) in Arcs && (j, i_dest) in Arcs && (i_dest,j_dest) in Arcs && (j_dest,i_dest) in Arcs
                tt_1 = travel_time[i, j] + travel_time[j, i_dest] + travel_time[i_dest,j_dest]
                early_tw_orgin_1 = nodes_tw[i][1]
                late_dest_1 = nodes_tw[j_dest][2]

                tt_2 = travel_time[i, j] + travel_time[j, j_dest] + travel_time[j_dest,i_dest]
               early_tw_orgin_2 = nodes_tw[i][1]
               late_dest_2 = nodes_tw[i_dest][2]

                if early_tw_orgin_1 + tt_1 > late_dest_1 && arly_tw_orgin_2 + tt_2 > late_dest_2 && tt_2 > max_travel_time[request_od[(i,i_dest)]]
                    temp_delete = findall(x -> x == (i, j), Arcs)[1]
                    push!(index_delete, temp_delete)
                end
            end
        ###Preprocessing 4
        elseif (i_dest,j_dest) in Arcs && i!=j
            if (i, j) in Arcs && (j, i_dest) in Arcs && (i_dest,j_dest) in Arcs && (j,i) in Arcs
                tt_1 = travel_time[i, j] + travel_time[j, i_dest] + travel_time[i_dest,j_dest]
                early_tw_orgin_1 = nodes_tw[i][1]
                late_dest_1 = nodes_tw[j_dest][2]

                tt_2 = travel_time[j, i] + travel_time[j, j_dest] + travel_time[i_dest,j_dest]
                early_tw_orgin_2 = nodes_tw[j][1]
                late_dest_2 = nodes_tw[i_dest][2]

                if early_tw_orgin_1 + tt_1 > late_dest_1 && arly_tw_orgin_2 + tt_2 > late_dest_2 && tt_2 > max_travel_time[request_od[(j,j_dest)]]
                    temp_delete = findall(x -> x == (i_dest,j_dest), Arcs)[1]
                    push!(index_delete, temp_delete)
                end
            end
        end
    end
end
index_delete = sort!(unique!(index_delete))
=#
