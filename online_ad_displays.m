% When a user goes to a website, one of a set of n ads, labeled 1,�,n, is displayed. This is called an impression. 
% We divide some time interval (say, one day) into T periods, labeled t=1,�,T. Let Nit?0 denote the number of 
% impressions in period t for which we display ad i. In period t there will be a total of It>0 impressions, so we 
% must have ?ni=1Nit=It, for t=1,�,T. (The numbers It might be known from past history.) You can treat all these 
% numbers as real. (This is justified since they are typically very large.)
% The revenue for displaying ad i in period t is Rit?0 per impression. (This might come from click-through payments, 
% for example.) The total revenue is ?Tt=1?ni=1RitNit. To maximize revenue, we would simply display the ad with the 
% highest revenue per impression, and no other, in each display period.
% We also have in place a set of m contracts that require us to display certain numbers of ads, or mixes of ads (say,
% associated with the products of one company), over certain periods, with a penalty for any shortfalls. Contract j is
% characterized by a set of ads Aj?{1,�,n} (while it does not affect the math, these are often disjoint), a set of periods
% Tj?{1,�,T}, a target number of impressions qj?0, and a shortfall penalty rate pj>0.
% The shortfall sj for contract j is
% sj=??qj??t?Tj?i?AjNit??+,
% where (u)+ means max{u,0}. (This is the number of impressions by which we fall short of the target value qj.) Our contracts
% require a total penalty payment equal to ?mj=1pjsj. Our net profit is the total revenue minus the total penalty payment.
% Use convex optimization to find the display numbers Nit that maximize net profit. The data in this problem are R?Rn�T, I?RT 
% (here I is the vector of impressions, not the identity matrix), and the contract data Aj, Tj, qj, and pj, j=1,�,m.
% Carry out your method on the problem with data given in ad_disp_data.m. The data Aj and Tj, for j=1,�,m are given by matrices 
% Acontr?Rn�m and Tcontr?RT�m, with
% Acontrij={10i?Ajotherwise,Tcontrtj={10t?Tjotherwise.
% What is the optimal net profit?

% data for online ad display problem
rand('state',0);
n=100;      %number of ads
m=30;       %number of contracts
T=60;       %number of periods

I=10*rand(T,1);  %number of impressions in each period
R=rand(n,T);    %revenue rate for each period and ad
q=T/n*50*rand(m,1);     %contract target number of impressions
p=rand(m,1);  %penalty rate for shortfall
Tcontr=(rand(T,m)>.8); %one column per contract. 1's at the periods to be displayed
for i=1:n
	contract=ceil(m*rand);
	Acontr(i,contract)=1; %one column per contract. 1's at the ads to be displayed
end

cvx_begin
    variable N(n,T);
    s = pos(q - diag(Acontr'*N*Tcontr)); %defining s as this convex function of N
    maximize (R(:)'*N(:) - p'*s);
    subject to
        N >= 0; %every element in matrix
        N'*ones(n,1) == I;
        
        
cvx_end

opt_profit = cvx_optval; 
opt_s = s;
opt_penalty = p'*opt_s;
opt_revenue = opt_profit + opt_penalty;

% Now try again being greedy, i.e. not satisfying contracts:

cvx_begin
    variable N(n,T);
    maximize (R(:)'*N(:));
    subject to
        N >= 0; %every element in matrix
        N'*ones(n,1) == I;
cvx_end

greedy_shortfall = pos(q-diag(Acontr'*N*Tcontr));
greedy_penalty = p'*greedy_shortfall;
greedy_profit = cvx_optval - greedy_penalty;
greedy_revenue = cvx_optval;

opt_revenue
opt_penalty
opt_profit

greedy_revenue
greedy_penalty
greedy_profit

