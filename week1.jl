##### Problem 1

### Q1
## 1.
# The decision maker must be the driver/the person seeing the play.
# And the decision is in the set of {Palægade, Sankt Annæ Plads}
## 2.
# The parking spaces is the enviroment
# The exogenous variables (Variables outside the system) are primarily 
# the availability of close parking space on Palæg
## 3.
# potential outcomes {late, not late}
# System???
## 4.
# Said

### Q2
# [Pa : 720 : 20 ]
# [S  : 180 : 180]

### Q3
# Maximax:
# Would choose Pa since it has the lowest cost/hishgest utility
# Maximin:
# Would choose S since the it chooses the highest costs (720, 180)
# and minimizes those

### Q4
# [Pa : 520 : 0]
# [S  : 0 : 160]
# Therefore the lowest regret would be S and choose that

### Q5
# 
p = 0.4
x1 = 0
function f(x1,p)
    -20*x1 - 180*(1-x1) - 700*x1*p
end

# Therefore S

### Q6
using Plots
pyplot()
begin
plot([f(0,1),f(0,0)])
plot!([f(1,1),f(1,0)])
end
# Mit skud ligger på onmkring 76 procent, gider ikke regne
# Ville også blive maple

######### Problem 2
# Solution 1:

# x = {0,1} 0 =no mosquit, 1 = mosquit
price = 5
c1 = [0,2]
c2 = [3,50]
### Q1
# Meee
# temperature
# money
# 

### Q2
# 

### Q2
# 

### Q5
price = 5
c1 = [0,2]
c2 = [3,50]
function f(x,p)
    -price*x - c1[2]*x*p - c1[1]*x*(1-p) - c2[2]*(1-x)*p - c2[1]*(1-x)*(1-p)
end
f(1,0.2)
f(0,0.2)
### Q6
using Plots
pyplot()
begin
plot([f(0,0),f(0,1)],legend = :outertopright)
plot!([f(1,0),f(1,1)])
end
# Ok man skal tænke på menneske liv osv. who cares skejser er det eneste der tæller







