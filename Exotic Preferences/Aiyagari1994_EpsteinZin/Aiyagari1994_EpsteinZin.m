% Example using Aiyagari model but with Epstein-Zin preferences.
%
% DiscountFactorParamNames contains the names for the three parameters relating to
% Epstein-Zin preferences. Calling them beta, gamma, and psi,
% respectively the Epstein-Zin preferences are given by
% U_t= [(1-beta)*u_t^(1-1/psi) + beta (E[U_{t+1}^(1-gamma)])^((1-1/psi)/(1-gamma))]^(1/(1-1/psi))
% where
%  u_t is per-period utility function
%  psi is the elasticity of intertemporal solution
%  gamma is a measure of risk aversion, bigger gamma is more risk averse
%  beta is the standard marginal rate of time preference (discount factor)
%  When 1/(1-psi)=1-gamma, i.e., we get standard von-Neumann-Morgenstern in
%  which the risk aversion and intertemporal elasticity of substition are
%  equal; although note that the role of beta means you will not just get
%  what you might first think of as the relevant von-Neumann-Morgenstern
%  preferences.

%% Use Epstein-Zin preferences. I have put all the lines that relate to Epstein-Zin preferences together to simplify reading.
% There are essentially three parts to using Epstein-Zin preferences.
% 1. Use vfoptions to state that you are using Epstein-Zin preferences.
% 2. Set the appropriate preference parameters.
% 3. Minor adjustment to 'discount factors' and 'return function'.

% The three if statements below are only needed so that you can easily check what happens if not using Epstein-Zin preferences.

% 1. Use vfoptions to state that you are using Epstein-Zin preferences.
vfoptions.exoticpreferences='EpsteinZin'; %Use Epstein-Zin preferences
% To turn off, either don't delare vfoptions.exoticpreferences, or set vfoptions.exoticpreferences='None'
% If you turn this off you would just solve the same model but with standard recursive 
% vonNeumann-Morgerstern expected utility preferences.
% This is intended as purely illustrative. A serious comparison of the preference types would require you to recalibrate the model.
% We are going to use the traditional consumption-units Epstein-Zin
% preferences (rather than utility-units)
vfoptions.EZutils=0;

% 2. Set the appropriate preference parameters.
% Epstein-Zin preference parameters
if strcmp(vfoptions.exoticpreferences,'EpsteinZin')
    Params.gamma=3; % Risk aversion
    Params.psi=0.5; % Intertemporal Elasticity of substitution
    % Need to explain which is which
    vfoptions.EZriskaversion='gamma';
    vfoptions.EZeis='psi';

else
    Params.gamma=2; % Note that for CES parameters, gamma is the CRRA, and
                    % 1/gamma is the intertemporal elasticity of substitution
end

% 3. Minor adjustment to 'return function'.
% Set the return function.
if strcmp(vfoptions.exoticpreferences,'EpsteinZin')
    % Note that gamma has been removed from return function when using Epstein-Zin preferences.
    % To do this now use Aiyagari1994_EpsteinZin_ReturnFn as return fn.
    ReturnFn=@(aprime, a, z,alpha,delta,gamma,r) Aiyagari1994_EpsteinZin_ReturnFn(aprime, a, z,alpha,delta,gamma,r);
    % Note that I could delete gamma from the return function entirely as it is no longer used.
else
    ReturnFn=@(aprime, a, z,alpha,delta,gamma,r) Aiyagari1994_ReturnFn(aprime_val, a, z,alpha,delta,gamma,r);
end
% When using Epstein-Zin preferences the risk aversion is done as part of
% the value function iteration but not as part of the return function
% itself. This is in contrast to standard preferences when the risk
% aversion is done as part of the return function.

% That is all. Every other line of code is unchanged!! Epstein-Zin really is that easy ;)

%% Set some basic variables

n_k=2^9;%2^9;
n_z=21; %21;
n_p=0; % Normally you will want n_p=0, setting a non-zero value here activates the use of a grid on prices.

%Parameters
Params.beta=0.96; %Model period is one-sixth of a year
Params.alpha=0.36;
Params.delta=0.08;
Params.gamma=3;
Params.sigma=0.2;
Params.rho=0.6;

%% Set up the exogenous shock process
%Create markov process for the exogenous labour productivity, l.
[z_grid,pi_z] = discretizeAR1_FarmerToda(0,Params.rho,Params.sigma*sqrt(1-Params.rho^2),n_z);
[z_mean,z_variance,z_corr,~]=MarkovChainMoments(z_grid,pi_z);
z_grid=exp(z_grid);
% Aiyagari 1994 normalizes z_grid to make sure E[z]=1. The following lines do this
%Get some info on the markov process
[Expectation_z,~,~,~]=MarkovChainMoments(z_grid,pi_z); %Since l is exogenous, this will be it's eqm value 
% Normalize z_grid to make E[z]=1 hold exactly
z_grid=z_grid./Expectation_z;
[Expectation_z,~,~,~]=MarkovChainMoments(z_grid,pi_z);
Params.Expectation_z=Expectation_z; % Need to put it in Params so it can be used as part of the general eqm eqn

%% Grids

%In the absence of idiosyncratic risk, the steady state equilibrium is given by
r_ss=1/Params.beta-1;
K_ss=((r_ss+Params.delta)/Params.alpha)^(1/(Params.alpha-1)); %The steady state capital in the absence of aggregate uncertainty.

% Set grid for asset holdings
k_grid=15*K_ss*(linspace(0,1,n_k).^3)'; % The ^3 means most points are near zero, which is where the derivative of the value fn changes most.

%Bring model into the notational conventions used by the toolkit
d_grid=0; %There is no d variable
a_grid=k_grid;
%pi_z;
%z_grid

n_d=0;
n_a=n_k;
%n_z

% Create descriptions of aggregate values as functions of d_grid, a_grid, z_grid 
% (used to calculate the integral across the agent dist fn of whatever functions you define here)
FnsToEvaluate.K = @(aprime,a,z) a; %We just want the aggregate assets (which is this periods state)

%Now define the functions for the General Equilibrium conditions
    %Should be written as LHS of general eqm eqn minus RHS, so that 
    %the closer the value given by the function is to zero, the closer 
    %the general eqm condition is to holding.
%Note: length(AggVars) is length(FnsToEvaluate) and length(p) is length(GEPriceParamNames)
GeneralEqmEqns.CapitalMarket = @(K,r,alpha,delta,Expectation_z) r-(alpha*(K^(alpha-1))*(Expectation_z^(1-alpha))-delta); %The requirement that the interest rate corresponds to the marginal product of capital (net of depreciation)

%%
DiscountFactorParamNames={'beta'};

% ReturnFn=@(aprime_val, a_val, z_val,alpha,delta,gamma,r) Aiyagari1994_ReturnFn(aprime_val, a_val, z_val,alpha,delta,gamma,r);

%%

%Use the toolkit to find the equilibrium price index
GEPriceParamNames={'r'};
%Set initial value for interest rates (Aiyagari proves that with idiosyncratic
%uncertainty, the eqm interest rate is limited above by it's steady state value
%without idiosyncratic uncertainty, that is that r<r_ss).
Params.r=0.04;

%% Calculate the general equilibrium 

% We will just use the default options for simoptions
simoptions=struct();
disp('Calculating price vector corresponding to the stationary eqm')
heteroagentoptions.verbose=1;
[p_eqm,~,GeneralEqmCondn]=HeteroAgentStationaryEqm_Case1(n_d, n_a, n_z, n_p, pi_z, d_grid, a_grid, z_grid, ReturnFn, FnsToEvaluate, GeneralEqmEqns, Params, DiscountFactorParamNames, [], [], [], GEPriceParamNames,heteroagentoptions, simoptions, vfoptions);

p_eqm

%% Now that we have the GE, let's calculate a bunch of related objects
% Equilibrium wage
Params.w=(1-Params.alpha)*((p_eqm.r+Params.delta)/Params.alpha)^(Params.alpha/(Params.alpha-1));

disp('Calculating various equilibrium objects')
Params.r=p_eqm.r;
[~,Policy]=ValueFnIter_Case1(n_d,n_a,n_z,d_grid,a_grid,z_grid, pi_z, ReturnFn, Params, DiscountFactorParamNames, [], vfoptions);

% PolicyValues=PolicyInd2Val_Case1(Policy,n_d,n_a,n_z,d_grid,a_grid);

StationaryDist=StationaryDist_Case1(Policy,n_d,n_a,n_z,pi_z, simoptions);

AggVars=EvalFnOnAgentDist_AggVars_Case1(StationaryDist, Policy, FnsToEvaluate,Params, [],n_d, n_a, n_z, d_grid, a_grid,z_grid);

% Calculate savings rate:
% We know production is Y=K^{\alpha}L^{1-\alpha}, and that L=1
% (exogeneous). Thus Y=K^{\alpha}.
% In equilibrium K is constant, so aggregate savings is just depreciation, which
% equals delta*K. The agg savings rate is thus delta*K/Y.
% So agg savings rate is given by s=delta*K/(K^{\alpha})=delta*K^{1-\alpha}
aggsavingsrate=Params.delta*AggVars.K.Mean^(1-Params.alpha);

% Calculate Lorenz curves, Gini coefficients, and Pareto tail coefficients
FnsToEvaluateFnIneq.Earnings = @(aprime,a,z,w) w*z;
FnsToEvaluateFnIneq.Income = @(aprime,a,z,r,w) w*z+(1+r)*a;
FnsToEvaluateFnIneq.Wealth = @(aprime,a,z) a;
StationaryDist_LorenzCurves=EvalFnOnAgentDist_LorenzCurve_Case1(StationaryDist, Policy, FnsToEvaluateFnIneq, Params,[], n_d, n_a, n_z, d_grid, a_grid, z_grid);

% 3.5 The Distributions of Earnings and Wealth
%  Gini for Earnings
EarningsGini=Gini_from_LorenzCurve(StationaryDist_LorenzCurves.Earnings);
IncomeGini=Gini_from_LorenzCurve(StationaryDist_LorenzCurves.Income);
WealthGini=Gini_from_LorenzCurve(StationaryDist_LorenzCurves.Wealth);

% Calculate inverted Pareto coeff, b, from the top income shares as b=1/[log(S1%/S0.1%)/log(10)] (forgammala taken from Excel download of WTID database)
% No longer used: Calculate Pareto coeff from Gini as alpha=(1+1/G)/2; ( http://en.wikipedia.org/wiki/Pareto_distribution#Lorenz_curve_and_Gini_coefficient)
% Recalculte Lorenz curves, now with 1000 points
StationaryDist_LorenzCurves=EvalFnOnAgentDist_LorenzCurve_Case1(StationaryDist, Policy, FnsToEvaluateFnIneq, Params,[], n_d, n_a, n_z, d_grid, a_grid, z_grid, [],1000);
EarningsParetoCoeff=1/((log(StationaryDist_LorenzCurves.Earnings(990))/log(StationaryDist_LorenzCurves.Earnings(999)))/log(10)); %(1+1/EarningsGini)/2;
IncomeParetoCoeff=1/((log(StationaryDist_LorenzCurves.Income(990))/log(StationaryDist_LorenzCurves.Income(999)))/log(10)); %(1+1/IncomeGini)/2;
WealthParetoCoeff=1/((log(StationaryDist_LorenzCurves.Wealth(990))/log(StationaryDist_LorenzCurves.Wealth(999)))/log(10)); %(1+1/WealthGini)/2;


%% Display some output about the solution

%plot(cumsum(sum(StationaryDist,2))) %Plot the asset cdf

fprintf('For parameter values sigma=%.2f, gamma=%.2f, rho=%.2f \n', [Params.sigma,Params.gamma,Params.rho])
fprintf('The table 1 elements are sigma=%.4f, rho=%.4f \n',[sqrt(z_variance), z_corr])

fprintf('The equilibrium value of the interest rate is r=%.4f \n', p_eqm.r*100)
fprintf('The equilibrium value of the aggregate savings rate is s=%.4f \n', aggsavingsrate)
%fprintf('Time required to find the eqm was %.4f seconds \n',findeqmtime)

