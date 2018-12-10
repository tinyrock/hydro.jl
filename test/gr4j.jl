using CSV
using DataFrames
using BenchmarkTools

@testset "GR4J" begin

    data = CSV.read("test/data/test_data.csv", header=1)
    names!(data, Symbol.(["date", "obs_rain", "obs_pet", "obs_runoff", "test_sim_runoff"]))

    @testset "Single timestep" begin
        pars = gr4j_reasonable_parameters()
        init_state = gr4j_init_state(pars)

        @test gr4j_run_step(0, 0, init_state, pars)[1] == 0
        @test gr4j_run_step(100, 5, init_state, pars)[1] ≈ 0.0014248522376373149
        @test gr4j_run_step(1000, 0, init_state, pars)[1] ≈ 1.0416849478510568
    end

    @testset "2 year simulation" begin
        pars = gr4j_parameters(320.1073, 2.4208, 69.6276, 1.3891)
        init_state = gr4j_init_state(pars)
        init_state["production_store"] = pars["x1"] * 0.6
        init_state["routing_store"] = pars["x3"] * 0.7

        result = simulate(gr4j_run_step, data, pars, init_state)

        @test isapprox(result[1, :test_sim_runoff], result[1, :runoff_sim], atol=0.0001)
        @test isapprox(result[400, :test_sim_runoff], result[400, :runoff_sim], atol=0.0001)
        @test isapprox(result[728, :test_sim_runoff], result[728, :runoff_sim], atol=0.0001)
    end

    @testset "Benchmarks" begin
        # typical timestep in less than 50 microseconds
        pars = gr4j_reasonable_parameters()
        init_state = gr4j_init_state(pars)
        init_state["production_store"] = pars["x1"] * 0.6
        init_state["routing_store"] = pars["x3"] * 0.7

        typical = @belapsed gr4j_run_step(10, 5, $init_state, $pars)
        @test typical < (50 * 1e-6)

        # huge X4 doesn't cost more than an extra 10 millisecond
        pars["x4"] = 40
        init_state = gr4j_init_state(pars)
        init_state["production_store"] = pars["x1"] * 0.6
        init_state["routing_store"] = pars["x3"] * 0.7

        huge_x4 = @belapsed gr4j_run_step(10, 5, $init_state, $pars)
        @test (huge_x4 - typical) < (10 * 1e-6)

        # two paths through production store cost the same
        pars = gr4j_parameters(320.1073, 2.4208, 69.6276, 1.3891)
        init_state = gr4j_init_state(pars)
        init_state["production_store"] = pars["x1"] * 0.6
        init_state["routing_store"] = pars["x3"] * 0.7

        evap_path = @belapsed gr4j_run_step(5, 100, $init_state, $pars)
        precip_path = @belapsed gr4j_run_step(100, 5, $init_state, $pars)
        @test isapprox(evap_path, precip_path, atol=1e-6)

        # simulation of 2 years data should take less than 50 milliseconds
        @test (@belapsed simulate(gr4j_run_step, $data, $pars, $init_state)) < (50 * 1e-3)
    end
end
