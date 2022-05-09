using LinearAlgebra
# 3.1
P = [0.5 0.5 0 0 0 0;
    0.33 0.33 0.33 0 0 0;
    0 1/6 1/6 2/3 0 0;
    0 0 1/6 1/6 2/3 0;
    0 0 0 0.1667 1/2 1/3;
    0 0 0 0 1/3 2/3]

profit = [500*0; 500*1; 500*2; 750*3; 750*4; 650*5]

function steady(P)
    # Computing the left side of the equation
    A=P'-Matrix(1.0I, length(P[1,:]), length(P[:,1]))

    ones = repeat([1.0],length(P[1,:]))'
    A = vcat(A,ones)
    # The right side of the equation
    b = vcat(repeat([0.0],length(A[1,:])),1.0)

    #Probability to be in a certain state
    Pi = A\b
end

a = steady(P)

# Long run expected average:
sum((profit .* a))
profit .* a
# 3.2
#????


# 4.1
P = [0.9 0.1;
    0.6 0.4]




# # 4.1
# P = [0.9 0.1;
#     0.6 0.4]

# Probability for i to j in n-steps
P= [0.632 0.632 0.1 0.2; 
    0.632 0.264 0.4 0.2; 
    0.264 0.184 0.368 0.368; 
    0.08 0.184 0.368 0.368]

function nStepProp(P,i,j,n)
    # Takes transition matrix: P
    # i: start state
    # j: end state
    # n: steps
    n=n-1

    # Creating the vectors for the used probabilities
    # Since k cannot equal j 
    p = []
    f = []
    for k in 1:length(P[1,:])
        if k != j
            append!(p,P[i,k])
            append!(f,P[k,j])
        end
    end

    for _ in 1:n
        #Running the iterative function
        f = p.*f

    end
    #Final Probability
    prop = sum(f)
    return prop
end
nStepProp(P,4,1,2)



