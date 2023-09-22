#[Last updated] 16/02/2023

#to run this code alone, read the code below 
#include("readData.jl")

##### Create dummy nodes 
""""
  Create dummy nodes for bus stops and transit stops
"""
function dummy_create(TotalNum, n_charger_dummies, requestInfo, chargerInfo, xyInfo, CoordinatesInfo, VehicleInfo)
   #define the variables
   n_c = TotalNum.n_c; n_chst = TotalNum.n_chst; T_max = TotalNum.T_max; n_bs = TotalNum.n_bs; n_ts = TotalNum.n_ts
   TArrive = CoordinatesInfo.TArrive; x_init = CoordinatesInfo.x_init;y_init = CoordinatesInfo.y_init
   v_k = VehicleInfo.v_k; μ = VehicleInfo.μ
  
   
#set the parameter 
nodes_bs = Int64[] # bus stop dummies
nodes_ts = Int64[]# transit stop dummies
nodes = Int64[]#all dummy nodes
x_bs = Float64[] #x coordinate of bus stop dummies
y_bs = Float64[] #y coordintea of dummy bus stops 
x_ts = Float64[] # x coordinate of tranist station dummies 
y_ts = Float64[] # y coordinate of transit station dummies 
nodes_xy_bs_ts = Int64[] # temp matrix combine nodes and x-y coordinate of buses and ts
x = Float64[] # x coorinate of all nodes
y = Float64[] # y-coorindate of all nodes 

#to classify the nodes type 
NodeID_BS = 100000
NodeID_TS = 200000
#NodeID_TStype = 10000
NodeID_C = 300000
depot_start = 0
depot_end = 999999
#reqTraID

"""
   Create od pair for all requests 
"""
#find the first and last mile request id
indexFM = findall(x -> x == 0, requestInfo[:,"is_last"])
indexLM = findall(x -> x == 1, requestInfo[:,"is_last"])

#creates the pickup bus stop dummy
nodesPU = Vector{Int}(NodeID_BS*ones(length(indexFM))+requestInfo[indexFM,"id_request"])
#creates the drop-off bus stop dummy
nodesDO = Vector{Int}(NodeID_BS*ones(length(indexLM))+requestInfo[indexLM,"id_request"])
#creates the pickup tranist station dummy
nodesPUTS = Vector{Int}(NodeID_TS*ones(length(indexLM))+requestInfo[indexLM,"id_request"])
#creates the drop-off tranist station dummy
nodesDOTS = Vector{Int}(NodeID_TS*ones(length(indexFM))+requestInfo[indexFM,"id_request"])

#create the set of TS node for first mile and last mile
#Train_FM =Vector{Int}(timeTable[:,"id_train"]*2-ones(size(timeTable,1))) #drop-off TS for first mile
#Train_LM = timeTable[:,"id_train"]*2 #pick up TS for last mile

##create the set of pickup nodes and drop-off nodes 
PUnodes = reduce(vcat,[nodesPU,nodesPUTS,]) # first -> last
DOnodes = reduce(vcat,[nodesDOTS,nodesDO]) # first -> last

#od pair for fist mile and last mile
od_FM_LM = reduce(hcat,[PUnodes,DOnodes])
#connect the index for FM and LM 
index_FM_LM = reduce(vcat,[indexFM,indexLM])
#create the dictionary, if you put[customer ID], it will return OD pair 
nodes_od = Dict(index_FM_LM.=>[(od_FM_LM[i,1],od_FM_LM[i,2]) for i in 1:n_c])
#od pairs for all requests
request_od = Dict([(od_FM_LM[i,1],od_FM_LM[i,2]) for i in 1:n_c].=>index_FM_LM)

od_FM = reduce(hcat,[nodesPU,nodesDOTS])#od pair for first mile users
od_LM = reduce(hcat,[nodesPUTS,nodesDO]) #od pair for last mile users
#create the dictionary, if you put[customer ID], it will return OD pair 
#od_temp_2 = reduce(vcat,[od_FM, od_LM]) 

"""
   Create the x- and y-coordinate vectors for bus stops and transit stops 
"""
#create the array of dummy nodes for BS and TS
nodes_bs= Vector{Int}(NodeID_BS*ones(n_c)+requestInfo[:,"id_request"])
nodes_ts = Vector{Int}(NodeID_TS*ones(n_c)+requestInfo[:,"id_request"])
nodes_bs_ts = reduce(vcat,[nodes_bs,nodes_ts]) #combine the bus stops and transit stop

#create the array with coordinate of bus dummy nodes
x_bs = xyInfo[requestInfo[:,"id_bus_stop"],"x"]
y_bs = xyInfo[requestInfo[:,"id_bus_stop"],"y"]
#x_bs = xyInfo[requestInfo[:,"id_bus_stop"]+ones(Int64,size(requestInfo,1)),"x"]
#y_bs = xyInfo[requestInfo[:,"id_bus_stop"]+ones(Int64,size(requestInfo,1)),"y"]
#create the array with coordinate of transti dummyt nodes 
x_ts = ones(length(nodes_ts)).*xyInfo[n_bs+1:n_bs+n_ts,"x"]
y_ts = ones(length(nodes_ts)).*xyInfo[n_bs+1:n_bs+n_ts,"y"]

#Combine nodes and coordinate of bus stops and transit stops 
nodes_xy_bs_ts = sortslices(vcat(hcat(nodes_bs,x_bs,y_bs),hcat(nodes_ts,x_ts,y_ts)),dims = 1)

#extract nodes, x and y coordinate for bus stops and train stops 
nodes = Vector{Int}(nodes_xy_bs_ts[:,1])#dummy nodes for bus stops and transit stops
x = nodes_xy_bs_ts[:,2] # x coordinates of dummy nodes in nodes vector 
y = nodes_xy_bs_ts[:,3] # y coordinates of dummy nodes in nodes vector 

"""
Add chargers and its dummies in nodes and coordinates 
    Three dummies for each charger
"""
#ID number to distinguish the location and type of chargers 
NodeID_CST = 10000   #Charging station ID
#create the sets of charger dummy for each charging stations 

node_char_temp = Vector{Int64}[]
x_char_temp = Vector{Float64}[]
y_char_temp = Vector{Float64}[]
for i in 1:n_chst
      push!(node_char_temp, collect(NodeID_C+NodeID_CST*i+1:NodeID_C+NodeID_CST*i+sum(chargerInfo[i,["No_chargers"]])*n_charger_dummies))
      push!(x_char_temp,ones(sum(chargerInfo[i,["No_chargers"]])*n_charger_dummies).*chargerInfo[i,"x_char_station"])
      push!(y_char_temp,ones(sum(chargerInfo[i,["No_chargers"]])*n_charger_dummies).*chargerInfo[i,"y_char_station"])
end

#create the vector with dummay charger nodes
nodes_charger = reduce(vcat,node_char_temp)
#adds dummy charge nodes to all the nodes set
nodes = reduce(vcat,[nodes,nodes_charger])

# create coordinates for chargers 
x_charger = reduce(vcat,x_char_temp)
y_charger = reduce(vcat,y_char_temp)

# add charger coordinate to x and y 
x = reduce(vcat,[x,x_charger])
y = reduce(vcat,[y,y_charger])

"""
Add origin and destination depots to nodes and coordinates 
"""
#Add origin and destination depot nodes
nodes = reduce(vcat,[depot_start,nodes,depot_end])
##Add origin and destination coordinate 
x = reduce(vcat,[x_init[end],x,x_init[end]])
y = reduce(vcat,[y_init[end],y,y_init[end]])

# making the dictionary to recall the coordinate of each node 
##output if you type nodes_coordinates[Node number] it will return (x y) cooridnate
nodes_coordinates = Dict(nodes .=> [(x[i],y[i]) for i in 1:length(x)])

"""
   Creates the dictrionary for changes in NoP at each node
"""
# makes the array of [origin, destinations]nodes 
nodes_od_FM_LM = reshape(od_FM_LM,(length(od_FM_LM),1))
#add depots nodes 
nodes_od_FM_LM_depos = reduce(vcat,[0,nodes_od_FM_LM,0])
# make the array of changes in No of passengers corresponding to nodes_od array 
nop_temp = Vector{Int}[]
nop_temp = reduce(vcat,[requestInfo[indexFM,"No_person"],requestInfo[indexLM,"No_person"]])
NoP = reduce(vcat,[0,nop_temp,-nop_temp,0])

#Make the dictionary. if you tyep the [node number] it will return NoP getting on/off on that node 
NoP_bs_ts_nodes = Dict(nodes_od_FM_LM_depos .=>[NoP[i] for i in 1:length(NoP)])

"""
Time windows dummies_create for train stations 
"""
#time window at nodes except for transit stops are 0 to T_max
#create the dictionary, if you put the [nodes number], it will return (the earliest arrival time, the latest arrival time)
nodes_tw = Dict(keys(nodes_coordinates).=> repeat([(0.0,T_max)],length(nodes_coordinates)))
#the earlist arrival time at drop-off transit stop 
DO_tw_earliest = TArrive[indexFM] - ones(length(indexFM)).*10 #arrive 10 min befor the transit departure at earliest 
#the latest arrival time at drop-off tranist stop
DO_tw_latest = TArrive[indexFM]  #arrive 0 min befor the transit departure at latest  
#the earlist arrival time at pick-up transit stop 
PU_tw_earliest = TArrive[indexLM] #arrive 0 min before the transit arrival at earliest 
#the latest arrival time at pick-off transit stop 
PU_tw_latest = TArrive[indexLM] + ones(length(indexLM)).*10 #arrive 10 min after the transit arrival at latest 

#combine arrival time for drop-off and pick-up  
tw_earliest = reduce(vcat,[DO_tw_earliest,PU_tw_earliest]) #the earliest arrival time at ts
tw_latest = reduce(vcat,[DO_tw_latest,PU_tw_latest]) #the latest arrival time at ts
#combine the drop-off and pick-up tranist nodes 
nodes_do_pu = reduce(vcat,[nodesDOTS,nodesPUTS])

#modify the value of dictionary for transit nodes
for i in 1:length(tw_earliest)
    nodes_tw[nodes_do_pu[i]] = (tw_earliest[i],tw_latest[i]) 
end

"""
   Direct distance between bus stop to the transit station 
"""
#direct distnce from origin nodes to destination nodes 
dist_c_ts = Dict{Int,Float64}()
max_travel_time = Dict{Int,Float64}() #maximum in-vehilce time

for i in 1:n_c
    dist_c_ts[i] = euclidean(nodes_coordinates[nodes_od[i][1]],nodes_coordinates[nodes_od[i][2]])/v_k/1000
    max_travel_time[i] = dist_c_ts[i] * 1.5
end
"""
    Service time at the node i 
"""
u = Dict(nodes .=> 0.0)
for i in PUnodes
    u[i] = μ #constant serving time 
end
"""
Time windows dummies_create for bus nodes 
"""
#for the pick-up nodes for first mile service,
## e_i = max(0,e_n+i-L-u[i])
## l_i = min(l_n+1 -t_i_n+i - u[i], T_max)
for i in 1:length(indexFM)
   local e_i = max(0,nodes_tw[nodes_od[indexFM[i]][2]][1]-max_travel_time[indexFM[i]]-u[nodes_od[indexFM[i]][1]])
   local l_i = min(nodes_tw[nodes_od[indexFM[i]][2]][2]-dist_c_ts[indexFM[i]]-u[nodes_od[indexFM[i]][1]],T_max)
    nodes_tw[nodes_od[indexFM[i]][1]] = (e_i,l_i)
end

#for the drop-off nodes of the last mile service, 
#e_n_i = e_i + u_i + t_i_n+i
#l_n_i = max(l_i + u_i + L , T_max)

for i in 1:length(indexLM)
   local e_n_i = nodes_tw[nodes_od[indexLM[i]][1]][1]+dist_c_ts[indexLM[i]]+u[nodes_od[indexLM[i]][1]]
   local l_n_i = min(nodes_tw[nodes_od[indexLM[i]][1]][2]+u[nodes_od[indexLM[i]][1]]+max_travel_time[indexLM[i]],T_max)
   nodes_tw[nodes_od[indexLM[i]][2]] = (e_n_i,l_n_i)
end

#### store the outputs 

return nodes_output = (nodes_bs_ts=nodes_bs_ts,    
n_charger_dummies=n_charger_dummies,
nodes_charger=nodes_charger,
nodes=nodes,
PUnodes=PUnodes,
DOnodes = DOnodes,
nodes_od = nodes_od,
nodes_tw = nodes_tw,
u = u,
NoP_bs_ts_nodes = NoP_bs_ts_nodes,
max_travel_time = max_travel_time,
nodesPU = nodesPU,
nodesDO = nodesDO,
nodes_coordinates = nodes_coordinates,
nodesPUTS = nodesPUTS,
nodesDOTS = nodesDOTS,
nodes_bs = nodes_bs,
nodes_ts = nodes_ts)
end

"""
#for the last mile service, the time window to visit dropoff bus stop needs to be later than the time window at the train station
for i in 1:length(indexFM)
   nodes_tw[nodes_od[indexFM[i]][1]] = (nodes_tw[nodes_od[indexFM[i]][1]][1],nodes_tw[nodes_od[indexFM[i]][2]][1])
end

#for the first mile service, the time window to visit pickup bus stop needs to be eariler than the time window at the train station 
for i in 1:length(indexLM)
   nodes_tw[nodes_od[indexLM[i]][2]] = (nodes_tw[nodes_od[indexLM[i]][1]][2],nodes_tw[nodes_od[indexLM[i]][2]][2])
end
"""
