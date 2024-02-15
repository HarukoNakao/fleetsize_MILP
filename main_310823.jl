#[Last updated] 31/08/2023
#Set the working directory 
#cd("\\\\atlas.uni.lux\\users\\haruko.nakao\\Julia_test\\fleet size problem")
#pwd() #Check the working directory 

###### Read packages 
using DataFrames, CSV, Random, Distributions, Distances #for readData.jl file 
using Combinatorics # for Arcs_create.jl file 
using JuMP, Gurobi, Plots, DelimitedFiles, Dates, TypedTables # for this file using 
using MathOptInterface#using Pkg; Pkg.update("Gurobi") # to update gurobi 
const MOI = MathOptInterface


for ite_co2 = 1
    if ite_co2 == 1 
        TargetCO2 = 50
    else
        TargetCO2 = 10
    end
#set the name of folder storing the input data
dataset_name = "data_fleet_11082023_2"
folderName = string(dataset_name,"\\")

#Create the folder to store the output
rightnow = Dates.format(Dates.now(), "yyyy_mm_dd_HHMMSS")
Resultfolder =pwd()* string("\\result_",dataset_name,rightnow,"\\")
mkpath(Resultfolder)


#Input 
per_init = 0.5 #scaling initial chargig state from max capacity


#TargetCO2 =50#% of CO2 emission compared to the max CO2 emission 
flag_new_formulation = true
n_charger_dummies = 3 #number of dummy chargers 
#CO2 emission only with GVs 
#vec_MaxCO2 = [26.3277762667357, 39.139795180004, 58.2477553979516, 72.9762773948294, 85.5717411149149]
#instance2
vec_MaxCO2 = [21.8930173652438,36.5589008311427,62.9433663262955,71.9737296321299,93.9748123267374]
#instnace 3 
#vec_MaxCO2= [22.6820614802309,41.1723393162971,53.8177880600278,77.071818292654,93.8145726117127]

cputimelimit = 4*60 #[min] time limit for solving the problem
requests_set = [10, 20, 30, 40, 50] #number of requests

##Rread all the neccesary files
include("data_structure.jl")
include("readData.jl")
include("dummy_create.jl")
include("Arcs_create.jl")
include("preprocessing.jl")
include("MILP_NEW.jl")
include("output_gen.jl")
include("save_output.jl")
include("preprocessing_2.jl")

# Create the DataFrame to store the output
column_names = ["BKobj", "GAP_LB", "GV", "EV_1", "EV_2", "CO2", "TotalChargeTime", "Runtime"]
keyoutput_sum = DataFrame(; [(Symbol(name)) => Float64[] for name in column_names]...)


for ite = 4#:length(requests_set)
    n_customer = ite*10 #chose the number of requests 
    mkpath(Resultfolder*"\\c_$(n_customer)\\")
    input_request = folderName * "c_$(n_customer).csv" 
    MaxCO2 = vec_MaxCO2[Int64(ite)]#set the max CO2 emission
    ################
    #  MILP 
    #################
    #creates arcs and nodes for MILP_LR
    total_num, requestInfo, charger_par, xyInfo, coordinates_info, vehicle_par, chargerInfo = readData(folderName, n_customer, per_init, TotalNum, CoordinatesInfo, VehiclePar, ChargerPar)
   
    nodes_output = dummy_create(total_num, n_charger_dummies, requestInfo, chargerInfo, xyInfo, coordinates_info, vehicle_par)
    arcs_output = Arcs_create(nodes_output, vehicle_par.v_k, total_num.n_c)
    
    #arcs_processed = preprocess(arcs_output, nodes_output.nodes_tw)
    arcs_processed = preprocess_new(arcs_output, nodes_output.nodes_tw, nodes_output.nodesPU,nodes_output.nodes_od,nodes_output.max_travel_time,nodes_output.nodesDO)
    #incomp_req = incompatible_requests(arcs_output, nodes_output.nodes_od, nodes_output.max_travel_time)
    incomp_req_chr=incompatible_req_chr(arcs_output, nodes_output.nodes_od, nodes_output.nodes_charger,nodes_output.nodes_tw,arcs_processed)
    
    keyoutput_vec = MILP_new(arcs_processed,
     arcs_output, nodes_output, charger_par, vehicle_par, total_num, flag_new_formulation,
     cputimelimit, MaxCO2, TargetCO2,chargerInfo,requestInfo, xyInfo,Resultfolder,nodes_output.nodes_coordinates,coordinates_info,incomp_req_chr)
 
    #Append the output to keyoutput_sum
    push!(keyoutput_sum, keyoutput_vec) 

end

#save the summary output in the folder 
CSV.write(Resultfolder * "keyoutput.csv", keyoutput_sum)

end
