using DrWatson
@quickactivate "tutorial"
DrWatson.greet()


using Agents, Random

mutable struct Tree <: AbstractAgent
    id::Int
    pos::Tuple{Int, Int}
    status::Bool  # true is green and false is burning
end


function model_initiation(; f, d, p, griddims, seed = 111)
    Random.seed!(seed)
    space = Space(griddims, moore = true)
    properties = Dict(:f => f, :d => d, :p => p)
    forest = AgentBasedModel(Tree, space; properties=properties)

    # create and add trees to each node with probability d,
    # which determines the density of the forest
    for node in nodes(forest)
        if rand() ≤ forest.properties[:d]
            add_agent!(node, forest, true)
        end
    end
    return forest
end

forest = model_initiation(f=0.05, d=0.8, p=0.05, griddims=(20, 20), seed=2)

forest


function forest_step!(forest)
  for node in nodes(forest, by = :random)
    nc = get_node_contents(node, forest)
    # the cell is empty, maybe a tree grows here
    if length(nc) == 0
        rand() ≤ forest.properties[:p] && add_agent!(node, forest, true)
    else
      tree = id2agent(nc[1], forest) # by definition only 1 agent per node
      if tree.status == false  # if it is has been burning, remove it.
        kill_agent!(tree, forest)
      else
        if rand() ≤ forest.properties[:f]  # the tree ignites spntaneously
          tree.status = false
        else  # if any neighbor is on fire, set this tree on fire too
          for cell in node_neighbors(node, forest)
            neighbors = get_node_contents(cell, forest)
            length(neighbors) == 0 && continue
            if any(n -> !forest.agents[n].status, neighbors)
              tree.status = false
              break
            end
          end
        end
      end
    end
  end
end


step!(forest, dummystep, forest_step!)
forest





step!(forest, dummystep, forest_step!, 10)
forest

forest = model_initiation(f=0.05, d=0.4, p=0.00, griddims=(20, 20), seed=2)


percentage(x) = count(x)/nv(forest)

agent_properties = Dict(:status => [percentage])



data = step!(forest, dummystep, forest_step!, 10, agent_properties)

data

forest = model_initiation(f=0.05, d=0.8, p=0.01, griddims=(20, 20), seed=5)
agent_properties = [:status, :pos]

data = step!(forest, dummystep, forest_step!, 10, agent_properties);

data

using AgentsPlots

p = plot2D(data, :status, t=1, cc=Dict(true=>"green", false=>"red"), nodesize=8)
p = plot2D(data, :status, t=2, cc=Dict(true=>"green", false=>"red"), nodesize=8)

agent_properties = [:status, :pos]
data = step!(forest, dummystep, forest_step!, 10, agent_properties, replicates=10)


using DataVoyager
Voyager(data)
