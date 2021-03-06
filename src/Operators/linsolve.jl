## Linear Solve


function stridelinsolve(Ad,b,tolerance,maxlength)
    L=Ad[end]
    #TODO: general
    u1=adaptiveqr([FillFunctional(2.),
        SliceOperator(L,-1,-1,2,2)],[b[2]+b[1],b[3:2:end]...],tolerance,maxlength)
    u2=adaptiveqr([FillFunctional(2.),
        SliceOperator(L,0,0,2,2)],[b[2]-b[1],b[4:2:end]...],tolerance,maxlength)
    interlace(u1,u2)
end




function linsolve{T<:Operator,N<:Number}(A::Vector{T},b::Array{N};tolerance=0.01eps(eltype(A[end])),maxlength=1000000)
    A=promotedomainspace(A,choosedomainspace(A))
    if length(A)==3&&
            isa(A[1],Evaluation{Chebyshev,Bool,Float64})&&
            isa(A[2],Evaluation{Chebyshev,Bool,Float64})&&
            !A[1].x && A[2].x &&
            length(bandrange(A[end]))≥25&&
            iseven(stride(A[end]))
        r=stridelinsolve(A,b,tolerance,maxlength)
    else
        r=adaptiveqr(A,b,tolerance,maxlength)
    end

    #all rows of Ad should have same domain space
    ds=domainspace(A[end])
    # If ds is a ArraySpace and r is a matrix, then
    # the constructor in ArraySpace converts to matrix
    isa(ds,AnySpace)?r:Fun(r,ds)
end

function linsolve{T<:Operator}(A::Vector{T},b::Array{Any};tolerance=0.01eps(eltype(A[end])),maxlength=1000000)
 #TODO: depends on ordering of A
    for k=1:length(A)-1
        @assert isa(A[k],Functional)
    end

    for k=1:min(length(A)-1,size(b,1)),j=1:size(b,2)
        @assert isa(b[k,j],Number)
    end




    #TODO: Use information from b to promote range space if necessary
    if size(b,1)<size(A,1)
        # the ... converts b to a tuple of numbers so that r is a number Vec
        r=reshape([b...],size(b))
        A=promotedomainspace(A,choosedomainspace(A))
    elseif size(b,1)==size(A,1)
        if isa(b[end,1],Fun)
            # Convert to a number vector

            bend=b[end,:]
            typ=mapreduce(eltype,promote_type,bend)
            ds=choosedomainspace(A,space(b[end,1]))
            A=promotedomainspace(A,ds)
            
            # coefficients in the rangespace
            rs=rangespace(A[end])            
            cfsB=Vector{typ}[coefficients(b[end,k],rs) for k=1:size(b,2)]
            
            
            m=mapreduce(length,max,cfsB)  # max length of rhs
            #TODO: this only works if space conversion doesn't increase size

            r=isa(b,Vector)?Array(typ,size(b,1)-1+m):Array(typ,size(b,1)-1+m,size(b,2))

            # assign boundary rows
            r[1:size(b,1)-1,:]=b[1:end-1,:]

 
            for k=1:size(b,2)
                r[size(b,1):size(b,1)+length(cfsB[k])-1,k]=cfsB[k]
                for j=size(b,1)+length(cfsB[k]):size(r,2)
                    r[j,k]=zero(typ)  # fill with zeros
                end
            end
        else
            #TODO: matrix
            @assert size(b,2)==1
            r=[b[1:end-1]...;b[end]...]  #b[end] is probably a vector or a number
        end
    else
        @assert size(b,2)==1
        # we have list of possible funs, devec
        rhs=b[size(A,1):end]
        if all(f->isa(f,Fun),rhs)
            be=devec(rhs)
            sp=choosedomainspace(A,space(be))
            A=promotedomainspace(A,sp)

            r=[b[1:size(A,1)-1]...;coefficients(be,rangespace(A[end]))]
        else
            #TODO: Don't remember what this case is for
            r=[b[1:size(A,1)-1]...;interlace(rhs)]
        end
    end

    linsolve(A,r;tolerance=tolerance,maxlength=maxlength)
end


function linsolve{T<:Operator,F<:Fun}(A::Vector{T},b::Array{F};kwds...)
    r=Array(Any,size(b))

    # convert constant funs to constants
    # this undoes the effect of [0.,f]
    for k=1:size(A,1)-1,j=1:size(b,2)
        # we only allow constants
        @assert length(b[k,j])==1
        #TODO: 1,1 entry may not be zero
        r[k,j]=b[k,j].coefficients[1]
    end

    r[size(A,1):end,:]=b[size(A,1):end,:]

    linsolve(A,r;kwds...)
end


linsolve{S,T}(A::Operator,b::Fun{S,T};kwds...)=linsolve([A],[b];kwds...)
linsolve(A::Operator,b::Number;kwds...)=linsolve([A],b*ones(rangespace(A));kwds...)
linsolve{T<:Operator}(A::Vector{T},b::Number;kwds...)=linsolve(A,[b];kwds...)
linsolve{S,Q,T<:Operator}(A::Vector{T},b::Fun{S,Q};kwds...)=linsolve(A,[b];kwds...)
linsolve{T<:Operator}(A::Array{T,2},b;kwds...)=linsolve(interlace(A),b;kwds...)
linsolve(A::Operator,b::Array;kwds...)=linsolve([A],b;kwds...)


\{T<:Operator}(A::Matrix{T},b::Union(Array,Number,Fun))=linsolve(A,b)
\{T<:Operator}(A::Vector{T},b::Union(Array,Number,Fun))=linsolve(A,b)
\(A::Operator,b)=linsolve(A,b)

