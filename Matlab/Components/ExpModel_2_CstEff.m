function [out,TS] = ExpModel_2_CstEff(fluid, P_su, h_su, M_dot, P_ex, T_amb, param)

% fluid, P_su, h_su, N_exp, P_ex, T_amb, param % <-- Unconmment to see the inputs of the external call

%% CODE DESCRIPTION
% ORCmKit - an open-source modelling library for ORC systems

% Remi Dickes - 11/05/2016 (University of Liege, Thermodynamics Laboratory)
% rdickes @ulg.ac.be
%
% "ExpModel_2_CstEff.m" is a matlab code implementing a constant-efficiency model
% of volumetric expanders (see the Documentation/ExpModel_2_SemiEmp_MatlabDoc)
% Unlike "ExpModel_CstEff.mat" which takes as input N_exp and computes M_dot, 
% this code derives the expander rotational speed based on the inlet mass flow rate.
%
% The model inputs are:
%       - P_su: inlet pressure of the WF                          	[Pa]
%       - h_su: inlet temperature of the WF                        	[J/kg]
%       - P_ex: outlet pressure of the WF                          	[Pa]
%       - fluid: nature of the fluid (string)                       [-]
%       - M_dot: fluid mass flow rate                               [kg/s]
%       - T_amb : ambien temperature                                [K]
%       - param: structure variable containing the model parameters
%
% The model paramters provided in 'param' should contain the followings:
%           param.V_s , machine displacement volume                	[m3]
%           param.V, volume of the expander                         [m^3]
%           param.epsilon_is, isentropic efficiency                	[-]
%           param.FF, filling factor (volumetric efficiency)       	[-]
%           param.h_min, minimum enthalpy of the fluid              [J/kg]
%           param.h_max, maximum enthalpy of the fluid              [J/kg]
%
% The model outputs are:
%       - out: a structure variable which includes
%               - T_ex =  exhaust temperature                    [K]
%               - h_ex =  exhaust enthalpy                       [J/kg]
%               - M_dot = fluid mass flow rate                   [kg/s]
%               - W_dot = mechanical power                       [W]
%               - Q_dot_amb = ambiant losses                     [W]
%               - epsilon_is = isentropic efficiency             [-]
%               - FF = filling factor (volumetric efficiency)    [-]
%               - time = the code computational time             [sec]
%               - flag = simulation flag                         [-1/1]
%               - M = mass of refrigerent inside the expaner     [kg]
%
%       - TS : a stucture variable which contains the vectors of temperature
%              and entropy of the fluid (useful to generate a Ts diagram 
%              when modelling the entire ORC system 
%
% See the documentation for further details or contact rdickes@ulg.ac.be

%% DEMONSTRATION CASE -- COMMENT THIS SECTION IF EXTERNAL CALL FOR SPEED IMPROVEMENT
% if nargin == 0
%     % Define a demonstration case if ExpanderModel.mat is not executed externally
%     fluid = 'R245fa';                           %Nature of the fluid
%     M_dot = 0.15982;                            %Mass flow rate         [kg/s]
%     P_su = 6.753498330038136e+05;               %Supply pressure        [Pa]
%     h_su = 4.052843743508205e+05;               %Supply enthalpy        [J/kg]
%     P_ex = 2.471310061849047e+05;               %Exhaust pressure       [Pa]
%     T_amb = 298.1500;                           %Ambient temperature    [K]
%     param.epsilon_is = 0.7;
%     param.FF = 1.2;
%     param.AU_amb = 0.674005126953125;
%     param.V_s = 1.279908675799087e-05;
%     param.V = 1.492257e-3;
%     param.h_max =  CoolProp.PropsSI('H','P',4e6,'T',500,fluid);
%     param.h_min =  CoolProp.PropsSI('H','P',5e4,'T',253.15,fluid);
% end

%% MODELLING SECTION
tstart_exp = tic;

T_su = CoolProp.PropsSI('T','P',P_su,'H',h_su,fluid);
s_su = CoolProp.PropsSI('S','P',P_su,'H',h_su,fluid);
rho_su = CoolProp.PropsSI('D','P',P_su,'H',h_su,fluid);
h_ex_s = CoolProp.PropsSI('H','P',P_ex,'S',s_su,fluid);

if P_su > P_ex && h_su > CoolProp.PropsSI('H','P',P_su,'Q',0,fluid)
    
    N_exp = 60*M_dot/(param.V_s*param.FF*rho_su);
    W_dot =  M_dot*(h_su-h_ex_s)*param.epsilon_is;
    Q_dot_amb = max(0,param.AU_amb*(T_su - T_amb));
    FF = param.FF;
    epsilon_is = param.epsilon_is;
    h_ex = h_su - (W_dot+Q_dot_amb)/M_dot;
    if h_ex > param.h_min && h_ex < param.h_max
        out.flag = 1;
    else
        out.flag = -1;
    end
    
else
    out.flag = -2;
end

if out.flag > 0
    out.h_ex = h_ex;
    out.N_exp = N_exp;
    out.W_dot = W_dot;
    out.Q_dot_amb = Q_dot_amb;
    out.epsilon_is = epsilon_is;
    out.FF = FF;
    out.T_ex = CoolProp.PropsSI('T','P',P_ex,'H',out.h_ex,fluid);
    out.M = (CoolProp.PropsSI('D','H',h_su,'P',P_su,fluid)+CoolProp.PropsSI('D','H',out.h_ex,'P',P_ex,fluid))/2*param.V;   
else
    out.N_exp = 60*M_dot/(param.V_s*rho_su);
    out.FF = 1;
    out.W_dot = M_dot*(h_su-h_ex_s);
    out.epsilon_is =1;
    out.Q_dot_amb = 0;
    out.h_ex = h_ex_s;
    out.T_ex = CoolProp.PropsSI('T','P',P_ex,'H',out.h_ex,fluid);
    out.M = (CoolProp.PropsSI('D','H',h_su,'P',P_su,fluid)+CoolProp.PropsSI('D','H',out.h_ex,'P',P_ex,fluid))/2*param.V;
end

TS.T = [T_su out.T_ex];
TS.s = [s_su CoolProp.PropsSI('S','H', out.h_ex,'P', P_ex, fluid)];
out.time = toc(tstart_exp);

end