module Queue
using Random, Distributions, DataStructures, Plots
_debug = true
#Write all your settings in here. E.g.:
# the running time
# the rates of the probability distributions for your process
struct Environment
    hours::Float64
    lambda::Float64  #arrival rate
    mu::Float64 #service rate
   
   #Add arrival rate per hour for both stations. Add travel-time rate for both stations.
    Environment() = new(
    2, 
    (1/6), 
    (1/12)
    )
end

#DO NOT CHANGE
struct Event
    type::Symbol
    time::Float64
end

#Describes the state of your process, similar to states in Markov. You can include as many variables as you like/need
mutable struct State
    queue_length::Int64
    server_busy::Bool
end

mutable struct SimStats
    #Served and unserved requests
    n_served::Int64 
    
    #to track occupancy, register total time the server is busy
    server_busy::Float64
    
    #Store state over time: time, queue_length, n_served, server_busy
    overview_usage::Matrix{Float64}
end


#If a vehicle is available, the student will leave station 1 with the vehicle. Arrival event at St2 is generated
function customer_arrival(env::Environment, state::State, events::PriorityQueue{Event,Float64}, stats::SimStats, t::Float64)
    if t<=env.hours # do not generate more students after horizon hours 
        #_debug && println("A customer has arrived at time $t with state (", state.queue_length, ", " , state.server_busy, ")")   
        #Increase queue length
        state.queue_length += 1;

        #Generate next arrival
        e1 = Event(:Arrival,t+rand(Exponential(env.lambda)))
        #_debug && println("-----next arrival at: $e1.time with current time $t " )
        enqueue!(events,e1,e1.time)

        #Add a new service start event if the server is not busy
        if !state.server_busy
            e2 = Event(:ServiceStart,t)
            #_debug && println("-----next service start:",  e2.time, "with current time $t and state(", state.queue_length, ", " , state.server_busy, ")" )
            enqueue!(events,e2,e2.time)            
       end
       stats.overview_usage = [stats.overview_usage; t state.queue_length state.server_busy]
    end
end



#Start service of customer
function service_starts(env::Environment, state::State, events::PriorityQueue{Event,Float64}, stats::SimStats, t::Float64)
    if state.server_busy == true
        throw(ErrorException("The server must be idle to be able to start a new job! "))
    end
    if t<=env.hours
        state.server_busy = true;
        state.queue_length -=1 
        #_debug && println("Service start at time $t with state (", state.queue_length, ", " , state.server_busy, ")") 
        #generate when service will be completed
        servicecompletionTime = rand(Exponential(env.mu))
        e = Event(:ServiceCompletion,t+servicecompletionTime)
        enqueue!(events,e,e.time)
        #_debug && println("-----Next service completion will be at time $t with state (", state.queue_length, ", " , state.server_busy, ")")
        if t+servicecompletionTime <= env.hours
            stats.server_busy+=servicecompletionTime
        else
            stats.server_busy+=(env.hours-t)
        end
    
    stats.overview_usage = [stats.overview_usage; t state.queue_length state.server_busy]
    end
end

function service_complete(env::Environment, state::State, events::PriorityQueue{Event,Float64}, stats::SimStats, t::Float64)
    if state.server_busy == false
        throw(ErrorException("The server must be busy to be able to complete a job! "))
    end
    if t<=env.hours
        state.server_busy = false;
        #_debug && println("Service complete at time $t with state (", state.queue_length, ", " , state.server_busy, ")") 
        #Generate next service start if there are customers in the queue
        if state.queue_length>0
            e = Event(:ServiceStart,t)
            enqueue!(events,e,e.time)
            #_debug && println("-----Next service will start at time $t with state (", state.queue_length, ", " , state.server_busy, ")")
        end
    stats.overview_usage = [stats.overview_usage; t state.queue_length state.server_busy]
    end
end


function simulation(env::Environment)
    t = 0.0
    state = State(0, false)
    overviewInitial = [t state.queue_length state.server_busy]
    stats = SimStats(0, false, overviewInitial)
    events = PriorityQueue{Event,Float64}()
    #Generate first arrival
    e1 = Event(:Arrival,rand(Exponential(env.lambda)))
    enqueue!(events,e1,e1.time)
    
    while !isempty(events)
        e = dequeue!(events)
        t = e.time
        if e.type==:ServiceStart
            service_starts(env,state,events,stats,t)
        elseif e.type==:ServiceCompletion
            service_complete(env,state,events,stats,t)
        elseif e.type==:Arrival
            customer_arrival(env,state,events,stats, t)
        end
    end
    return stats
end


#function printResults(stats::SimStats, run::Int64)
#print some results to screen:

#p = plot(stats.overview_usage[:,1],stats.overview_usage[:,2] , label="QueueLength")
#p = plot!(stats.overview_usage[:,1],stats.overview_usage[:,3] , label="ServerState")
#display(p)


#print detailed stats results to file, so you can review and analyze also later
#filename = string("C:/Users/evdh/OneDrive - Danmarks Tekniske Universitet/Teaching/DecisionUnderUncertainty/Simulation/results_" , run , ".txt")
#open(filename,"a") do io
#    println(io, stats.overview_usage)
# end

#end

function main()
    #Set seed -- in this way you can replicate the exact same results
    Random.seed!(3141549);
    runs = 10
    env =     Environment() 
    
    #Run simulation
    for i=1:runs
        stats = simulation(env)
        p = plot(stats.overview_usage[:,1],stats.overview_usage[:,2] , label="QueueLength")
        p = plot!(stats.overview_usage[:,1],stats.overview_usage[:,3] , label="ServerState")
        display(p)
        #printResults(stats, i)
    end
end

main()
end



