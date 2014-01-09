

export Interval



## Standard interval

type Interval{T<:Number} <: IntervalDomain
	a::T
	b::T
end

Interval()=Interval(-1.,1.)
function Interval(d::Vector)
    @assert length(d) == 2
    
    Interval(d[1],d[2])
end


Base.convert{D<:Interval}(::Type{D},i::Vector)=Interval(i)
Interval(a::Number,b::Number) = Interval(promote(a,b)...)




## Map interval



tocanonical(d::Interval,x)=(d.a + d.b - 2x)/(d.a - d.b)
tocanonicalD(d::Interval,x)=2/( d.b- d.a)
fromcanonical(d::Interval,x)=.5*(d.a + d.b) + .5*(d.b - d.a)x
fromcanonicalD(d::Interval,x)=.5*( d.b- d.a)



Base.length(d::Interval) = d.b - d.a



==(d::Interval,m::Interval) = d.a == m.a && d.b == m.b



##Integration and differentiation


# diff T -> U, then convert U -> T
function Base.diff{T<:Number,M<:Interval}(f::IFun{T,M})

    # TODO: Will need to change code for other domains
    @assert typeof(f.domain) <: Interval
    
    tocanonicalD(f.domain,0)*IFun(ultraiconversion(ultradiff(f.coefficients)),f.domain)
end

function integrate{T<:Number,M<:Interval}(f::IFun{T,M})
    # TODO: Will need to change code for other domains
    @assert typeof(f.domain) <: Interval
    
    fromcanonicalD(f.domain,0)*IFun(ultraint(ultraconversion(f.coefficients)),f.domain)    
end


    