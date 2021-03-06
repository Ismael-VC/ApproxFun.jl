
import Base.chop

# Used for spaces not defined yet
immutable UnsetNumber <: Number  end
Base.promote_rule{N<:Number}(::Type{UnsetNumber},::Type{N})=N


Base.real(::Type{UnsetNumber})=UnsetNumber
Base.real{T<:Real}(::Type{T})=T
Base.real{T<:Real}(::Type{Complex{T}})=T
Base.eps{T<:Real}(::Type{Complex{T}})=eps(real(T))

dotu(f::Vector{Complex{Float64}},g::Vector{Complex{Float64}})=BLAS.dotu(f,g)
dotu{N<:Real}(f::Vector{Complex{Float64}},g::Vector{N})=dot(conj(f),g)
dotu{N<:Real,T}(f::Vector{N},g::Vector{T})=dot(f,g)


## Helper routines
alternatingvector(n::Integer) = 2*mod([1:n],2) .- 1

function alternatesign!(v::Vector)
    n=length(v)
    for k=2:2:n
        v[k]=-v[k]
    end

    v
end

alternatesign(v::Vector)=alternatesign!(copy(v))



function pad!{T}(f::Vector{T},n::Integer)
	if n > length(f)
		append!(f,zeros(T,n - length(f)))
	else
		resize!(f,n)
	end
end


function pad{T}(f::Vector{T},n::Integer)
	if n > length(f)
	   ret=Array(T,n)
	   ret[1:length(f)]=f
	   for j=length(f)+1:n
	       ret[j]=zero(T)
	   end
       ret
	else
        f[1:n]
	end
end

function pad(f::Vector{Any},n::Integer)
	if n > length(f)
        Any[f...,zeros(n - length(f))...]
	else
        f[1:n]
	end
end

function pad(v::Vector,n::Integer,m::Integer)
    @assert m==1
    pad(v,n)
end

function pad{T}(A::Matrix{T},n::Integer,m::Integer)
	if n <= size(A,1) && m <= size(A,2)
        A[1:n,1:m]
	elseif n==0 || m==0
	   Array(T,n,m)  #fixes weird julia bug when T==None
    else   
        ret = zeros(T,n,m)

        if n <= size(A,1)
            for k=1:n,j=1:size(A,2)
                ret[k,j]=A[k,j]
            end
        elseif m <= size(A,2)
            for k=1:size(A,1),j=1:m
                ret[k,j]=A[k,j]
            end
        else
            ret[1:size(A,1),1:size(A,2)]=A
        end

        ret
	end
end

pad(A::Matrix,::Colon,m::Integer)=pad(A,size(A,1),m)
pad(A::Matrix,n::Integer,::Colon)=pad(A,n,size(A,2))


#TODO:padleft!

function padleft(f::Vector,n::Integer)
	if (n > length(f))
        [zeros(n - length(f)),f]
	else
        f[end-n+1:end]
	end
end



##chop!
function chop!(c::Vector,tol::Real)
    @assert tol >= 0

    for k=length(c):-1:1
        if abs(c[k]) > tol
            resize!(c,k)
            return c
        end
    end

    resize!(c,0)
    c
end

chop(f::Vector,tol)=chop!(copy(f),tol)
chop!(f::Vector)=chop!(f,eps())


function chop!(A::Array,tol)
    for k=size(A,1):-1:1
        if norm(A[k,:])>tol
            A=A[1:k,:]
            break
        end
    end
    for k=size(A,2):-1:1
        if norm(A[:,k])>tol
            A=A[:,1:k]
            break
        end
    end
    return A
end

