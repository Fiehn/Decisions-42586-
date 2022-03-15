
#### Problem 1
## Q1

using Statistics
using Distributions
using Plots

p = 0.4
N = 10
d = Binomial(1,p)

v = rand(d, N)
print(v)

## Q2
mean = 11.85
sd = 0.15
N = 8

d = Normal(mean,sd)
x = rand(d,N)

quantile.(d, [0.05, 0.95])

## Q3
c = [1.85,1.92,1.95,1.7,2.1,2.5,2.2,2,2.08]

function t_test(x; conf_level=0.95)
    alpha = (1 - conf_level)
    tstar = quantile(TDist(length(x)-1), 1 - alpha/2)
    SE = std(x)/sqrt(length(x))

    lo = Statistics.mean(x) + (-1 * tstar * SE)
    hi = Statistics.mean(x) + 1 * tstar * SE
    "($lo, $hi)"
end

t_test(c)

#### Problem 2
c = 1000

Ex1 = [1.2,1,1.7] * 1/100
Ex2 = [2,-1.1,-0.2] * 1/100
Ex3 = [0.1,-0.5,1.3] * 1/100
Ex4 = [-0.2,-0.9,0] * 1/100
Ex5 = [0.5,0.2,-2.3] * 1/100

## Q1
using Plots
pyplot()
plot(Plots.fakedata(50, 5), w = 3)

function cool(ex,c)
    b = []
    a = c
    append!(b,c)
    for i in 1:length(ex)
        a = ex[i] * a + a
        append!(b,a)
    end
    return b
end

print(cool(Ex1,c))
begin
    plot([cool(Ex1,c)])
    plot!([cool(Ex2,c)])
    plot!([cool(Ex3,c)])
    plot!([cool(Ex4,c)])
    plot!([cool(Ex5,c)])
end

## Q2
u1 = [cool(Ex1,c)[2],cool(Ex2,c)[2],cool(Ex3,c)[2],cool(Ex4,c)[2],cool(Ex5,c)[2]]
Statistics.mean(u1)
t_test(u1)

u2 = [cool(Ex1,c)[3],cool(Ex2,c)[3],cool(Ex3,c)[3],cool(Ex4,c)[3],cool(Ex5,c)[3]]
Statistics.mean(u2)
t_test(u2)

u3 = [cool(Ex1,c)[4],cool(Ex2,c)[4],cool(Ex3,c)[4],cool(Ex4,c)[4],cool(Ex5,c)[4]]
Statistics.mean(u3)
t_test(u3)

## Q3
# Never buy NFT bitch

######### Problem 3
begin
    using Statistics
    using Distributions
    using Plots

    to = 17
    te = 22
    p = 0.9
    cAbove = 10
    cBelow = 30
    temp = [2.5,2.0,2.2,3.8,3.1]
end

if (x-temp[1])*0.9 +17 > 22
    b = cAbove * ((x-temp[1])*0.9 +17-22)
else
    b = 1
end






