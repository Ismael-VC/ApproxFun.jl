export plan_chebyshevtransform, plan_ichebyshevtransform, chebyshevtransform, ichebyshevtransform

## Transforms take values at Chebyshev points of the first and second kinds and produce Chebyshev coefficients

#TODO confirm that this can handle T=Complex{Float64} looks like this is a real-to-real transform

function plan_chebyshevtransform{T<:FFTW.fftwNumber}(x::Vector{T};kind::Integer=1)
    if kind == 1
        length(x)==1?identity:FFTW.plan_r2r(x, FFTW.REDFT10)
    elseif kind == 2
        length(x)==1?identity:FFTW.plan_r2r(x, FFTW.REDFT00)
    end
end

function chebyshevtransform{T<:FFTW.fftwNumber}(x::Vector{T},plan::Function;kind::Integer=1)
    if kind == 1
        ret=negateeven!(plan(x))
        ret[1]/=2
        ret/=length(x)
    elseif kind == 2
        n = length(x)
        if n == 1
            x
        else
            ret = plan(x)
            ret[1] /= 2;ret[end] /= 2
            negateeven!(ret)./(n-1)
        end
    end
end
chebyshevtransform{T<:FFTW.fftwNumber}(x::Vector{T};kind::Integer=1)=chebyshevtransform(x,plan_chebyshevtransform(x;kind=kind);kind=kind)

#following Chebfun's @Chebtech1/vals2coeffs.m and @Chebtech2/vals2coeffs.m
function chebyshevtransform{T<:Number}(x::Vector{T};kind::Integer=1)
    if kind == 1
        n = length(x)
        if n == 1
            x
        else
            w = [2exp(im*convert(T,π)*k/2n) for k=0:n-1]
            ret = w.*ifft([reverse(x);x])[1:n]
            ret = T<:Real ? real(ret) : ret
            ret[1] /= 2
            ret
        end
    elseif kind == 2
        n = length(x)
        if n == 1
            x
        else
            ret = ifft([reverse(x),x[2:end-1]])[1:n]
            ret = T<:Real ? real(ret) : ret
            ret[2:n-1] *= 2
            ret
        end
    end
end


## Inverse transforms take Chebyshev coefficients and produce values at Chebyshev points of the first and second kinds


function plan_ichebyshevtransform{T<:FFTW.fftwNumber}(x::Vector{T};kind::Integer=1)
    if kind == 1
        length(x)==1?identity:FFTW.plan_r2r(x, FFTW.REDFT01)
    elseif kind == 2
        length(x)==1?identity:FFTW.plan_r2r(x, FFTW.REDFT00)
    end
end

function ichebyshevtransform{T<:FFTW.fftwNumber}(x::Vector{T},plan::Function;kind::Integer=1)
    if kind == 1
        x[1] *=2
        ret = plan(negateeven!(x))/2
        negateeven!(x)
        x[1]/=2
        ret
    elseif kind == 2
        n = length(x)
        if n == 1
            x
        else
            ##TODO: make thread safe
            x[1] *= 2;x[end] *= 2
            ret = chebyshevtransform(x,plan;kind=kind)
            x[1] /=2;x[end] /=2
            ret[1] *= 2;ret[end] *= 2
            negateeven!(ret)
            ret *= .5*(n-1)
            reverse!(ret)
        end
    end
end
ichebyshevtransform{T<:FFTW.fftwNumber}(x::Vector{T};kind::Integer=1)=ichebyshevtransform(x,plan_ichebyshevtransform(x;kind=kind);kind=kind)

#following Chebfun's @Chebtech1/vals2coeffs.m and @Chebtech2/vals2coeffs.m
function ichebyshevtransform{T<:Number}(x::Vector{T};kind::Integer=1)
    if kind == 1
        n = length(x)
        if n == 1
            x
        else
            w = exp(-im*convert(T,π)*[0:2n-1]/2n)/2
            w[1] *= 2;w[n+1] *= 0;w[n+2:end] *= -1
            ret = fft(w.*[x,one(T),x[end:-1:2]])[n:-1:1]
            ret = T<:Real ? real(ret) : ret
        end
    elseif kind == 2
        n = length(x)
        if n == 1
            x
        else
            ##TODO: make thread safe
            x[1] *= 2;x[end] *= 2
            ret = chebyshevtransform(x;kind=kind)
            x[1] /=2;x[end] /=2
            ret[1] *= 2;ret[end] *= 2
            negateeven!(ret)
            ret *= .5*(n-1)
            reverse!(ret)
        end
    end
end

## Code generation for integer inputs

for func in (:chebyshevtransform,:ichebyshevtransform)
    @eval $func{T<:Integer}(x::Vector{T};kind::Integer=1)=$func(float64(x);kind=kind)
end


# Matrix inputs


function chebyshevtransform{T<:FFTW.fftwNumber}(X::Matrix{T};kind::Integer=1)
    if kind == 1
            if size(X) == (1,1)
            X
        else
            R=negateeven!(FFTW.r2r(X,FFTW.REDFT10))
            R[:,1]/=2;R[1,:]/=2;
            R/=size(X,1)*size(X,2)
        end
    elseif kind == 2
        if size(X) == (1,1)
            X
        else
            R=FFTW.r2r(X,FFTW.REDFT00)/((size(X,1)-1)*(size(X,2)-1))
            R[:,1]/=2;R[:,end]/=2
            R[1,:]/=2;R[end,:]/=2
            negateeven!(R)
        end
    end
end

function ichebyshevtransform{T<:Number}(X::Matrix{T};kind::Integer=1)
    if kind == 1
        if size(X) == (1,1)
            X
        else
            X[1,:]*=2;X[:,1]*=2
            R = FFTW.r2r(negateeven!(X),FFTW.REDFT01)/4
            negateeven!(X)
            X[1,:]/=2;X[:,1]/=2
            R
        end
    elseif kind == 2
        if size(X) == (1,1)
            X
        else
            X[1,:]*=2;X[end,:]*=2;X[:,1]*=2;X[:,end]*=2
            R=chebyshevtransform(X;kind=kind)
            X[1,:]/=2;X[end,:]/=2;X[:,1]/=2;X[:,end]/=2
            R[1,:]*=2;R[end,:]*=2;R[:,1]*=2;R[:,end]*=2
            negateeven!(R)
            R*=(size(X,1)-1)*(size(X,2)-1)/4
            flipud(fliplr(R))
        end
    end
end


# Helper routines


function negateeven!(x::Vector)
    for k =2:2:length(x)
        x[k] = -x[k]
    end
    x
end

#checkerboard, same as applying negativeeven! to all rows then all columns
function negateeven!(X::Matrix)
    for k =2:2:size(X,1),j=1:2:size(X,2)
        X[k,j] *= -1
    end
    for k =1:2:size(X,1),j=2:2:size(X,2)
        X[k,j] *= -1
    end
    X
end
