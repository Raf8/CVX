function [x_var, v_var, p_star_series, residue_series, x_star_ref] = IPM_MulticommodityFlow
% Interior Point Method -- "Multicommodity Flow" ECE1505 Pset 4 Q2

% Problem description: 
%
% minimize sum(xi/(ci - xi))
%
% subject to
%            0 <= x <= c
%            B*x <= bb
%            Ap*x == s
%
% 1. Define all problem parameters and data:
N = 8;              % number of nodes
L = 13;             % number of links (variables)
c = ones(L,1);
bb = [1, 1, 1]';
s = [1.2, 0.6, 0.6, zeros(1,N-1-3)]';
Ap = zeros(N-1,L);
Ap(1,1) = 1; Ap(1,2) = 1; Ap(1,3) = 1;
Ap(2,1) = -1; Ap(2,4) = 1; Ap(2,6) = 1;
Ap(3,3) = -1; Ap(3,5) = 1; Ap(3,8) = 1;
Ap(4,2) = -1; Ap(4,4) = -1; Ap(4,5) = -1; Ap(4,7) = 1;
Ap(5,7) = -1; Ap(5,9) = 1; Ap(5,10) = 1; Ap(5,12) = 1;
Ap(6,6) = -1; Ap(6,9) = -1; Ap(6,11) = 1;
Ap(7,8) = -1; Ap(7,10) = -1; Ap(7,13) = 1;
B = zeros(3,L);
B(1,4) = 1; B(1,6) = 1; 
B(2,5) = 1; B(2,8) = 1;
B(3,9) = 1; B(3,10) = 1; B(3,12) = 1;

% For checking correctness, we can solve the problem using CVX by changing
% the objective to sum of square of x. Should yield same x* (?), and later
% we can compare via sum(square(x_var)) from our IPM method to p_star_ref.
cvx_begin quiet
    variable x(L)
    minimize sum(square(x)) % is monotonic as original objective over feasible domain
    subject to 
        0 <= x <= c
        B*x <= bb
        Ap*x == s
cvx_end
p_star_ref = cvx_optval;
x_star_ref = x;

% 2. Set up parameters for Interior Point Method
numOuterItrs = 0;
numInnerItrs = 0;
x0 = 0.1*ones(L,1); % This point is strictly in the domain of barrier function
t_ipm = 1;        % initial barrier param
eps_ipm = 1.49e-8; % standard with CVX
norm_tol = 3e-5; % in practice, need a check on the backtracking line search on norm since it can get
                   % 'low enough' to be considered solved, but not low
                   % enough for the algorithm condition to be true.
mu_ipm = 8;       % barrier increase factor
m_Ineqs = 2*L + 3; % 'm', i.e. the number of inequalities
x_var = x0;        % initialize the variable
v_var = zeros(size(Ap',2),1); % dual variable associated with Ap*x == s

% Set up vars for ISNM:
A = Ap;
b = s;  % excuse the double use of 'b'; this is the problem equality b,
        % while the inequality quantity 'bb' is for the switching capacity
        % constraint, i.e. B*x <= bb
residual_curr = [grad_f(t_ipm,x_var,c,B,bb) + A'*v_var; A*x_var - b];

p_star_series = [objective(x_var,c)];  % for part c) plot
residue_series = [norm(residual_curr)+m_Ineqs/t_ipm]; % for part d) plot

% Parameters for the Infeasible Start Newton's Method:
alpha = 0.25;
beta = 0.7;
eps_isnm = 1.49e-8;

% Helper functions: get the relevant gradients, Hessians -- see end of script

while (m_Ineqs/t_ipm >= eps_ipm) % OUTER LOOP - Barrier Method
    % 1. Centering step: x_var <-- argmin{ t*f0(x) + phi(x) | A*x == b }
    while (1) % INNER LOOP - Infeasible Start Newton Method
        
        % Solve KKT system for x_nt, v_nt: 
        K = [hess_f(t_ipm,x_var,c,B,bb), A'; A, zeros(N-1)];
        nt = -K\residual_curr; % could solve via elimination of (1,1) block for faster solve
        x_nt = nt(1:L); v_nt = nt(L+1:end); % now we have primal-dual directions

        % Backtracking Line Search
        t_isnm = 1;
        res_t_isnm = [grad_f(t_ipm,(x_var+t_isnm*x_nt),c,B,bb) + A'*(v_var+t_isnm*v_nt); A*(x_var+t_isnm*x_nt) - b];
        while (norm(res_t_isnm) > (1 - alpha*t_isnm)*norm(residual_curr))
            t_isnm = beta*t_isnm;
            res_t_isnm = [grad_f(t_ipm,(x_var+t_isnm*x_nt),c,B,bb) + A'*(v_var+t_isnm*v_nt); A*(x_var+t_isnm*x_nt) - b];
            %norm(res_t_isnm)
            norm(residual_curr)
            if (norm(res_t_isnm) < norm_tol)
                break; % this can happen if we are optimal b/w outer loops (i.e. increasing t yields no change)
            end
        end

        % Updates
        x_var = x_var + t_isnm*x_nt; 
        v_var = v_var + t_isnm*v_nt;
        residual_curr = res_t_isnm;
        residue_series = [residue_series, norm(residual_curr)+m_Ineqs/t_ipm]; 
        numInnerItrs = numInnerItrs + 1;

        if (norm(residual_curr) < eps_isnm || norm(residual_curr) < norm_tol)
            disp('yo!');
            break;
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%% DONE CENTERING STEP %%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Update: x_var is already (and constantly) updated
    t_ipm = t_ipm*mu_ipm;    % Increase t
    % Now update the residual for this new t: 
    residual_curr = [grad_f(t_ipm,x_var,c,B,bb) + A'*v_var; A*x_var - b];
    numOuterItrs = numOuterItrs + 1
    p_star_series = [p_star_series, objective(x_var,c)]; % from centering step
end

% Finally, project onto feasible set in case of any numerical errors:
for i=1:L
    if (x_var(i) < 0)
        x_var(i) = 0;
    end
    if (x_var(i) > c(i))
        x_var(i) = c(i);
    end
end

end


% Helper functions: get the relevant gradients, Hessians
function grad = grad_f0(x,c)
    L = size(x,1);
    grad = zeros(L,1); 
    for i=1:L 
        grad(i) = c(i)/((c(i)-x(i))^2); 
    end 
end

function ei = e_i(i,n)
    ei = zeros(n,1);
    ei(i) = 1;
end

function grad = grad_phi(x,c,B,bb)
    L = size(x,1);
    L2 = size(B,1);
    grad = zeros(L,1);
    for i=1:L
        term1 = (1/(-x(i)) + 1/(c(i) - x(i)))*e_i(i,L);
        grad = grad + term1;
    end
    for i=1:L2
        B_row = B(i,:);
        term2 = (1/(bb(i) - B_row*x))*B_row';
        grad = grad + term2;
    end
end

function H = hess_f0(x,c)
    L = size(x,1);
    H = zeros(L,L);
    for i=1:L
        H(i,i) = 2*c(i) / ((c(i) - x(i))^3);
    end
end

function H = hess_phi(x,c,B,bb)
    L = size(x,1);
    L2 = size(B,1);
    H = zeros(L,L);
    for i=1:L
        ei = e_i(i,L);
        term1 = (1/(x(i)^2) + 1/((x(i) - c(i))^2))*(ei*ei');
        H = H + term1;
    end
    for i=1:L2
        B_row = B(i,:);
        term2 = (1/((B_row*x - bb(i))^2))*(B_row'*B_row); %outer product, not scalar
        H = H + term2;
    end
end

% Composite functions -- helps make inner loop (ISNM) cleaner
function grad = grad_f(t,x,c,B,bb)
    grad = t*grad_f0(x,c) + grad_phi(x,c,B,bb);
end

function H = hess_f(t,x,c,B,bb)
    H = t*hess_f0(x,c) + hess_phi(x,c,B,bb);
end

function f0 = objective(x,c)
    L = size(x,1); f0 = 0;
    for i=1:L
        f0 = f0 + x(i)/(c(i)-x(i));
    end
end




