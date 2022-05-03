using Random, Distributions, Plots, XLSX

######## Initial functions to load lambda and mu from the ArrivalProfiles.xlsx ##########

# Change the type to Float64 from Int and String for the loaded vectors
function type_change(v)
    v_ny = Vector{Float64}()
    for i in 1:length(v)
        if typeof(v[i]) == String
            push!(v_ny,parse(Float64,v[i]))
        elseif typeof(v[i]) == Int64
            push!(v_ny,float(v[i]))
        else
            push!(v_ny,v[i])
        end
    end
    return v_ny
end

function load_arri(path="C:/Users/rasmu/OneDrive - Danmarks Tekniske Universitet/Onedrive/OneDrive - Danmarks Tekniske Universitet/Decisions under uncertainty/Projekt/ArrivalProfiles.xlsx")
    xf = XLSX.readxlsx(path)

    # Lambda is given as expected arrivals therefore inverse
    lambda_port = 1 ./ type_change(xf[1]["C2:Z2"])
    lambda_dtu = 1 ./ type_change(xf[1]["C3:Z3"])

    # Travel time
    mu_rammer_dtu = type_change(xf[1]["C7:Z7"])
    mu_rammer_port = type_change(xf[1]["C8:Z8"])

    return lambda_port, lambda_dtu, mu_rammer_dtu, mu_rammer_port
end

# Inserts a value at the spot it fits, used to create a priority queue
function insert_and_sort!(vect::Vector, x)
    (splice!(vect, searchsorted(vect,x), [x]); vect) 
end

########## Structs and initial loading ###########

struct Environment # The environment including arrival rates and travel rates
    lambda_dtu::Vector{Float64}  #arrival rate 1
    mu_rammer_dtu::Vector{Float64} #service rate 1
    lambda_port::Vector{Float64} # arrival rate 2
    mu_rammer_port::Vector{Float64} #service rate 2
    
    # loading the vectors from excel
    lambda_port, lambda_dtu, mu_rammer_dtu, mu_rammer_port = load_arri()
    Environment() = new(lambda_port, lambda_dtu, mu_rammer_dtu, mu_rammer_port)
end

mutable struct Stats # Vector including [Station 1, Station 2]
    n_cars::Vector{Int64} # Number of cars at the stations at any given time
    un_fullfilled::Vector{Int64} # Amount of times a customer arrives to an empty station
    fullfilled::Vector{Int64} # Amount of times a costumer arrives and gets a car
    empty_time::Vector{Float64} # The amount of time any given station has 0 cars
    currently_empty::Vector{Bool} # Is the station currently empty empty
end

struct Balance # The rebalance
    desired::Array{Tuple{Int64,Int64},1} # The desired rebalance amounts [(station 1,station 2), (station 1, station 2)]
    rebalance_times::Vector{Float64} # The desired rebalance times [1.0,3.23]
end

######### The Functions of the Simulation ##########
function time_change(e::Array{Tuple{Float64,String},1},day::Int64) # Used for changing the rates at an hourly basis
    # Switch day and reset rate index
    if k == 24
        global k = 0 # Rate index
        global day += 24 # Day
    end
    # Insert the next time change one day later
    popfirst!(e)[1]
    insert_and_sort!(e,(k+day,"time_change"))

    # Change rate index
    global k += 1
end

#### Costumer arriving at the station and taking a car if avaiable
function arrival_student(station::Int64,e::Array{Tuple{Float64,String},1},env::Environment,stat::Stats) 
    # Insert next arrival based on previous arrival and what station
    if station == 1
        insert_and_sort!(e,(rand(Exponential(env.lambda_dtu[k]))+e[1][1],"st1"))
    elseif station == 2
        insert_and_sort!(e,(rand(Exponential(env.lambda_port[k]))+e[1][1],"st2"))
    end

    if stat.currently_empty[station] == true # Student arrives at empty station.
        stat.un_fullfilled[station] += 1 # Unfullfilled
        popfirst!(e) # Remove the arrival
        
    else # Student arrives at a full station and leaves
        stat.n_cars[station] -= 1 # removing car from station
        stat.fullfilled[station] += 1 # one fullfilled request
        
        # Insert travel time based on arrival station
        if station == 1 
            insert_and_sort!(e,(rand(Exponential(env.mu_rammer_port[k]))+e[1][1],"que_st2")) 
        elseif station == 2
            insert_and_sort!(e,(rand(Exponential(env.mu_rammer_dtu[k]))+e[1][1],"que_st1")) 
        end

        if stat.n_cars[station] == 0 # station becomes empty
            stat.empty_time[station] -= popfirst!(e)[1] # Empty station timer starts 
            stat.currently_empty[station] = true # Station is empty
        else
            popfirst!(e) 
        end
    end 

end 

#### Vehicle arriving at the station
function arrival_vehicle(station::Int64,e::Array{Tuple{Float64,String},1},stat::Stats) # Vehicle arriving at the station
    if stat.currently_empty[station] == true # Arriving at an empty station
        stat.n_cars[station] += 1
        stat.empty_time[station] += popfirst!(e)[1] # End empty timer
        stat.currently_empty[station] = false 
    else
        stat.n_cars[station] += 1 # arrive
        popfirst!(e) 
    end

end

# Rebalancing event
function rebalancing(rebal::Balance,stat::Stats,env::Environment,e::Array{Tuple{Float64,String},1})
    # Assuming traveling vehicles are a part of the total amount of cars at a given station

    # Checking the amount of travelling vehicles
    travel_count_1 = 0
    travel_count_2 = 0
    for i in 1:length(e)
       if e[i][2] == "que_st1"
           travel_count_1 += 1
       elseif e[i][2] == "que_st2"
           travel_count_2 += 1
       end
    end
    # Check if there are more cars at station 1 than desired for rebalancing
    if travel_count_1 + stat.n_cars[1] >= rebal.desired[rebalance_action][1] 
        if stat.n_cars[1] <= (travel_count_1 + stat.n_cars[1])-rebal.desired[rebalance_action][1] # If there are too few cars to rebalance
            for i in 1:stat.n_cars[1] # Remove cars
                insert_and_sort!(e,(rand(Exponential(env.mu_rammer_port[k]))+e[1][1],"que_st2")) 
                stat.n_cars[1] -= 1 
            end 
            stat.currently_empty[1] = true # Station becomes empty
            stat.empty_time[1] -= e[1][1]
        else
            for i in 1:(travel_count_1 + stat.n_cars[1])-rebal.desired[rebalance_action][1] # Remove cars
                insert_and_sort!(e,(rand(Exponential(env.mu_rammer_port[k]))+e[1][1],"que_st2"))
                stat.n_cars[1] -= 1 
            end
        end
    # Check if there are more cars at station 2 than desired for rebalancing
    elseif travel_count_2 + stat.n_cars[2] > rebal.desired[rebalance_action][2]
        if stat.n_cars[2] <= (travel_count_2 + stat.n_cars[2])-rebal.desired[rebalance_action][2] # If there are too few cars to rebalance
            for i in 1:stat.n_cars[2] # Remove cars
                insert_and_sort!(e,(rand(Exponential(env.mu_rammer_dtu[k]))+e[1][1],"que_st1"))
                stat.n_cars[2] -= 1
            end 
            stat.currently_empty[2] = true
            stat.empty_time[2] -= e[1][1]
        else
            for i in 1:(travel_count_2 + stat.n_cars[2])-rebal.desired[rebalance_action][2] # Remove cars
                insert_and_sort!(e,(rand(Exponential(env.mu_rammer_dtu[k]))+e[1][1],"que_st1"))
                stat.n_cars[2] -= 1
            end
        end
    else
        throw(ErrorException("Error in rebalance!")) 
    end
    # Adding the next reblance event one day later
    insert_and_sort!(e,(24.0+popfirst!(e)[1],"rebalance"))

    # Changing the rebalance action
    if rebalance_action == length(rebal.desired)
        global rebalance_action = 1
    else
        global rebalance_action += 1
    end
end

###### Simulation ######
function sim(days_to_run::Int64,initial_n_cars::Vector{Int64}, rebal::Balance, env::Environment)
    ###########
    # For Graphs of vehicles
    graph_st1 = []
    graph_st2 = []
    time = []

    ###########
    # Initial Misc
    stat = Stats([initial_n_cars[1],initial_n_cars[2]],[0,0],[0,0],[0,0],[false,false])
    e = Array{Tuple{Float64,String},1}()
    runs = 0
    
    ###########
    # arrival and travel rates
    insert_and_sort!(e,(0.0,"time_change"))
    global k = 1
    global day = 0
    
    ###########
    # Arrivals
    insert_and_sort!(e,(rand(Exponential(env.lambda_dtu[k])),"st1"))
    insert_and_sort!(e,(rand(Exponential(env.lambda_port[k])),"st2"))
    
    ###########
    # Rebalance
    global rebalance_action = 1
    for i in 1:length(rebal.rebalance_times)
        insert_and_sort!(e,(rebal.rebalance_times[i],"rebalance"))
    end

    # Main loop
    while e[1][1] <= days_to_run*24.0 && runs <= 100000 # Runs until the end of the simulation
        load_type = e[1][2] # Type of event
        if load_type == "st1" # Arrival at station 1
            arrival_student(1,e,env,stat)
        elseif load_type == "st2" # Arrival at station 2
            arrival_student(2,e,env,stat)
        elseif load_type == "que_st1" # Arrival at station 1 from queue
            arrival_vehicle(1,e,stat)
        elseif load_type == "que_st2" # Arrival at station 2 from queue
            arrival_vehicle(2,e,stat)
        elseif load_type == "time_change" # Time change
            time_change(e,day)
        elseif load_type == "rebalance" # Rebalance
            rebalancing(rebal,stat,env,e)
        else
            throw(ErrorException("Issue in the event type!")) 
        end
        push!(graph_st1,stat.n_cars[1]) # Add to graph of vehicles for station 1
        push!(graph_st2,stat.n_cars[2]) # Add to graph of vehicles for station 2
        push!(time,e[1][1]) # Add to graph of time
        runs += 1 # Checks the amount of events
    end

    # Make sure the empty timer stops at the end of the run
    if stat.currently_empty[1] == true
        stat.empty_time[1] += e[1][1]
    elseif stat.currently_empty[2] == true
        stat.empty_time[2] += e[1][1]
    end
    
    return stat.n_cars,stat.un_fullfilled,stat.fullfilled,stat.empty_time,runs,graph_st1,graph_st2,time 
end

###### Main ######
function main(initial_n_cars::Vector{Int64},days_to_run::Int64,n_of_runs::Int64,rebalance::Tuple{Vector{Tuple{Int64, Int64}}, Vector{Float64}})
    env = Environment() 
    rebal = Balance(rebalance[1],rebalance[2]) 

    # Defining variables so they act globally
    overview = [] 
    a = 0
    efficiancy_cars = [] 
    efficiancy_empty = []
    efficiancy_fullfilled = []
    efficiancy_emptytime = []

    # Run the simulation n_of_runs times
    for i in 1:n_of_runs 
        a = sim(days_to_run,initial_n_cars,rebal,env) 
        overview = [overview;a]  # Add to overview
        
        efficiancy_fullfilled = [a[3][1]/(a[3][1]+a[2][1]), a[3][2]/(a[3][2]+a[2][2]) ] # Calculate efficiancy
        efficiancy_emptytime = [a[4][1]/(days_to_run*24),a[4][2]/(days_to_run*24)] 

        efficiancy_cars = [efficiancy_cars; [efficiancy_fullfilled]] 
        efficiancy_empty = [efficiancy_empty; [efficiancy_emptytime]]
    end
    
    # Save stats for plot if needed
    # if n_of_runs == 1
    #     global out = [a[6],a[7],a[8]]

    #     print("Efficiancy percentage for station 1 is ")
    #     printstyled(round(efficiancy_fullfilled[1]*100,digits=2),"%"; color=:blue)
    #     print(" and ")
    #     printstyled(round(efficiancy_fullfilled[2]*100,digits=2),"%"; color=:blue)
    #     print(" for station 2. Percentage of time spent empty for station 1 is ")
    #     printstyled(round(efficiancy_emptytime[1]*100,digits=2),"%"; color=:blue)
    #     print(" and ")
    #     printstyled(round(efficiancy_emptytime[2]*100,digits=2),"%"; color=:blue)
    #     println(" for station 2.")
    # end
    return efficiancy_empty, efficiancy_cars
end

########### User manual ############
##### Inputs: main(1,2,3,4)
# 1: [initial cars at station 1, initial cars at station 2] (Int,Int)
# 2: days to run each simulation (Int)
# 3: Amount simulations to run (Int)
# 4: ( [(Desired amount at station 1 for first reblance, station 2 at first rebalance), (station 1 at second, station 2 at second), ..., (station 1 at n rebalance, station 2 at n)], [time of first rebalance, ..., time at n event] ) (Tuple(Int,Int),Float)


########### For loop to find ideal rebalance at midnight ############
# Finding the rebalance amount to begin with and the related efficiancy
function ideal_rebalance_midnight(n,stepsize=15)
    effic_st1 = []
    effic_st2 = []
    position = []
    for j in 1:stepsize:n*2
        _, effic = main([n,n],100,30, ([(j,n*2-j)],[0.0]) )
        total_effic = [effic[1][1],effic[1][2]]
        for p in 2:30-1
            total_effic = [effic[p][1]+total_effic[1],effic[p][2]+total_effic[2]]
        end
        
        push!(effic_st1,total_effic[1]/30)
        push!(effic_st2,total_effic[2]/30)
        push!(position,[j,n*2-j])
    end
    # Finding the index of the highest summed efficiancy
    total_effic = effic_st1 .+ effic_st2
    a = findmax(total_effic)[2]
    # Using the index to determine the rebalance amount
    println("Efficiency for one rebalance midnight:\nstation1 ",effic_st1[a],"\nstation2: ",effic_st2[a],"\nposition: ",position[a])
    println("Distribution of rebalances:\nStation 1: ",round(position[a][1]/(n*2),digits=3)," Station 2: ",round(position[a][2]/(n*2),digits=3))
end

### Then a for loop to find the lowest amount of cars for to fullfill the service level ###
# Asuming that the rebalance distribution remains the same with the increase of the total amount of cars
function lowest_cars_midnight(distribution,n_start,stepsize = 2)
    effic_st1 = 0
    effic_st2 = 0
    n = n_start

    while (effic_st1 <= 0.95 || effic_st2[1] <= 0.95)
        n = n + stepsize
        _, effic = main([n,n],100,30, ([(floor(Int64,n*2*distribution[1]),trunc(Int64,n*2*distribution[2]))],[0.0]) )
        total_effic = [effic[1][1],effic[1][2]]
        for p in 2:30-1
            total_effic = [effic[p][1]+total_effic[1],effic[p][2]+total_effic[2]]
        end
        effic_st1 = total_effic[1]/30
        effic_st2 = total_effic[2]/30
    end

    println("Efficiency for one rebalance at midnight:\nstation1 ",effic_st1,"\nstation2: ",effic_st2,"\nthe amount of cars needed for the desired service level: ",n*2)
end

# # Multiple tests to find the ideal (manually)
# ideal_rebalance_midnight(140,5) # 0.807,0.193
# lowest_cars_midnight([0.807,0.193],125,1) # 272

# ideal_rebalance_midnight(136,5) # 0.831,0.169
# lowest_cars_midnight([0.831,0.169],125,1) # 262

# ideal_rebalance_midnight(132) # 0.799,0.200
# lowest_cars_midnight([0.799,0.200],125,1) # 276


############ for loop for two rebalance at 7 and 13 ############
# Only rebalance amount
function ideal_rebalance_7_13(n,stepsize=20)
    effic_st1 = []
    effic_st2 = []
    position_reb1 = []
    position_reb2 = []

    for i in 1:stepsize:n*2
        for j in 1:stepsize:n*2
            _, effic = main([n,n],100,30, ([(j,n*2-j),(i,n*2-i)],[7.0,13.0]) )
            total_effic = [effic[1][1],effic[1][2]]
            for p in 2:30-1
                total_effic = [effic[p][1]+total_effic[1],effic[p][2]+total_effic[2]]
            end
            
            push!(effic_st1,total_effic[1]/30)
            push!(effic_st2,total_effic[2]/30)
            push!(position_reb1,[j,n*2-j])
            push!(position_reb2,[i,n*2-i])
        end
    end

    total_effic = effic_st1 .+ effic_st2
    a = findmax(total_effic)[2]
    println("\n\nEfficiency for two rebalance at 7 and 13:\nstation 1: ",effic_st1[a],"\nstation2: ",effic_st2[a],"\nposition 1: ",position_reb1[a],"\nposition 2: ",position_reb2[a])
    println("Distribution of rebalances for rebalance 1:\nStation 1: ",round(position_reb1[a][1]/(n*2),digits=3)," Station 2: ",round(position_reb1[a][2]/(n*2),digits=3))
    println("Distribution of rebalances for rebalance 2:\nStation 1: ",round(position_reb2[a][1]/(n*2),digits=3)," Station 2: ",round(position_reb2[a][2]/(n*2),digits=3))
end

function lowest_cars_7_13(distribution,n_start,stepsize = 2)
    effic_st1 = 0
    effic_st2 = 0
    n = n_start
    while (effic_st1 <= 0.95 || effic_st2 <= 0.95)
        n += stepsize
        _, effic = main([n,n],100,30, ([
            (floor(Int64,n*2*distribution[1][1]),trunc(Int64,n*2*distribution[1][2])),
            (floor(Int64,n*2*distribution[2][1]),trunc(Int64,n*2*distribution[2][2]))],[7.0,13.0]))
        total_effic = [effic[1][1],effic[1][2]]
        for p in 2:30-1
            total_effic = [effic[p][1]+total_effic[1],effic[p][2]+total_effic[2]]
        end
        
        effic_st1 = total_effic[1]/30
        effic_st2 = total_effic[2]/30

    end
    println("Efficiency for one rebalance at midnight:\nstation1 ",effic_st1,"\nstation2: ",effic_st2,"\nthe amount of cars needed for the desired service level: ",n*2)
end

# # Manual tests
# ideal_rebalance_7_13(70,10) # [0.864,0.136],[0.579,0.421]
# lowest_cars_7_13([[0.864,0.136],[0.579,0.421]],70,2) # 164

# ideal_rebalance_7_13(82,8) # [0.884,0.116],[0.521,0.479]
# lowest_cars_7_13([[0.884,0.116],[0.521,0.479]],65,1) # 160

# ideal_rebalance_7_13(80,10) # [0.881,0.119],[0.521,0.479]
# lowest_cars_7_13([[0.881,0.119,],[0.569,0.431]],80,1) # 162


########### Example for plotting ############
st1_reb = floor(Int64,262*0.831) # 217
st2_reb = trunc(Int64,262*0.169) # 44

main([217,44],10,1,([(217,44)],[0.0]))
plot(out[3],out[1],color="blue",labels="Amount of vehicles at station 1 by hours") # Plot the graph of vehicles for station 1
plot(out[3],out[2],color="red",labels="Amount of vehicles at station 2 by hours") # Plot the graph of vehicles for station 2

