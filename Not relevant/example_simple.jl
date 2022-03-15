using JuMP
using GLPK

m = Model(GLPK.Optimizer)
invest = [15 18 6 20]

n=4

@variable(m, x[1:n], Bin)
@objective(m, Min, sum(invest[i]*x[i] for i=1:n))
@constraint(m, x[1] + x[4] >=1 )
@constraint(m, x[1] + x[2] + x[4] >=1 )
@constraint(m, x[2] + x[3] + x[4] >=1 )
optimize!(m)

println("Objective Value: ", objective_value(m))
println("Variable values: ", value.(x))








