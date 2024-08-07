function F=Aiyagari1994_2shocks_ReturnFn(aprime,a,z1,z2,alpha,delta,mu,r)
% The return function is essentially the combination of the utility
% function and the constraints.

F=-Inf;
w=(1-alpha)*((r+delta)/alpha)^(alpha/(alpha-1));
c=w*z1*z2+(1+r)*a-aprime; % Budget Constraint

if c>0
    if mu==1
        F=log(c);
    else
        F=(c^(1-mu) -1)/(1-mu);
    end
end

end