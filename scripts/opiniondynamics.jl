using DrWatson
@quickactivate "tutorial"
using Statistics


using Agents
using Statistics: mean

mutable struct HKAgent{T <: AbstractFloat} <: AbstractAgent
    id::Int
    old_opinion::T
    new_opinion::T
end

function hk_model(;numagents = 100, ϵ = 0.4)
    model = ABM(HKAgent, scheduler = fastest,
                properties = Dict(:ϵ => ϵ))
    for i in 1:numagents
        o = rand()
        add_agent!(model, o, o)
    end
    return model
end

get_old_opinion(agent)::Float64 = agent.old_opinion

function boundfilter(agent,model)
    filter(j -> abs(get_old_opinion(agent) - j) < model.properties[:ϵ],
      get_old_opinion.(values(model.agents)))
end

function agent_step!(agent, model)
    agent.new_opinion = mean(boundfilter(agent,model))
end

function updateold(a)
    a.old_opinion = a.new_opinion
    return a
end

function model_step!(model)
    for i in keys(model.agents)
        agent = id2agent(i, model)
        updateold(agent)
    end
end

function model_run(; numagents = 100, iterations = 50, ϵ = 0.05)
    model = hk_model(numagents = numagents, ϵ = ϵ)
    when = 0:1:iterations
    agent_properties = [:new_opinion]
    data = step!(
            model,
            agent_step!,
            model_step!,
            iterations,
            agent_properties,
            when = when
            )
    return(data)
end

data = model_run(numagents = 20, iterations = 20)
data[end-19:end, :]

using Plots

plotsim(data, ϵ) = plot(
                        data[!, :step],
                        data[!, :new_opinion],
                        leg= false,
                        group = data[!, :id],
                        title = "epsilon = $(ϵ)"
                        )

plt001,plt015,plt03, plt04 = map(
                          e -> (model_run(ϵ= e), e) |>
                          t -> plotsim(t[1], t[2]),
                          [0.05, 0.15, 0.3, 0.4]
                          )

plot(plt001, plt015, plt03, plt04, layout = (2,2))
