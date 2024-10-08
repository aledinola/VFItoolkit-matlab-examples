function CapitalMarket_res = fun_GE(r,Params,n_d,n_a,n_z,d_grid,a_grid,z_grid, pi_z, ReturnFn,DiscountFactorParamNames,vfoptions,simoptions,FnsToEvaluate)

Params.r = r;

%% VFI
[~,Policy]=ValueFnIter_Case1(n_d,n_a,n_z,d_grid,a_grid,z_grid, pi_z, ReturnFn, Params, DiscountFactorParamNames, [], vfoptions);

%% Statdist
StationaryDist=StationaryDist_Case1(Policy,n_d,n_a,n_z,pi_z, simoptions);

%% Aggvars
AggVars=EvalFnOnAgentDist_AggVars_Case1(StationaryDist, Policy, FnsToEvaluate,Params, [],n_d, n_a, n_z, d_grid, a_grid,z_grid);
K_mean = AggVars.K.Mean;

%% Market clearing condition
CapitalMarket_res = r-(Params.alpha*(K_mean^(Params.alpha-1))*(Params.Expectation_l^(1-Params.alpha))-Params.delta);

CapitalMarket_res = gather(CapitalMarket_res);

disp(CapitalMarket_res)

end