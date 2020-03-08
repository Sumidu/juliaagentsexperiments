using DrWatson
@quickactivate "tutorial"

using Agents
using Random
using Statistics
using CSV
using DataFrames
using Plots
using Images
mutable struct Person <: AbstractAgent
    id::Int
    pos::Tuple{Int,Int}
    healthy::Bool
    infected::Bool
    daysinfected::Int
    sick::Bool
    dayssick::Int
    dead::Bool
    immune::Bool
    age::Int
end


function translateDensity(x::Int, m = MersenneTwister())

    if x == 1
        return(rand(m,1:250))
    elseif x == 2
        return(rand(m,250:500))
    elseif x == 3
        return(rand(m,500:2000))
    elseif x == 4
        return(rand(m,2000:4000))
    elseif x == 5
        return(rand(m,5000:8000))
    elseif x == 6
        return(rand(m,8000:8100))
    end
    return 0
end




function getDensityData()

    rawdata = CSV.read(datadir("exp_raw", "Zensus.csv"))
    #names(rawdata)

    rawdata.x = (rawdata.x_mp_1km .- 500) ./ 1000
    rawdata.y = (rawdata.y_mp_1km .- 500) ./ 1000

    xmin = minimum(rawdata.x)
    xmax = maximum(rawdata.x)
    xsize = Int(xmax - xmin) + 1

    ymin = minimum(rawdata.y)
    ymax = maximum(rawdata.y)
    ysize = Int(ymax - ymin) + 1

    rawdata.x = rawdata.x .- xmin .+1
    rawdata.y = rawdata.y .- ymin .+1


    rawdata
end

function generateDensity(rawdata, target = 80000000, seed = 123)
    xmin = minimum(rawdata.x)
    xmax = maximum(rawdata.x)
    xsize = Int(xmax - xmin) + 1

    ymin = minimum(rawdata.y)
    ymax = maximum(rawdata.y)
    ysize = Int(ymax - ymin) + 1
    # empty map
    m = MersenneTwister(seed)
    densitymap = zeros(Int64, xsize, ysize)
    println("$(nrow(rawdata)) sets of data.")
    for i in 1:nrow(rawdata)
        value = rawdata[i,:Einwohner]
        x = Int(rawdata.x[i])
        y = Int(rawdata.y[i])
        densitymap[x, y] = translateDensity(value, m)
        #println("$(i)")
    end

    correctionfactor = target / sum(densitymap)
    densitymap = (x->Int.(round(x))).(densitymap' .* correctionfactor)

end

rawdata = getDensityData()
fullmap = generateDensity(rawdata, 80000000, 123123123)
sum(fullmap)

gr()
heatmap(fullmap)






function model_init(properties, densitymap, clusters = 1 ;seed = 123)
    Random.seed!(seed)
    xsize = width(densitymap)
    ysize = height(densitymap)
    space = Space((xsize, ysize), moore = false)
    world = AgentBasedModel(Person, space; properties=properties)

    i = 1
    for x in 1:xsize, y in 1:ysize
        if densitymap[y,x] > 0
            for j in 1:densitymap[y,x]
                p = Person(i, (x,y), true, false, 0, false, 0, false, false)
                add_agent_pos!(p,world)
                i += 1
            end
        end
    end

    for i in 1:clusters
        random_agent(world).infected = 1
    end
    return world
end




function modelstep!(model)
    for node in nodes(model, by = :random)
        nc = get_node_contents(node, model)
        if length(nc) != 0
            for pid in nc

                p = id2agent(pid, model)

                # when a person is infected
                if p.infected

                    p.daysinfected += 1

                    # if not immune, dead, or already sick - make him sick?
                    if !p.dead && !p.immune && !p.sick && p.daysinfected > rand(model.properties[:incubation])
                        if rand() < model.properties[:illness_ratio]
                            p.healthy = false
                            p.sick = true
                            p.dayssick = 1
                        end
                    end

                    if !p.dead && !p.immune && p.sick
                        p.dayssick += 1
                    end
                    # already sick
                    if p.sick && (p.dayssick > rand(model.properties[:duration]))

                        if rand() < model.properties[:severe_ratio]
                            p.dead = true
                        else
                            p.immune = true
                            p.healthy = true
                            p.sick = false
                            p.infected = true
                        end
                    end

                    # infect someone else
                    if rand() < model.properties[:spread_rate]
                        #println("Infecting neighbors")
                        for cell in node_neighbors(node, model)
                            cc = get_node_contents(cell, model)

                            if length(cc) > 0
                        #        println("found neighbours")
                                if rand(1:4) < 2 # only in 1 of 4 cases
                        #            println("found other")
                                    other = id2agent(rand(cc), model)
                                    if !other.dead && !other.immune && other.healthy
                                        other.infected = true
                                        other.healthy = false
                                    end
                                end
                            end
                        end
                    else
                        other = id2agent(rand(nc), model)
                        if !other.dead && !other.immune && other.healthy && (rand() < model.properties[:infection_rate])
                            other.infected = true
                            other.healthy = false
                        end
                    end
                end
            end
        end
    end
    print(".")
end


densitymap = fullmap[350:450, 10:40]
densitymap = fullmap
heatmap(densitymap)
print("Simulating $(sum(densitymap)) people")

props = Dict(
                :R0 => 2.1,
                :incubation => 2:14,
                :illness_ratio => 0.5,
                :severe_ratio => 0.01,
                :duration => 14:36,
                :infection_rate => 0.10,
                :spread_rate => 0.05
)


@time model = model_init(props, densitymap, 10)

agent_properties = Dict(:infected => [sum],
                  :dead => [sum],
                  :sick => [sum],
                  :immune => [sum],
                  :daysinfected => [mean],
                  :dayssick => [mean],
                  :healthy => [sum])

@time results = step!(model, dummystep, modelstep!, 20, agent_properties)

print(results)
