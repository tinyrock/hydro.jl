using Test

include("../src/Hydro.jl")
using .Hydro

@testset "Hydro.jl" begin
    @testset "Rainfall funoff models" begin
        include("gr4j.jl")
    end

    @testset "Transforms" begin
        include("transforms.jl")
    end

    @testset "Verification" begin
        include("verification.jl")
    end
end
