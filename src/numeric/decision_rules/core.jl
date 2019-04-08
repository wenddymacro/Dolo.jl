abstract type AbstractDecisionRule{S<:Grid,T<:Grid,nx} end

function Base.show(io::IO, dr::AbstractDecisionRule)
    println(io, typeof(dr))
end

outdim(dr::AbstractDecisionRule{<:Grid,<:Grid,nx}) where nx = nx


# ---------------------- #
# Constant decision rule #
# ---------------------- #

mutable struct ConstantDecisionRule{nx} <: AbstractDecisionRule{EmptyGrid,EmptyGrid,nx}
    constants::SVector{nx,Float64}
end

function ConstantDecisionRule(constants::Vector{Float64})
    nx = length(constants)
    ConstantDecisionRule{nx}(SVector{nx,Float64}(constants...))
end

function ConstantDecisionRule(model::Model)
    ConstantDecisionRule(model.calibration[:controls])
end

(dr::ConstantDecisionRule)(x::Point) = dr.constants
(dr::ConstantDecisionRule)(x::Vector{Point{d}}) where d = [dr.constants for n=1:length(x)]
(dr::ConstantDecisionRule)(i::Int, x::Union{Point{d},Vector{Point{d}}}) where d = dr(x)
(dr::ConstantDecisionRule)(i::Int, j::Int, x::Union{Point{d},Vector{Point{d}}}) where d = dr(x)

# (dr::ConstantDecisionRule)(x::AbstractVector, y::AbstractVector) = dr.constants
# (dr::ConstantDecisionRule)(x::AbstractVector, y::AbstractMatrix) = repeat(dr.constants', size(y, 1), 1)
# (dr::ConstantDecisionRule)(x::AbstractMatrix, y::AbstractVector) = repeat(dr.constants', size(x, 1), 1)
# (dr::ConstantDecisionRule)(x::AbstractMatrix, y::AbstractMatrix) = repeat(dr.constants', size(x, 1), 1)
# (dr::ConstantDecisionRule)(i::Int, x::Union{AbstractVector,AbstractMatrix}) = dr(x)
# (dr::ConstantDecisionRule)(i::Int, j::Int, x::Union{AbstractVector,AbstractMatrix}) = dr(x)

# ------------------------------ #
# 2-dimensional Taylor Expansion #
# ------------------------------ #

mutable struct BiTaylorExpansion{nx} <: AbstractDecisionRule{EmptyGrid,EmptyGrid,nx}
    m0::Vector{Float64}
    s0::Vector{Float64}
    x0::Vector{Float64}
    x_m::Matrix{Float64}
    x_s::Matrix{Float64}
end

(dr::BiTaylorExpansion)(m::Point, s::Point) = SVector( (dr.x0 + dr.x_m*(m-dr.m0) + dr.x_s*(s-dr.s0))... )

(dr::BiTaylorExpansion)(m::AbstractVector{<:Point}, s::AbstractVector{<:Point}) = [dr(m[i], s[i]) for i=1:length(s)]

(dr::BiTaylorExpansion)(m::AbstractVector, s::AbstractVector) = Array(dr(SVector(m...), SVector(s...)))
(dr::BiTaylorExpansion)(m::AbstractMatrix, s::AbstractVector) = vcat([(dr(m[i, :], s))' for i=1:size(m, 1) ]...)
(dr::BiTaylorExpansion)(m::AbstractVector, s::AbstractMatrix) = vcat([(dr(m, s[i, :]))' for i=1:size(s, 1) ]...)
(dr::BiTaylorExpansion)(m::AbstractMatrix, s::AbstractMatrix) = vcat([(dr(m[i, :], s[i, :]))' for i=1:size(m, 1) ]...)


# User defined functions
struct CFunDR{S,T,nx} <: AbstractDecisionRule{S,T,nx}
    fun::Function
    dprocess::AbstractDiscretizedProcess
end
CFunDR(fun::Function, dprocess::AbstractDiscretizedProcess, n_x::Int) = CFunDR{typeof(dprocess.grid), EmptyGrid, n_x}(fun, dprocess)
(cfdr::CFunDR)(i::Int, x::Point{d}) where d = cfdr.fun(node(Point, cfdr.dprocess,i),x)
(cfdr::CFunDR)(i::Int, x::Vector{Point{d}}) where d = [cfdr(i,e) for e in x]
