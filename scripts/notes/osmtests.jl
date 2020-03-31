using DrWatson
@quickactivate "tutorial"

using DifferentialEquations

f(u,p,t) = sin(u)

u0 = 1/2

tspan = (0.0,1.0)

prob = ODEProblem(f, u0, tspan)

sol = solve(prob)

sol = solve(prob,reltol=1e-6)

sol = solve(prob,reltol=1e-6,save_everystep=false)

sol = solve(prob,Tsit5())


sol[5]

[t+u for (u,t) in tuples(sol)]

sol(0.44)

ENV["GKS_ENCODING"] = "utf-8"
#]add Plots # You need to install Plots.jl before your first time using it!
using Plots
using LaTeXStrings
#plotly() # You can optionally choose a plotting backend
plot(sol)

plot(sol,linewidth=5,title="Solution to the linear ODE with a thick line",
     xaxis="Time (t)",yaxis=L"u(t) (in \mu m)",label="My Thick Line!") # legend=false

L"\alpha test"



function lorenz!(du,u,p,t)
 du[1] = 15.0*(u[2]-u[1])
 du[2] = u[1]*(28.0-u[3]) - u[2]
 du[3] = u[1]*u[2] - (8/3)*u[3]
end


u0 = [1.0;0.0;0.0]
tspan = (0.0,100.0)
prob = ODEProblem(lorenz!,u0,tspan)
sol = solve(prob)

plot(sol,vars=(1,2,3))

function parameterized_lorenz!(du,u,p,t)
  x,y,z = u
  σ,ρ,β = p
  du[1] = dx = σ*(y-x)
  du[2] = dy = x*(ρ-z) - y
  du[3] = dz = x*y - β*z
end

u0 = [1.0,0.0,0.0]
tspan = (0.0,1.0)
p = [10.0,28.0,8/3]
prob = ODEProblem(parameterized_lorenz!,u0,tspan,p)













using OpenStreetMapX

mx = get_map_data(datadir("exp_raw","map.osm"), use_cache = false)
println("The map contains $(length(map_data.nodes)) nodes")

using Random
Random.seed!(0)
node_ids = collect(keys(mx.nodes))
routes = Vector{Vector{Int}}()
visits = Dict{Int,Int}()
for i in 1:5000
    a,b = [point_to_nodes(generate_point_in_bounds(mx), mx) for _ in 1:2]
    route, route_time = OpenStreetMapX.shortest_route(mx,a,b)
    if route_time < Inf # when we select points neaer edges no route might be found
        push!(routes, route)
        for n in route
            visits[n] = get(visits, n,0)+1
        end
    end
end
println("We have generated ",length(routes)," non-empty routes")

mx

mx.g

using GraphPlot

gplot(mx.g)

using OpenStreetMapXPlot
import Plots
Plots.gr()
p = OpenStreetMapXPlot.plotmap(mx,width=600,height=400);

import Random

pointA = point_to_nodes(generate_point_in_bounds(mx), mx)
pointB = point_to_nodes(generate_point_in_bounds(mx), mx)
sr = OpenStreetMapX.shortest_route(mx, pointA, pointB)[1]

addroute!(p,mx,sr;route_color="red");
plot_nodes!(p,mx,[sr[1],sr[end]],start_numbering_from=nothing,fontsize=13,color="pink");
p
