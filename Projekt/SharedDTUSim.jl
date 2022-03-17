using Random, Distributions, DataStructures



#Write all your settings in here. E.g.:
# the running time
# the probability distributions for your process
struct Environment
    hours::Float64
    arrival_D_st1::Exponential
    arrival_D_st2::Exponential
    travel_time_st1st2_D::Exponential
    travel_time_st2st1_D::Exponential

    
    Environment() = new(420.0, 
    Exponential(10),
    Exponential(10),
    Exponential(10),
    Exponential(10))
end

#DO NOT CHANGE
struct Event
    type::Symbol
    time::Float64
end

#Describes the state of your process, similar to states in Markov. You can include as many variables as you like/need
mutable struct State
    station1_vehs::Int32
    station2_vehs::Int32
end

#If a vehicle is available, the student will leave station 1 with the vehicle. Arrival event at St2 is generated
function arrival_student_st1(env::Environment, state::State, events::PriorityQueue{Event,Float64}, t::Float64)
    rand()


end


#Same for station 2
function arrival_student_st2(env::Environment, state::State, events::PriorityQueue{Event,Float64}, t::Float64)
   
end

#Arrival of cars at station 1 and station 2
function arrival_vehicle_st1(env::Environment, state::State, t::Float64)
    
end

function arrival_vehicle_st2(env::Environment, state::State, t::Float64)
   
end

function simulate(env::Environment, carsSt1::Int64, carsSt2::Int64)
    t = 0
    state = State(carsSt1, carsSt2)
    events = PriorityQueue{Event,Float64}()
    
end

function main()
   
end

main()

