########################################################
#To read data for fleet size and composition problem 
#[Last updated] 09/02/2023
# Haruko Nakao

#to run this file separately, run the code below 
#using DataFrames, CSV, Random, Distributions, Distances
########################################################

function readData(folderName,n_customer,per_init,total_num,coordinates_info,VehiclePar,ChargerPar)
#set the file name 
input_tt = folderName * "Timetable_6h_23h.csv"
input_parameter = folderName * "Parameters.csv"
input_xy = folderName * "Coordinate_6h_23h.csv"
input_vehicle = folderName * "VehicleInfo.csv"
input_cs = folderName * "CSInfo.csv"
input_request = folderName * "c_$(n_customer).csv"

#Read input files  
timeTable = DataFrame(CSV.File(input_tt))
vehicleInfo = DataFrame(CSV.File(input_vehicle))
requestInfo = DataFrame(CSV.File(input_request))
chargerInfo = DataFrame(CSV.File(input_cs))
xyInfo = DataFrame(CSV.File(input_xy))
per_set = DataFrame(CSV.File(input_parameter))

#################
#   total numbers
#################

n_c = nrow(requestInfo) # n_c, Number of requests 
n_ts = per_set[1, "no_train_station"] #n_ts: Number of transit stations
n_bs =  nrow(xyInfo) - 2 #: Number of bus stops
n_k = sum(eachrow(vehicleInfo[:, "fleet_size"]))[1] #: Total fleet size
n_kg = vehicleInfo[1, "fleet_size"] # :Total fleet size for gasoline vehicle
n_chst = nrow(chargerInfo) #: Number of charging stations
n_chtype = 2 #: Number of charging types
T_max = convert(Float64, timeTable.arrival_time[end]) + 20000 #: Time horizon
# Define the values for the struct
total_num = TotalNum(n_c, n_ts, n_bs, n_k, n_kg, n_chst, n_chtype, T_max)
    
#########################
#  Coordinate related info
##########################

# Coordinate of drop-offs, depot
x_init = xyInfo[:, 2] # x-coordinate for all nodes
y_init = xyInfo[:, 3] # y-coordinate for all nodes

# Coordinate for each pickup points and drop-off points
x_c = Float64[] # customers' x coordination
y_c = Float64[] # customers' y coordinate
reqTraID = Int64[] # ID of Transit service with customers
TArrive = Float64[] # Arrival time of transit service with customers

for i in 1:n_c
    push!(x_c, xyInfo[requestInfo[i, "id_bus_stop"], "x"])
    push!(y_c, xyInfo[requestInfo[i, "id_bus_stop"], "y"])
    push!(reqTraID, (2 * requestInfo[i, "id_train"] - 1) + requestInfo[i, "is_last"])
    push!(TArrive, timeTable[requestInfo[i, "id_train"], "arrival_time"])
end

coordinates_info = CoordinatesInfo(x_init, y_init, x_c, y_c, reqTraID, TArrive)

###################################
#  Vehicle specification parameters   
###################################

# Create vectors of vehicle info
Q_max = Int64[]
E_max = Float64[]
E_min = Float64[]
E_init = Float64[]
beta = Float64[]
PC = Float64[]
EnergyP = Float64[]
emission = Float64[]
μ = per_set[1, "service_time"]  # Service time per person
v_k = per_set[1, "vehicle_speed"]  # Bus speed km/min
v_type = per_set[1,"no_bus_type"] # number of vehicle types

for i_v in 1:v_type
     Q_max = reduce(vcat, [Q_max, fill(vehicleInfo[i_v, "cap_veh"], vehicleInfo[i_v, "fleet_size"])])
     E_max = reduce(vcat, [E_max, fill(vehicleInfo[i_v, "cap_fuel"], vehicleInfo[i_v, "fleet_size"])])
     E_min = reduce(vcat, [E_min, fill(vehicleInfo[i_v, "min_fuel"], vehicleInfo[i_v, "fleet_size"])])
     E_init = reduce(vcat, [E_init, fill(vehicleInfo[i_v, "cap_fuel"], vehicleInfo[i_v, "fleet_size"])])
     beta = reduce(vcat, [beta, fill(vehicleInfo[i_v, "energy_consumption"], vehicleInfo[i_v, "fleet_size"])])
     PC = reduce(vcat, [PC, fill(vehicleInfo[i_v, "daily_purchase_cost"], vehicleInfo[i_v, "fleet_size"])])
     EnergyP = reduce(vcat, [EnergyP, fill(vehicleInfo[i_v, "cost_energy"], vehicleInfo[i_v, "fleet_size"])])
     emission = reduce(vcat, [emission, fill(vehicleInfo[i_v, "CO2"], vehicleInfo[i_v, "fleet_size"])])
end

# Create the VehicleInfo structure
vehicle_par = VehiclePar(Q_max, E_max, E_min, E_init, beta, PC, EnergyP, emission, μ, v_k)

##################################
# Chargers specification parameters   
###################################


# Calculate the values
n_charger = sum(chargerInfo[:, "No_chargers"])
alpha_DC = per_set[1, "alpha_DC"]  # kW/min speed of DC charger
alpha = repeat([alpha_DC], n_charger)

# Create the ChargerInfo structure
charger_par = ChargerPar(n_charger, alpha_DC, alpha)

return total_num, requestInfo, charger_par, xyInfo, coordinates_info, vehicle_par, chargerInfo
end