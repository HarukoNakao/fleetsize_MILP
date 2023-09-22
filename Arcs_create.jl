#[last updated]13/02/2023

"""
Create Arcs for buses
    1. Arcs from origin depot to 1)pickup bus stops (BS), 2)pickup transit stops (TS),3) chargers and destination depot
    2. Arcs from chargers to 1)pickup BS, 2)pickup TS and 3)destionation depot
    3. Arcs from pickup BS to 1)pickup BS and 2)drop-off TS 
    4. Arcs from drop-off BS to 1)drop-off BS, 2)chargers and 3)destination depot 
    5. Arcs from pick up TS to 1)pickup TS and 2)drop-off BS
    6. Arcs from drop-off TS to 1)drop-off TS, 2)pickup TS, 3)chargers and 4)destiantion depot
"""

#create the function to create Arcs and its distance and travel time 
## input x_temp: origin node number, y_temp:destination node number 
function networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
    push!(Arcs,(x_temp,y_temp))
    dist[(x_temp,y_temp)] = euclidean(nodes_coordinates[x_temp],nodes_coordinates[y_temp])/1000
    travel_time[(x_temp,y_temp)] = euclidean(nodes_coordinates[x_temp],nodes_coordinates[y_temp])/1000/v_k
   # min: nodes_coordinate is m, v_k is km/min
    return (Arcs, dist, travel_time)
end

function Arcs_create(nodes_output, v_k,n_c)
    nodes_charger = nodes_output.nodes_charger;
    nodesPU = nodes_output.nodesPU;
    nodesDO = nodes_output.nodesDO;
    nodes = nodes_output.nodes; 
    nodes_coordinates = nodes_output.nodes_coordinates;
    nodesPUTS = nodes_output.nodesPUTS;
    nodesDOTS = nodes_output.nodesDOTS
    nodes_bs = nodes_output.nodes_bs
    nodes_ts = nodes_output.nodes_ts
    nodes_od = nodes_output.nodes_od
#prepare values
   Arcs = Tuple{Int64, Int64}[]
   dist = Dict{Tuple, Float64}()
   travel_time = Dict{Tuple, Float64}()

"""
   Arcs from orgin depot and to destination depot
    1. from origin depot to destination depot
    2. between depot and chargers 
    3. between depot and BS
    4. between depot and BS
"""
#1:  Arcs from origin depot to destination depot
x_temp = nodes[1]
y_temp = last(nodes)
global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)

#2: Arcs from origin depot to chargers and from chargers to destination depot
for cgr in nodes_charger
    #origin depot to chargers
    local x_temp = nodes[1]
    local y_temp = cgr
    global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
       
    #Chargers from destination depot 
    local x_temp = cgr
    local y_temp = last(nodes)
    global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
end

#3: Arcs from origin depot to bs and bs to destintion depot 
## from origin depot to pickup bus stops
for ite in nodesPU
    local x_temp = nodes[1]
    local y_temp = ite
    global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
end 
## from drop-off bs to the last depot
for ite in nodesDO
    local x_temp = ite
    local y_temp = last(nodes)
    global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
end
Arcs
#4:Arcs between origin and destination depot and tranist stops
##origin depot to pickup TS for Last mile
for ts in nodesPUTS #pickup TS
    local x_temp = nodes[1]
    local y_temp = ts
    global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
end
##dropoff TS for First mile to destination TS
for ts in nodesDOTS #dropoff TS
    local x_temp = ts
    local y_temp = last(nodes)
    global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
end
"""
   Arcs related to bus stops 
    1. between BS and BS
    2. between BS and chargers
    3. between BS and TS
"""
##1: Arcs between bus stop and bus stop
Arcs_bs_bs_1 = collect(combinations(nodes_bs,2)) #one direction 
Arcs_bs_bs_2 = collect(combinations(reverse(nodes_bs),2)) #another direction 
#combine them and make the set of arcs between bs and bs
Arcs_bs_bs = reduce(vcat,[Arcs_bs_bs_1, Arcs_bs_bs_2])

for ite in 1:(length(Arcs_bs_bs)) #dropoff TS
    local x_temp = Arcs_bs_bs[ite][1]
    local y_temp = Arcs_bs_bs[ite][2]
    global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
end

#2 Arcs between bus stop and charger 
for cgr in nodes_charger
    #Create the set of arcs from drop-off bs to chargers 
    for bs_do in nodesDO
        local x_temp = bs_do
        local y_temp = cgr
        global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
    end
    #Create the set of arcs from chargers to pick-ups 
    for bs_pu in nodesPU
        local x_temp = cgr
        local y_temp = bs_pu
        global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
    end
end

#3: Arcs between bus stops and transit stops
#ts to bs

for ts in nodes_ts
    for bs in nodes_bs
        local x_temp = ts
        local y_temp = bs
        global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
    end
end
#bs to ts
for ts in nodes_ts
    for bs in nodes_bs
        local x_temp = bs
        local y_temp = ts
        global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
    end
end


#=
## pickup bs to drop-off ts 
for i in 1:(size(od_FM,1))
    local x_temp = od_FM[i,1] #pick-up bs
    local y_temp = od_FM[i,2] #drop-off ts
    global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
end
##pickup ts to drop-off bs
for i in 1:(size(od_LM,1))
    local x_temp = od_LM[i,1] #pickup train station
    local y_temp = od_LM[i,2] #drop-off bs
    global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)  
end

## pickup ts to other pickup bs 
for puts in nodesPUTS
    #nextPUBS = nodesPU[findall(nodesPU .> puts)]
    nextPUBS = nodesPU
        for pu in nextPUBS
            local x_temp = puts #pickup train station
            local y_temp = pu #drop-off bs
            global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
        end
end
# drop-off transit stop to  pickup bs 
for dots in nodesDOTS
    #nextPUBS = nodesPU[findall(nodesPU .> dots)]
    nextPUBS = nodesPU
        for pu in nextPUBS
            local x_temp = dots 
            local y_temp = pu 
            global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
        end
end

# drop-off bs to  pickup ts 
for dobs in nodesDO
    #nextPUTS = nodesPUTS[findall(nodesPUTS .> dobs)]
    nextPUTS = nodesPUTS
        for puts in nextPUTS
            local x_temp = dobs 
            local y_temp = puts 
            global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
        end
end
=#

"""
   Rest of the arcs involving TS
     1. between TS and chargers 
     2. between TS and TS  
"""
#1: Arcs between transit stations and chargers 
for cgr in nodes_charger
    #Create the set of arcs from drop-off bs to chargers 
    for ts_do in nodesDOTS
        local x_temp = ts_do 
        local y_temp = cgr 
        global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
    end
    #Create the set of arcs from chargers to pick-ups 
    for ts_pu in nodesPUTS
        local x_temp = cgr 
        local y_temp = ts_pu 
        global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
    end
end

#2: Arcs between transit stops  

## this part needs to be revised if the NO. of TS >1 
#between drop-off transit station 
Arcs_dots = collect(combinations(nodesDOTS,2))  #only smaller No nodes to larger No nodes 
for ite in 1:(length(Arcs_dots)) #dropoff TS
    local  x_temp = Arcs_dots[ite][1]
    local y_temp = Arcs_dots[ite][2]
    global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
end
#between pick-up transit station 
Arcs_puts =collect(combinations(nodesPUTS,2)) #only smaller No nodes to larger No nodes 
for ite in 1:(length(Arcs_puts)) #dropoff TS
    local x_temp = Arcs_puts[ite][1]
    local y_temp = Arcs_puts[ite][2]
    global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
end
#drop-off to pickup
for puts in nodesPUTS
    for dots in nodesDOTS
        #if puts>dots #only smaller No nodes to larger No nodes 
            local x_temp = dots
            local y_temp = puts
            global Arcs,dist,travel_time = networkcreate(x_temp,y_temp,v_k, Arcs,nodes_coordinates,dist,travel_time)
        #end
    end
end


"""
Create Arcs for customers
"""
# Arcs for customers
#Arcs_c = []
Arcs_c = Tuple{Int64, Int64}[] 
for i in 1:n_c
    push!(Arcs_c, nodes_od[i])
end

return Arcs_output = (Arcs = Arcs,travel_time = travel_time,dist = dist)
end