function [xafter, tafter, xbefore, tbefore] = step2(xin, flag);
% STEP2   Simulate 1 step and calculate state after impact.
%
% [xafter, tafter, xbefore, tbefore] = step2(xin, flag);
%
% INPUTS:
% + xin = input state vector, angles and their rates of change. 
% + flag = takes the string 'allow no contact'. If this string passed in, 
%   step2 will allow the walker to _not_ make a step within 10 seconds. 
%   Otherwise the simulation treats xin as part of an unstable limit cycle.
%
% OUTPUTS:
% + xafter = state after impact. If 'allow no contact' specified, xafter =
%   xbefore(end,:).
% + tafter = time at impact. If 'allow no contact' specified, tafter =
%   tbefore(end,:).
% + xbefore = vector of the states at each integration time, up to impact.
% + tbefore = vector of times for each state
%
% NOTES:
% + Returned values are either all finite or all null.
% + All inputted angles are modded by 2*pi, but allowed to keep their sign.
%   If the state after impact is greater than 2*pi, step2 returns nulls.
% + If any of the input values are greater than 1E7, they are rejected.
%
% Notice that ode45 outputs our variables in reverse order, compared to how
% we output our variables.
%

debug = 0;

global M Mp g L R K alpha slope mu eqnhandle dim wd invalidResults

% initialize the invalid results flag
invalidResults = 0;

if size(xin) ~= [1 dim]
    fprintf('step2 error: Input state vector must have 1 row and %i cols.\n', dim);
    xafter = [];
    tafter = [];
    xbefore = [];
    tbefore = [];
    return
end

% Restrict values of the input vector
if norm(xin) > 1E8
    fprintf('step2 warning: Input state too large. Stopping run.\n');
    xafter = [];
    tafter = [];
    xbefore = [];
    tbefore = [];
    return
end

if nargin == 1 | length(flag) == 0
    flag = 'disallow';
end

% Mod the input angles, it seems to help the results make sense.
xin = [rem(xin(1:3), 2*pi) xin(4:end)];

% Perform the integration
tspan = [0 10];
options = odeset('Events', 'guard2', 'RelTol', 2.22045e-014, 'AbsTol', 1e-20); %, 'OutputFcn', @odeplot, 'Refine', 4, 'OutputSel', [1 2 3]); %'AbsTol', 1e-6, 'RelTol', 1e-7); %'AbsTol', 1e-20, 'RelTol', 2.22045e-014); %, 'OutputFcn', @odeplot, 'OutputSel', [1 2]); 
[t x tcontact xcontact] = ode45(eqnhandle, tspan, xin, options);

% Check to see if eqns2 encountered NaN or Inf
if invalidResults == 1
    xafter = [];
    tafter = [];
    xbefore = [];
    tbefore = [];
    return
end

% Check to see if ode45 produced NaN or Inf
if isnan(xin) ~= zeros(size(xin)) | isinf(xin) ~= zeros(size(xin))
    xafter = [];
    tafter = [];
    xbefore = [];
    tbefore = [];
    return
end

% Decide how to process 
if (length(xcontact) == 0 | length(tcontact) == 0) & strcmp(flag, 'allow no contact') == 0 % If no contact
    if (debug == 1) 
        fprintf('step2 warning: No contact made w/ slope in %i seconds, stopping run.\n', tspan(2));
    end
    xafter = [];
    tafter = [];
    xbefore = [];
    tbefore = [];
    return
elseif size(xcontact)*[1 0]' > 1 | length(tcontact) > 1 % If > 1 contact
    % A relevant question: why does ode45 trigger multiple times?
    % It could have something to do with the value of isterminal.
    % If isterminal = 0 when all other conditions are met at a certain 
    % state, then ode45 may be saving that state but proceeding with the
    % integration. Something to check up on in the future.
    if debug == 1
        fprintf('step2 warning: Found %i false event trigger(s).\n', size(xcontact)*[1 0]'-1);
    end
    tcontact = tcontact(end);
    xcontact = xcontact(end,:);
end

% Check for valid output. It's sometimes NaN or Inf.
vnames = {'x'; 'xcontact'};
for i=1:length(vnames)
    vector = eval(char(vnames(i)));
    if isfinite(vector) ~= ones(size(vector))
        if (debug == 1)
            fprintf('step2 warning: Values are not finite, rejecting output.\n');
        end
        xafter = [];
        tafter = [];
        xbefore = [];
        tbefore = [];
        return
    end
end

% Check for negative guard value. This means the swing leg passed through
% the slope w/o making contact.
% for i=1:size(x)*[1 0]'
%     if guard2(t(i), x(i,:)) < 0
%         if (debug == 1) 
%             fprintf('step2 warning: Guard function is negative at t = %f, rejecting output.\n', t(i));
%         end
%         xafter = [];
%         tafter = [];
%         xbefore = [];
%         tbefore = [];
%         return
%     end
% end

% Check if any of the angles before impact exceed 2*pi. This suggests full
% rotation through the slope surface, or legs that kick all the way around.
% if find(abs(xcontact(:,1:dim/2)) > 2*pi) ~= 0
%     if (debug == 1) 
%         fprintf('step2 warning: Walker has angles that exceed 2*pi, rejecting output.\n');
%     end
%     xafter = [];
%     tafter = [];
%     xbefore = [];
%     tbefore = [];
%     return
% end

% Get state after impact.
if strcmp(flag, 'allow no contact') == 1 & (length(xcontact) == 0 | length(tcontact) == 0)
    if (debug == 1) 
        fprintf('step2 warning: No contact made w/ slope in %i seconds, but allowing anyways.\n', tspan(2));
    end
    xcontact = x(end,:);
    tcontact = t(end,:);
    xafter = xcontact;
else
    xafter = feval(eqnhandle, xcontact, 'i')';
end

tafter = tcontact;
xbefore = x;
tbefore = t;


% function [xafter, tafter, xbefore, tbefore] = step2(xin);
% % STEP2   Simulate 1 step, and calculate the step after impact.
% %
% % [xafter, tafter, xbefore, tbefore] = step2(xin);
% %
% % xafter = state after impact
% % tafter = time at impact
% % xbefore = vector of the states at each integration time, up to impact.
% % tbefore = vector of times for each state.
% %
% % Notice that ode45 outputs our variables in reverse order, compared to how
% % we output our variables.
% %
% 
% debug = 1;
% 
% global M Mp g L R K slope eqnhandle dim
% 
% tspan = [0 10];
% options = odeset('Events', 'guard2', 'AbsTol', 1e-6, 'RelTol', 1e-7); %, 'OutputFcn', @odeplot, 'OutputSel', [1 2]); 
% [t x tcontact xcontact] = ode45(eqnhandle, tspan, xin, options);
% % [t x tcontact xcontact] = ode45(@eqns2, tspan, xin, options);
% 
% if (length(xcontact) == 0 | length(tcontact) == 0)
% %     fprintf(1, '\nstep2 error: Guard does not trigger before %i secs. RESULTS ARE INCORRECT.\n\n', tspan(2));
% %     xcontact = x(end, :);
%     % I should put a return statement here, but I want the program to
%     % terminate itself; and if called by walk2 then I want instability to
%     % show itself!
% %     xafter = [];
% %     tafter = [];
% %     xbefore = [];
% %     tbefore = [];
% %     return
%     xcontact = x(end,:);
%     tcontact = t(end,:);
%     
% elseif length(tcontact) > 1 & size(xcontact) == [2 4]
%     % The state after and before impact will trigger the event function, in
%     % this case guard2, at time t = 0.00000000, but ode45 ignores this very
%     % first event trigger and so we end up with a tcontact and xcontact
%     % with more than 1 row, corresponding to multiple event triggers! This
%     % seems bad. To do: double check ode45 code and verify that they ignore
%     % triggers at the start of integration.
%     tcontact = tcontact(2);
%     xcontact = xcontact(2,:);
% end
% 
% % Check for negative guard value. This means the swing leg passed through
% % the slope w/o making contact.
% % for i=1:size(x)*[1 0]'
% %     if guard2(t(i), x(i,:)) < 0
% %         if (debug == 1) 
% %             fprintf('step2 warning: Guard function is negative at t = %f, rejecting output.\n', t(i));
% %         end
% %         xafter = [];
% %         tafter = [];
% %         xbefore = [];
% %         tbefore = [];
% %         return
% %     end
% % end
% 
% xafter = feval(eqnhandle, xcontact, 'i')';
% % xafter = eqns2(xcontact, 'i')';
% tafter = tcontact;
% xbefore = x;
% tbefore = t;
