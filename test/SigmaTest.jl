using ApproxFun, Base.Test

#The first test checks the solution of the integral equation
# u(x) + \int_{-1}^{+1} \frac{e^{y} u(y)}{\sqrt{1-y^2}} dy = f
# on the interval [-1,1].

x=Fun(identity)
w=1/sqrt(1-x^2)
d=domain(x)

S=Σ(d)

@test domainspace(S) == JacobiWeight{Chebyshev}(-0.5,-0.5,Chebyshev())

L=I+S[exp(x)*w]
usol=sin(2x)
f=L*usol
u=L\f
@test norm(u-usol) <= 10eps()


#The second test checks the solution of the integro-differential equation
# u'(x) + x u(x) + \int_{-2}^{+2} sin(y-x) u(y) \sqrt{4-y^2} dy = f
# on the interval [-2,2], with u(-2) = 1.

x=Fun(identity,[-2.,2.])
w=sqrt(4-x^2)
d=domain(x)

D=Derivative(d)
B=ldirichlet(d)
S=Σ(.5,.5,d)

@test domainspace(S) == JacobiWeight{Ultraspherical{1}}(.5,.5,Ultraspherical{1}(d))

K=LowRankFun((x,y)->sin(y-x)*w[y],Ultraspherical{1}(d),domainspace(S))


L=D+x+S[K]
usol=cospi(20x)
f=L*usol
u=[B;L]\[1.;f]


@test norm(u-usol) ≤ 100eps()




f1=Fun(t->cos(cos(t)),[-π,π])
f=Fun(t->cos(cos(t)),Laurent([-π,π]))

@test_approx_eq sum(f1) Σ()*f

f1=Fun(t->cos(cos(t))/t,Laurent(Circle()))
f2=Fun(t->cos(cos(t))/t,Fourier(Circle()))
@test_approx_eq Σ()*f1 Σ()*f2

f1=Fun(t->cos(cos(t)),Laurent([-π,π]))
f2=Fun(t->cos(cos(t)),Fourier([-π,π]))
@test_approx_eq Σ()*f1 Σ()*f2


