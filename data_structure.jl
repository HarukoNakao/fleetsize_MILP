#Total number
struct TotalNum
    n_c::Int64 #Number of requests
    n_ts::Int64 #Number of transit stations
    n_bs::Int64 #Number of bus stops
    n_k::Int64 #Total fleet size 
    n_kg::Int64 #Total fleet size for gasolin vehicle 
    n_chst::Int64 #Number of charging stations 
    n_chtype::Int64 #Number of charging types 
    T_max::Float64 # time horizon
end
struct CoordinatesInfo
    x_init::Vector{Float64}
    y_init::Vector{Float64}
    x_c::Vector{Float64}
    y_c::Vector{Float64}
    reqTraID::Vector{Int64}
    TArrive::Vector{Float64}
end
# create vector of info related to each vehicle 
struct VehiclePar
    Q_max::Vector{Int64}        # Vehicle passenger capacity
    E_max::Vector{Float64}      # Battery capacity (kW maximum state of charge)
    E_min::Vector{Float64}      # kW minimum state of charger
    E_init::Vector{Float64}     # kW initial state of charger
    beta::Vector{Float64}       # kW/km energy consumption for each vehicle
    PC::Vector{Float64}         # Daily equivalent of purchasing/maintenance cost for each vehicle
    EnergyP::Vector{Float64}    # Energy price per unit for each vehicle
    emission::Vector{Float64}   # CO2 emission
    μ::Float64                  # Service time per person
    v_k::Float64                # Bus speed (km/min)
    fleetsize_list::Vector{Int64} # Fleet size for each vehicle
end
struct ChargerPar
    n_charger::Int64    # Number of chargers
    alpha_DC::Float64   # kW/min speed of DC charger
    alpha::Vector{Float64}  # kW/min speed of chargers (DC charger speed repeated for all chargers)
end