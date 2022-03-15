using JuMP
using GLPK

struct Activity
    start::Int32
    finish::Int32
end

activities = [Activity(8,12), Activity(3,8),Activity(6,10),Activity(3,5),
			  Activity(5,9),Activity(8,11),Activity(1,4), Activity(2,13),
			  Activity(0,6), Activity(11,14),Activity(5,7)]
n = length(activities)
m = Model(GLPK.Optimizer)

@variable(m, x[activities], Bin)
@objective(m, Max, sum(x[a] for a in activities))

for i=1:n-1
	for j=i+1:n
		ai = activities[i]
		aj = activities[j]
		if(!(ai.finish <= aj.start || aj.finish <= ai.start))
			@constraint(m, x[ai]+x[aj]<=1)
		end
	end
end

optimize!(m)
println("Objective Value: ", objective_value(m))
println("Variable values: ", JuMP.value.(x))
