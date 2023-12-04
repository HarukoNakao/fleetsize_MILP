function process_results(
    chargerInfo, nodes_coordinates,
    requestInfo, xyInfo, x_init,y_init,
    n_bs, n_ts, n_c, n_k, n_kg, TargetCO2,
    Arcs, dist, Resultfolder,x,nodes,
    Q,B,E,tau,nodes_charger,emission,nodes_bs,nodes_ts
    )

    ### set the name for resultsfolder
    # Resultfolder = resultfolder * "c_$(n_c)\\"
    # Resultfolder = resultfolder 

    """
       #summarise and store the results 
    """
    bus_arcs, bus_path,usedbus = get_bus_path(n_k, Arcs,x,nodes)
    change_of_load, service_begin_time, state_of_charge, charge_time, dist_path,total_chg_time,totalCO2 = get_output(dist,n_k,bus_path,Q,B,E,tau,nodes_charger,x,emission)

    #println("\n")
    #println("\nPaths of  buses:\n$(bus_path)")
    #println("\n")
    #println("\nActive_arcs:\n$(bus_arcs)")

    ##extract the id for used buses 

    println("\n")
    println("Change of load: $(change_of_load)")
    println("\n")
    println("SOC: $(state_of_charge)")
    println("\n")
    println("Charge time: $(charge_time)")

    #save the outputs as txt file 
    # rightnow = Dates.format(Dates.now(), "yyyy_mm_dd_HHMMSS")
    # fn_buspath = Resultfolder * string("BusPath_", n_bs, "bs_", n_c, "c_", n_k, "v_", n_kg, "gv_", TargetCO2, "%CO2_", rightnow)
    # #fn_arriveT = Resultfolder * string("ArriveT_", n_bs, "bs_", n_c, "c_", n_k, "v_", n_kg, "gv_", MaxCO2, "%CO2_", rightnow)
    # fn_serviceBT = Resultfolder * string("ServeBeginT_", n_bs, "bs_", n_c, "c_", n_k, "v_", n_kg, "gv_", TargetCO2, "%CO2_", rightnow)
    # fn_SOC = Resultfolder * string("SOC_", n_bs, "bs_", n_c, "c_", n_k, "v_", n_kg, "gv_", TargetCO2, "%CO2_", rightnow)
    # fn_COL = Resultfolder * string("COL_", n_bs, "bs_", n_c, "c_", n_k, "v_", n_kg, "gv_", TargetCO2, "%CO2_", rightnow)
    # fn_CT = Resultfolder * string("ChargeT_", n_bs, "bs_", n_c, "c_", n_k, "v_", n_kg, "gv_", TargetCO2, "%CO2_", rightnow)
    
    # writedlm(fn_buspath, bus_path) #save bus path 
    # #writedlm(fn_arriveT, arrival_time) #save arrival time
    # writedlm(fn_serviceBT, service_begin_time)
    # writedlm(fn_SOC, state_of_charge) #save state of charge
    # writedlm(fn_COL, change_of_load) #save the change of load 
    # writedlm(fn_CT, charge_time) #save charge time 
    
    #Creates the summary table 
    nodes_reqID = Dict(nodes_bs .=> requestInfo[:, "id_request"])

    for k in usedbus
        summary = []
        bus_stops = []
        for inode in bus_path[k]
            if inode in nodes_bs
                push!(bus_stops, requestInfo[nodes_reqID[inode], "id_bus_stop"])
            elseif inode in nodes_ts
                push!(bus_stops, 111111)
            elseif inode in [0, 999999]
                push!(bus_stops, 999999)
            else
                push!(bus_stops, 3333333)
            end
        end
        # summary = DataFrame(id_request=bus_path[k], bs=bus_stops, change_of_load=change_of_load[k], service_time=service_begin_time[k], distance=dist_path[k])
        #fn_summary = Resultfolder * string("Summary_Vehicle#",k,"_",n_bs, "bs_", n_c, "c_", n_k, "v_", n_kg, "gv_", MaxCO2, "%CO2_", rightnow)
        # fn_summary_csv = Resultfolder * string("Summary_Vehicle#", k, "_", n_bs, "bs_", n_c, "c_", n_k, "v_", n_kg, "gv_", TargetCO2, "%CO2_", rightnow, ".csv")
        # fn_summary_csv = Resultfolder  
      
        #writedlm(fn_summary, summary) 
        # CSV.write(fn_summary_csv, summary)

    end
    
    """
       #Plot the results
    """
    # Plot the instace 
    #set of active bus stops 
    activeBS = requestInfo[:, "id_bus_stop"]
    activeBS = Int.(activeBS)

    title!("Instance")
    fig_instance = scatter((chargerInfo[:, "x_char_station"], chargerInfo[:, "y_char_station"]), label="Charging stations", markersize=10, markershape=:utriangle, color=:white, legend=:bottomleft)
    scatter!((nodes_coordinates[0][1], nodes_coordinates[0][2]),
        xlims=(-10000, 10000), ylims=(-10000, 10000),
        label="Depot", markersize=8, markershape=:star, color=:Green)
    plot!(legend=:outerright, legendcolumns=3)
    scatter!((xyInfo[activeBS, "x"], xyInfo[activeBS, "y"]), label="Stops", markershape=:circle, color=:blue, series_annotations=text.(requestInfo[:, "id_request"], :bottom))
    scatter!((x_init[n_bs+1:n_ts+n_bs], y_init[n_bs+1:n_ts+n_bs]), label="Transit stops", markershape=:square, color=:red)

    savefig(fig_instance, Resultfolder * "\\Instance")


    for k in usedbus
        fig = plot()
        for i in 1:length(bus_path[k])-1
            x_vec = reduce(vcat, [nodes_coordinates[bus_path[k][i]][1], nodes_coordinates[bus_path[k][i+1]][1]])
            y_vec = reduce(vcat, [nodes_coordinates[bus_path[k][i]][2], nodes_coordinates[bus_path[k][i+1]][2]])
            plot!(x_vec, y_vec, arrow=true, color=:black, linewidth=1, label="", legend=:bottomleft)
        end
        title!(string("Vehicle Path #", k))
        scatter!((nodes_coordinates[0][1], nodes_coordinates[0][2]),
            xlims=(-10000, 10000), ylims=(-10000, 10000),
            label="Depot", markersize=8, markershape=:star, color=:Green)
        plot!(legend=:outerright, legendcolumns=3)
        scatter!((xyInfo[activeBS, "x"], xyInfo[activeBS, "y"]), label="Stops", markershape=:circle, color=:blue, series_annotations=text.(requestInfo[:, "id_request"], :bottom))
        scatter!((x_init[n_bs+1:n_ts+n_bs], y_init[n_bs+1:n_ts+n_bs]), label="Transit stops", markershape=:square, color=:red)


        #create the file name for the figure 
        filefig = string("Vehicle Path#", k, "_", n_bs, "bs_", n_c, "c_", n_k, "v_", n_kg, "gv_", TargetCO2, "%CO2")
        #save figure 
        savefig(fig, Resultfolder * filefig)
    end
    
  return usedbus,total_chg_time,totalCO2
end