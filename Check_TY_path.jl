####################################################################
# Aim: Check if the distnace matrix is the same between me and Tai-you
# Haruko Nakao
# Last updated: 16/02/2023
##################################################################### 
using DataFrames, XLSX
using DataFrames, CSV, Random, Distributions, Distances #for readData.jl file 
using Combinatorics # for Arcs_create.jl file 
include("readData.jl")
include("dummy_create.jl")
include("Arcs_create.jl")
include("preprocessing.jl")

foldername = "C:\\Users\\haruko.nakao\\Desktop\\Julia_test\\fleet_size_problem_v16Feb23\\TaiYu_result_c40\\"
#read the excel file
route_1 = DataFrame(XLSX.readtable(foldername * "route_detail_r_1.xlsx", "Sheet1"))
route_2 = DataFrame(XLSX.readtable(foldername * "route_detail_r_2.xlsx", "Sheet1"))
route_3 = DataFrame(XLSX.readtable(foldername * "route_detail_r_3.xlsx", "Sheet1"))

# extract the bus paths
veh_route_1 = []
veh_route_2 = []
veh_route_3 = []

#modify the nodes number 
#Veh 1
veh_route_1 = Vector{Int}(route_1[:, "route"] - (ones(length(route_1[:, "route"]))))

for i in 2:length(veh_route_1)-1
    if veh_route_1[i] > 40
        temp_node = veh_route_1[i] - 40
        if requestInfo[temp_node, "is_last"] == 1 #lastmile
            veh_route_1[i] = temp_node + 100000
        else
            veh_route_1[i] = temp_node + 200000
        end
    else
        temp_node = veh_route_1[i]
        if requestInfo[temp_node, "is_last"] == 1 #lastmile
            veh_route_1[i] = veh_route_1[i] + 200000
        else
            veh_route_1[i] = veh_route_1[i] + 100000
        end
    end
end

veh_route_1[1] = 0
veh_route_1[end] = 999999

# Veh 2
veh_route_2 = Vector{Int}(route_2[:, "route"] - (ones(length(route_2[:, "route"]))))

for i in 2:length(veh_route_2)-1
    if veh_route_2[i] > 40
        temp_node = veh_route_2[i] - 40
        if requestInfo[temp_node, "is_last"] == 1 #lastmile
            veh_route_2[i] = temp_node + 100000
        else
            veh_route_2[i] = temp_node + 200000
        end
    else
        temp_node = veh_route_2[i]
        if requestInfo[temp_node, "is_last"] == 1 #lastmile
            veh_route_2[i] = veh_route_2[i] + 200000
        else
            veh_route_2[i] = veh_route_2[i] + 100000
        end
    end
end
veh_route_2[1] = 0
veh_route_2[end] = 999999

#Veh 3
veh_route_3 = Vector{Int}(route_3[:, "route"] - (ones(length(route_3[:, "route"]))))
for i in 2:length(veh_route_3)-1
    if veh_route_3[i] > 40
        temp_node = veh_route_3[i] - 40
        if requestInfo[temp_node, "is_last"] == 1 #lastmile
            veh_route_3[i] = temp_node + 100000
        else
            veh_route_3[i] = temp_node + 200000
        end
    else
        temp_node = veh_route_3[i]
        if requestInfo[temp_node, "is_last"] == 1 #lastmile
            veh_route_3[i] = veh_route_3[i] + 200000
        else
            veh_route_3[i] = veh_route_3[i] + 100000
        end
    end
end
veh_route_3[1] = 0
veh_route_3[end] = 999999

### Check the distance 
#vehicle 1
dist_1 = []
for i in 1:length(veh_route_1)-1
    push!(dist_1, dist[(veh_route_1[i], veh_route_1[i+1])])
end
dist_1
#vehicle 2 
dist_2 = []
for i in 1:length(veh_route_2)-1
    push!(dist_2, dist[(veh_route_2[i], veh_route_2[i+1])])
end

dist_3 = []
for i in 1:length(veh_route_3)-1
    push!(dist_3, dist[(veh_route_3[i], veh_route_3[i+1])])
end
vehcost = 48.510000000000005
oc = EnergyP[1] * beta[1]*(sum(dist_1)+sum(dist_2)+sum(dist_3))
totalcost = vehcost+oc
print(veh_route_2)
print(veh_route_1)