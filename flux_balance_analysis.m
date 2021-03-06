% Flux Balance Analysis problem 
%
% FBA is the conservation of mass applied to metabolites inside a cell.
% Metabolites are small molecules that are products of metabolism. 
%
% We define a stoichiometry matrix to encode data of relative reaction
% masses, each column representing a rxn (n columns) corresponding to the m
% possible metabolites (m rows). 
%
% S(i,j) > 0 is the relative rate of production of metabolite i in rxn j 
% inside the cell. Multiplying by the appropriate rxn rate v(j) gives mass 
% flow per time. S(i,j)<0 implies that metabolite i is being consumed in 
% rxn j. 
%
% A reaction such as M1 --> M2 + 2*M3 as rxn 1 would yield the first column
% of S to be (-1, 1, 2, 0, ..., 0)'. M1 is consumed, M2 and M3 are
% produced.
%
% A reaction can also represent a metabolite entering or leaving a cell;
% M1 entering the cell would be represented as (1, 0, ..., 0)' while M6
% leaving the cell would be (0, 0, 0, 0, 0, -1, 0, ..., 0)'.
%
% The final reaction represents biomass creation, i.e. cell growth. Using
% the same conventions for S(i,j), S(i,n) gives the amounts of metabolite i
% used (<0) or created (>0) per unit of cell growth rate.
%
% We want to find this maximum possible growth rate of the cell, v(n),
% consistent with the constaints of mass balance (S*v == 0), and bounded
% reaction rates 0 <= v <= vmax. Our objective is essentially e'*v, where e
% = e(n) = (0, 0, ..., 0, 1)'.


% data file for flux balance analysis in systems biology
% From Segre, Zucker et al "From annotated genomes to metabolic flux
% models and kinetic parameter fitting" OMICS 7 (3), 301-316. 

% Stoichiometric matrix
S = [
%	M1	M2	M3	M4	M5	M6	
	1	0	0	0	0	0	%	R1:  extracellular -->  M1
	-1	1	0	0	0	0	%	R2:  M1 -->  M2
	-1	0	1	0	0	0	%	R3:  M1 -->  M3
	0	-1	0	2	-1	0	%	R4:  M2 + M5 --> 2 M4
	0	0	0	0	1	0	%	R5:  extracellular -->  M5
	0	-2	1	0	0	1	%	R6:  2 M2 -->  M3 + M6
	0	0	-1	1	0	0	%	R7:  M3 -->  M4
	0	0	0	0	0	-1	%	R8:  M6 --> extracellular
	0	0	0	-1	0	0	%	R9:  M4 --> cell biomass
	]';

[m,n] = size(S);
vmax = [
	10.10;	% R1:  extracellular -->  M1
	100;	% R2:  M1 -->  M2
	5.90;	% R3:  M1 -->  M3
	100;	% R4:  M2 + M5 --> 2 M4
	3.70;	% R5:  extracellular -->  M5
	100;	% R6:  2 M2 --> M3 + M6
	100;	% R7:  M3 -->  M4
	100;	% R8:  M6 -->  extracellular
	100;	% R9:  M4 -->  cell biomass
	];

en = zeros(n,1); en(n) = 1;

cvx_begin
    variable v(n);
    dual variable l1;
    dual variable l2;
    dual variable mu;
    maximize (en'*v);
    subject to 
        l1: 0 <= v;
        l2: v <= vmax;
        mu: S*v == 0;
cvx_end

Gstar = cvx_optval;
% Note: our optimal lagrange multiplier we care about is l2 as the optimal
% lagrange multiplier for reaction rate limits.
% From this we see that R1,R3,R5 have nonzero lagrange multipliers, with
% l(5) being the largest. Thus the maximum growth rate is most sensitive to 
% the 5th reaction rate limit. 

%testing - did I derive the correct dual problem?
cvx_begin
    variable ll1(n);
    variable ll2(n);
    variable mmu(m);
    maximize (-ll2'*vmax);
    subject to
        ll1 >= 0;
        ll2 >= 0;
        S'*mmu + ll2 - ll1 - en == 0;
cvx_end
% yep. Strong duality holds as this is an inequality LP. We have that p* =
% -d* because in deriving the dual we put maximize f0 to minimize -f0, thus
% for the dual we have to invert its sign back again. 

% should have l1 == ll1, l2 == ll2, mu == mmu

% Part 2: Essential Genes and Synthetic Lethals
%
% Assuming a gene Gi controls reaction Ri, we can model the effect of
% "knocking out" gene Gi as setting the rxn rate v(i) to zero (i.e. vmax(i)
% --> 0). 
%
% We note that this necessarily reduces the maximum possible growth
% rate. Taking a look at our example S, we see that cell biomass (growth) 
% depends on the consumption of metabolite M4.
%
% There are 3 total reactions involving M4; multiplying out the
% stoichiometry by their reaction rates, we get a formula like:
%
% (2*v(2))M4 + (2*v(4))M4 = (v(6))M4, where the RHS is growth
%
% Clearly if a gene rate limits v(2) or v(4), we can expect less growth.
% If the maximum growth rate approaches zero, our model states that we have
% cell death.
%
% Essential genes are those such that when knocked out, the max growth rate
% v(n) is reduced below a threshold Gmin. Synthetic lethals are pairs of
% non-essential genes such that when knocked out, their combined effeect is
% that of an essential gene (dropping max growth rate below a threshold). 
%
% Using the threshold Gmin = 0.2*Gstar, we will find essential genes and
% synthetic lethals. 
%

% Essential Genes: try knocking one out, test new optimal value against
% threshold.
Gmin = 0.2*Gstar;
essentialGenes = zeros(n,1);
for i=1:n
   vmax_test = vmax;
   vmax_test(i) = 0;
   cvx_begin quiet 
    variable v(n);
    dual variable l1;
    dual variable l2;
    dual variable mu;
    maximize (en'*v);
    subject to 
        l1: 0 <= v;
        l2: v <= vmax_test;
        mu: S*v == 0;
    cvx_end 
    if (cvx_optval < Gmin)
       disp(strcat('Gene is essential: ',num2str(i),' with growth rate: ',num2str(cvx_optval))); 
       essentialGenes(i) = 1;
    end
end

% Synthetic lethals: knock out all pairs of genes. We can cross-reference
% with above results to ensure that we don't count essential genes in here.
for i=1:n
   if (essentialGenes(i) == 1)
       continue;
   end
   for j=i:n
       if (essentialGenes(j) == 1)
          continue; 
       end
       vmax_test = vmax;
       vmax_test(i) = 0;
       vmax_test(j) = 0;
       cvx_begin quiet 
        variable v(n);
        dual variable l1;
        dual variable l2;
        dual variable mu;
        maximize (en'*v);
        subject to 
            l1: 0 <= v;
            l2: v <= vmax_test;
            mu: S*v == 0;
        cvx_end 
        if (cvx_optval < Gmin)
           disp(strcat('Gene pair is synthetic lethal: {',num2str(i),',',num2str(j),'} with growth rate: ',num2str(cvx_optval))); 
        end
    end
end