
# function change_type(P)
#     if typeof(P) == Vector{Vector{Float64}}
#         p_new = p[length(p)]
#         for i in 1:length(p)-1
#             p_new = hcat(p[length(p)-i],p_new)
#         end 
#         return p_new
#     else
#         return P
#     end
# end
# P = change_type(P)

using LinearAlgebra


check_stochastic = (P) -> maximum(abs, sum(P, dims = 2) .- 1) < 1e-10 ? true : false

mutable struct MarkovChain
    P::Matrix{Float64}
    
    function MarkovChain(P)
        n,m = size(P)
        
        n != m &&
            throw(DimensionMismatch("The matrix P is not square"))
        minimum(P) <0 &&
            throw(ArgumentError("The matrix P is not stochastic (negative value)"))
        !check_stochastic(P) &&
            throw(ArgumentError("The matrix P is not stochastic (summed to more than 1)"))
        return new(P)
    end
end

n_states(mc::MarkovChain) = size(mc.P, 1)

function Base.show(io::IO, mc::MarkovChain)
    println(io,"Markov Chain : ")
    println(io,mc.P)
end

function Base.getindex(mc::MarkovChain, i::Int64, j::Int64)
    return mc.P[i,j]
end

function Base.setindex!(mc::MarkovChain, value::Float64, i::Int64, j::Int64)
    mc.P[i,j] = value
    println("Be aware that the matrix is not necesarily stochastic anymore")
end

function MakeMatrix(mc::MarkovChain)
    return Matrix{Float64}(mc.P)
end
 

# Give the vertices of the graph in the form of a list of tuples
function vertices(mc::MarkovChain)
    
    V = Vector{Int64}()
    for i in 1:n_states(mc)
        V = push!(V, i)
    end

    E = []
    for i in 1:n_states(mc)
        for j in 1:n_states(mc)
            if mc[i,j] > 0
                push!(E,(i,j))
            end
        end
    end
    return V,E
end

# Find the neighbors of a state
function neighbors(E,v::Int64)
    neighbors = []
    for i in eachindex(E)
        if E[i][1] == v
            push!(neighbors, E[i][2])
        end
    end
    return neighbors
end

# Deapth first search iteration of the graph
function dfs_iter(v,E,visited) # Needs type
    stack = Vector{Int64}()
    order = Vector{Int64}()
    push!(stack, v)

    while !isempty(stack)
        v = last(stack)
        neighbor = neighbors(E,v)

        if sum(visited[neighbor]) == length(neighbor)
            visited[v] = true
            push!(order,pop!(stack))
        else
            if visited[v] == false
                visited[v] = true            
                for w in neighbor

                    if visited[w] == false
                        push!(stack, w)
                    end
                end
            end
        end
    end
    return order,visited
end

# Reverese the graph (Markov chain) 
function reverse_graph(E)
    E_rev = []
    for i in eachindex(E)
        push!(E_rev, (E[i][2], E[i][1]))
    end
    return E_rev
end

# Strongly connected components (Communicating classes) with the kosaraju algorithm
function SCCs_kosaraju(mc::MarkovChain)
    V,E = vertices(mc)
    visited = falses(length(V))
    order = []
    for i in V
        if visited[i] == false
            ordered,visited = dfs_iter(i,E,visited)
            for j in ordered
                push!(order, j)
            end
        end

    end
    E_rev = reverse_graph(E)
    SCCs = []
    visited = falses(length(V))
    for i in reverse!(order)
        
        if visited[i] == false
            SCC,visited = dfs_iter(i,E_rev,visited)

            push!(SCCs, SCC)
        end
    end

    return SCCs
end

# Irreducible Markov Chains
is_strongly_connected(mc::MarkovChain) = length(SCCs_kosaraju(mc)) == 1

# Condensing the graph
function condensation(mc::MarkovChain)
    V,E = vertices(mc)
    SCCs = SCCs_kosaraju(mc)

    components = Vector{Int64}(undef, length(V))
    new_E = []

    for (i,s) in enumerate(SCCs)
        components[s] .= i
    end

    # Check connection between the condenced components
    for e in E
        if components[e[1]] != components[e[2]]
            push!(new_E, (components[e[1]], components[e[2]]))
        end
    end
    return unique!(components),new_E
end

# Number of degrees (edges) going out of the vertex
function out_degree(V,E)
    out_degree = zeros(length(V))
    for e in E
        out_degree[e[1]] .+= 1
    end
    return out_degree
end

# Number of degrees (edges) going in to the vertex
function in_degree(V,E)
    in_degree = zeros(length(V))
    for e in E
        in_degree[e[2]] .+= 1
    end
    return in_degree
end

# number of degrees going in and out of the vertex
function degree(V,E)
    degree = zeros(length(V))
    for e in E
        degree[e[1]] .+= 1
        degree[e[2]] .+= 1
    end
    return degree
end

# (Recurrent classes)
function attracting_components(mc::MarkovChain)
    components,E = condensation(mc)
    
    attracting_components = []

    for v in components
        if out_degree(components,E)[v] == 0
            push!(attracting_components, v)
        end
    end
    return SCCs_kosaraju(mc)[attracting_components]
end


# Breadth first search
# Graph-Theoretic Analysis of Finite Markov Chains
# J. P. Jarvis and D. R. Shier
function bfs(v,V,E,visited)
    n = length(V)
    parents = zeros(n)
    tree = Vector{}()
    levels = zeros(n)

    current_level = Vector{Int64}()
    next_level = Vector{Int64}()
    sizehint!(next_level,n)
    sizehint!(current_level,n)

    # Initialize
    push!(current_level, v)
    i = 0
    j = 0

    while !isempty(current_level)
        j += 1
        for v in current_level
            if visited[v] == false
                i += 1
                levels[i] += j
                visited[v] = true
                
                parents[i] = v
                neighbor = neighbors(E,v)
                
                for w in neighbor
                    if visited[w] == false && v != w
                        push!(next_level, w)
                        push!(tree,(v,w))
                    end
                end

            end

        end
        # push!(tree, next_level)
        current_level = next_level
        next_level = Vector{Int64}()
        
    end
    return parents, tree, visited, levels
end

# Greates common divisor (Euclidean algorithm)
function gcd(a,b)
    if b == 0
        return a
    else
        return gcd(b, a % b)
    end
end

# dobbelt tjek hvad fuck jeg har lavet ?
function period(mc::MarkovChain)
    !is_strongly_connected(mc) &&
        throw(ArgumentError("The Markov chain is not strongly connected"))
    
    V,E = vertices(mc)
    visited = falses(length(V))
    parent, tree, visited, levels = bfs(1,V,E,visited)

    # Check if it has self loop
    
    for e in E
        isequal(e[1], e[2]) && return 1
    end

    perm = sortperm(parent)

    parent = parent[perm]
    levels = levels[perm]

    # Find all the non-tree edges
    ix_drop = indexin(tree,E)
    E_new = E[eachindex(E) .∉ Ref(ix_drop)]

    val_e = zeros(length(E_new))
    divisor = 0
    for i in eachindex(E_new)
        val_e[i] = levels[E_new[i][1]] - levels[E_new[i][2]] + 1
        divisor = gcd(divisor, val_e[i])
        isequal(divisor,1) && return 1
    end

    return divisor
end

function is_irreducible(mc::MarkovChain)
    return is_strongly_connected(mc)
end

function is_reducible(mc::MarkovChain)
    return !is_irreducible(mc)
end

function is_periodic(mc::MarkovChain)
    return period(mc) != 1
end

function is_aperiodic(mc::MarkovChain)    
    return period(mc) == 1
end

function is_ergodic(mc::MarkovChain)
    return is_aperiodic(mc) && is_irreducible(mc)
end

function communication_classes(mc::MarkovChain)
    return SCCs_kosaraju(mc)
end

function recurrent_classes(mc::MarkovChain)
    return attracting_components(mc)
end

# Algebraic steady state distribtuion
function steady_distribution_algebra(mc::MarkovChain)
    !is_ergodic(mc) &&
        throw(ArgumentError("The Markov chain is not ergodic"))
    
    P = reshape(mc.P, n_states(mc), n_states(mc))

    A=P'-Matrix(1.0I, length(P[1,:]), length(P[:,1]))

    ones = repeat([1.0],length(P[1,:]))'
    A = vcat(A,ones)

    b = vcat(repeat([0.0],length(A[1,:])),1.0)

    return(A\b)
end

# steady state distribution by simulation
function steady_distribution_sim(mc::MarkovChain,n=52)
    !is_ergodic(mc) &&
        throw(ArgumentError("The Markov chain is not ergodic"))
    
    P = reshape(mc.P, n_states(mc), n_states(mc))

    initial_dist = push!(zeros(n_states(mc)-1),1)'

    for _ in 1:n
        update = initial_dist * P
        initial_dist = update
    end
    return initial_dist'
end

function steady_state(mc::MarkovChain,n=52,type="algebra")
    if type == "algebra"
        return steady_distribution_algebra(mc)
    else if type == "sim"
        return steady_distribution_sim(mc,n)
    else
        throw(ArgumentError("Unknown type"))
    end
end

### Absorbtion
# Source: https://en.wikipedia.org/wiki/Absorbing_Markov_chain
# Number of transient states
function num_trans(mc::MarkovChain)
    t = []
    r = []
    a = 0
    temp = 1
    # Loop through matrix
    for k in 1:n_states(mc)
        a += 1

        for c in 1:n_states(mc)
            if P[k,c] == 1
                # If there is a prob of 1 to return to same state it absorbs and is not included.
                push!(r,a)
                temp = 0
                break
            end
        end
        # Not decent code at all, but it works..
        if temp == 1
            push!(t,a)
        else
            temp = 1
        end
    end
    return t, r
end

function create_RQ(mc::MarkovChain)
    t,r = num_trans(mc)

    # Creating empty vector 
    Q = Vector{Float64}(undef,length(t))'
    # Choosing all the transient states into a pseydo transient matrix by size t-t
    for k in t
        qRow = []
        for c in t
            push!(qRow,mc[k,c])
        end
        Q = vcat(Q, qRow')
    end

    R = Vector{Float64}(undef,length(r))'
    
    if isempty(r)
        # Doing the same but for absorbant states into t-r, a few changes in the way the matrices combine
        return Q[2:length(t)+1,:], R
    else
        for k in t
            rRow = []
            for c in r
                push!(rRow,mc[k,c])
            end
            R = vcat(R, rRow')
        end
        R = R[2:length(t)+1,:]
    end

    Q = Q[2:length(t)+1,:]
    N = inv(Matrix(1.0I,length(Q[1,:]),length(Q[:,1])) .- Q)

    return Q, R, N
end

# Another property is the probability of being absorbed in the absorbing state j when starting from transient state i
function absorbing_probabilities(mc::MarkovChain) # i NEEDs to be recurrent, fix later
    _, R, N = create_RQN(mc)
    B = N*R
    return B
end

function ENS_absorption(mc::MarkovChain) # Expected number of steps before being absorbed
    _,_,N = create_RQN(mc)

    return N*ones(n_states(mc))
end

# The probability of visiting transient state j when starting at a transient state i is the (i,j)-entry of the matrix H = (N-I)(Ndg)^-1
function transient_probabilities(mc::MarkovChain)
    _,_,N = create_RQN(mc)

    H = (N-Matrix(1.0I,length(N[1,:]),length(N[:,1])))*inv(Diagonal(N))
    return H
end

# Mean Number of Steps, Hitting Time or First Passage Time
function MeanNumSteps(mc::MarkovChain,type="algebra")
    l = n_states(mc)

    # Creates a matrix with the steady states, terrible code but it works
    W = repeat(vcat(steady_state(mc,type)',steady_state(mc,type)'),Int(round(l/2)))
    if isodd(l)
        W = W[1:l,:]
    end

    mcM = MakeMatrix(mc)

    # Fundamental Matrix
    Z = inv(Matrix(1.0I,l,l) - mcM + W)

    # vector of steady states to use for the transition
    w = steady_state(mc,type)

    # Empty vector, have not found a way to concenate without a starting row of same size (I am just stupid, could easily be fixed, but i m also lazy)
    M = Vector{Float64}(undef,l)'
    # The magic happens here!
    # It creates 
    for k in 1:l
        mRow = []
        for c in 1:l
            a = (Z[k,k] - Z[c,k])/w[k]
            push!(mRow,a)
        end
        M = vcat(M, mRow')
    end
    return M[2:l+1,:]' + Matrix(1.0I,l,l)
end

# Expected Recurence Time
ERT(mc::MarkovChain,i::Int64) -> 1/steady_state(mc)[i]

# n-step probability
#Probability of moving from i to j in n steps.
function nStepProp(mc::MarkovChain,i::Int64,j::Int64,n::Int64)
    # Takes transition matrix: mc
    # i: start state
    # j: end state
    # n: steps
    n=n-1 # again, it real ugly but it works

    # Creating the vectors for the used probabilities
    # Since k cannot equal j 
    p = []
    f = []
    for k in 1:n_states(mc)
        if k != j
            push!(p,mc[i,k])
            push!(f,mc[k,j])
        end
    end

    for _ in 1:n
        #Running the iterative function
        f = p.*f
    end
    #Final Probability
    
    return sum(f) # er det ikke bare f?? 
end

# # VIrker ikke, den er bare copilot
# function PageRank(mc::MarkovChain)
#     # PageRank algorithm
#     # Source: https://en.wikipedia.org/wiki/PageRank
#     # Initialize
#     l = n_states(mc)
#     r = ones(l)/l
#     # Loop
#     for _ in 1:100
#         r = r*mc
#     end
#     return r
# end



# It is time for the hidden markov chains


# https://en.wikipedia.org/wiki/Viterbi_algorithm
function viterby(mc::MarkovChain)
    
end



# # Markov chain properties

push!(zeros(n_states(mc)-1),1)'
recurrent_classes(mc)

p = [0.1 0.4 0.5;
    0.4 0.3 0.3;
    0.6 0.2 0.2]
mc = MarkovChain(p)

attracting_components(mc)
condensation(mc)


reshape(mc, n_states(mc), n_states(mc)) + [0.1 0.2 0.3 0.5 0;
    0.2 0.1 0.2 0.3 0;
    0.3 0.2 0.1 0.2 0;
    0.5 0.3 0.2 0.1 0;
    0 0 0 0 0]




is_ergodic(mc)


p = [0.5 0 0.5 0 0 0; 1 0 0 0 0 0; 0 0 0 0.5 0.5 0; 0 1 0 0 0 0 ; 0 0 0 0 0 1; 0 0 0 1 0 0]
mc = MarkovChain(p)
V,E = vertices(mc)
visited = falses(length(V))
parent, tree, visited, levels = bfs(1,V,visited)


mc[1,2]


p = [0 0.5 0.5 0 0 0 0 0;
    0.5 0.5 0 0 0 0 0 0;
    0 0 0 0.5 0 0 0 0.5;
    0 0 0.5 0 0.5 0 0 0;
    0 0 0 0 0 1 0 0;
    0 0 0 0 0 0 1 0;
    0 0 0 0 0 0.5 0 0.5;
    0 0 0 0 0 1 0 0;
    ]

p = [1 0 0 0 0; 0.3 0.2 0.5 0 0; 0 0.4 0.1 0.5 0; 0 0 0 0.5 0.5; 0 0 0 0.5 0.5]
mc = MarkovChain(p)
SCCs_kosaraju(mc)

condensation(mc)

attracting_components(mc)


visited = falses(length(V))
parents,tree, visited = bfs(3,V,visited)


p = [0 0.5 0.5 0 0 0 0 0;
    0.5 0.5 0 0 0 0 0 0;
    0.1 0 0 0.4 0 0 0 0.5;
    0 0 0.5 0 0.5 0 0 0;
    0 0 0 0 0 1 0 0;
    0 0 0 0 0 0 1 0;
    0 0 0 0 0 0.5 0 0.5;
    0 0 0 0 0 1 0 0;
    ]
mc = MarkovChain(p)
V,E = vertices(mc)
visited = falses(length(V))



# https://juliagraphs.org/
# https://github.com/QuantEcon/QuantEcon.jl/blob/013ec2682794abccc5868392b7d7fe14b41f13dc/src/markov/mc_tools.jl#L19-L30
# https://github.com/FAST-ASR/MarkovModels.jl/blob/master/src/fsms/fsmop.jl
# https://www.probabilitycourse.com/chapter11/11_2_4_classification_of_states.php
# https://github.com/sbromberger/LightGraphs.jl/blob/master/src/connectivity.jl
