function status = animate3(xcycle, option);
% ANIMATE3   Visualize the walker walking down a slope. May need to edit
% depending on the model.
%
% INPUT: 
% + xcycle = vector of the states at each integration step. See walk3.
% + option = 0 for standard animation, 1 for walking w/o resetting the
%   axes, 2 for walking w/o resetting the axes and also for holding the
%   points on the graph.   
%
% OUTPUT:
% + status = 1 if successful (usually is) and 0 otherwise. This feature
%   will change in the future, to pass out a handle/pointer to an avi/mpg
%   object. This will happen only if I can figure out a way to decrease
%   processor time when drawing.
%
% Notes:
% Avoid running anything computationally intensive when you use  this
% animation.
%
% Original code of the UC Berkeley CHESS Bipeds research group.
% http://chess.eecs.berkeley.edu/bipeds
% Please direct bug reports and related inquiries to Eric D.B. Wendel, 
% ericdbw@berkeley.edu.
%

global w l slope modeldir wd

status = 0;

if nargin ~= 2
    option = 0; % Reset axes as default
end

% Set the default erase mode
if option == 2
    style = 'none';
else
    style = 'xor';
end

if strcmp(modeldir, 'C:\Documents and Settings\Eric Wendel\My Documents\research\dev\3D/pointfoot-midlegmass/controlled/nohip') ~= 1
    fprintf(1, 'The animation script currently only works for option 3.\n');
else

% Parse input
t = xcycle(:,1);
roll = xcycle(:,2);
stance = xcycle(:,3);
nstance = xcycle(:,4);

% Translate the angles into locations in 3D Cartesian space
vect = [0 0 l]'; % The vector in the non/stance leg reference frames
Rs = zeros(3, 3);
Rns = zeros(3, 3);
Rr = zeros(3, 3);
stanceleg = zeros(3, size(t,1));
nstanceleg = zeros(3, size(t,1));
impactpt = zeros(3, size(t,1));
j = 1; k = 1;
for i=1:size(t,1)    
    % The following rotation matrices are from leg ref frame to world frame
    Rs = [1 0              0              
          0 cos(stance(i)) -sin(stance(i))
          0 sin(stance(i)) cos(stance(i))];
    Rns = [1 0               0                 
           0 cos(nstance(i)) sin(nstance(i))
           0 sin(nstance(i)) -cos(nstance(i))];
    Rr = [cos(roll(i))  0 -sin(roll(i))
          0             1 0
          sin(roll(i))  0 cos(roll(i))];

    % Make sure the robot actually moves forward by saving the point of
    % impact with the ground.
    if i > 2
        if t(i) == t(i-1)
            impactpt(:,i) = nstanceleg(:,i-1);
            adjust(j) = i;
            j = j + 1;
        else
            impactpt(:,i) = impactpt(:,i-1);
        end
    end

    % Assemble points using rigid-body kinematics
    stanceleg(:,i) = impactpt(:,i) + Rr*(Rs*vect);
    nstanceleg(:,i) = stanceleg(:,i) + Rr*(Rns*vect);
end      

% Assemble the robot
sx = [impactpt(1,:)' stanceleg(1,:)']; % Stance points
sy = [impactpt(2,:)' stanceleg(2,:)'];
sz = [impactpt(3,:)' stanceleg(3,:)'];
nsx = [stanceleg(1,:)' nstanceleg(1,:)']; % Nonstance points
nsy = [stanceleg(2,:)' nstanceleg(2,:)'];
nsz = [stanceleg(3,:)' nstanceleg(3,:)'];
groundx = [nstanceleg(1,:)' impactpt(1,:)']; % Ground points (slope)
groundy = [nstanceleg(2,:)' impactpt(2,:)'];
groundz = [nstanceleg(3,:)' impactpt(3,:)'];
projx = [sx nsx]; % Shadow on the ground (z = 0 surface)
projy = [sy nsy];
twody = [sy nsy]; % 2D projection (x = .5 surface)
twodz = [sz nsz];

% Create figure
screenSize = get(0, 'ScreenSize');
if option == 0
    width = screenSize(3)/2;
    left = screenSize(3)/4;
    bottom = screenSize(4)/4;
    height = screenSize(4)/2;
elseif option == 1 | option == 2
    width = screenSize(3);
    left = 0;
    bottom = screenSize(4)/4;
    height = screenSize(4)/1.5;
end
figure('Position', [left bottom width height])

% Create graphics objects
sleg = line(sx(1,:), sy(1,:), sz(1,:), 'EraseMode', style, 'Marker', '.', 'Color', 'b');
nsleg = line(nsx(1,:), nsy(1,:), nsz(1,:), 'EraseMode', style, 'Marker', '.', 'Color', [0 .5 0]);
ground = line(groundx(1,:), groundy(1,:), groundz(1,:), 'EraseMode', 'none', 'Marker', '.', 'Color', 'k');
proj = line(projx(1,:), projy(1,:), [0 0 0 0], 'EraseMode', 'xor', 'Color', [.5 .5 .5]);
twod = line([0 0 0 0], twody(1,:), twodz(1,:), 'EraseMode', 'xor', 'Color', [.5 .25 .25]);
if option == 2
    set(proj, 'EraseMode', 'none')
    set(twod, 'EraseMode', 'none')
end

% Adjust axes
if option == 0
    stride = norm([sy(1,:) nsy(1,:) groundy(1,:)]) - min(sy(1,:)); 
    ymin = min(nsy(1,:)) - 1.5; ymax = norm(nsy(1,:)) + 1.5;
elseif option == 1 | option == 2
    stride = 0;
    ymin = min(nsy(1,:)) - 1.5; ymax = norm (nsy(1,:)) + 4;
end
xmin = min(groundx(1,:)) - .5; xmax = max(groundx(1,:)) + .5;
zmin = min(sz(1,:)) - .1; zmax = norm(sz(1,:)) + .1;
axis([ xmin xmax ymin ymax zmin zmax ])
axis fill

% Set the 3D viewpoint
if strcmp(modeldir(size(wd,2)-1:size(wd,2)), '2D')
    view([-90 0])
elseif strcmp(modeldir(size(wd,2)-1:size(wd,2)), '3D')
    view([-20 30])
    box on
end

% Draw and create movie
j = 1;
xlabel('x')
ylabel('y')
zlabel('z')
for i=2:size(t,1)
    % Make adjustments on impact
    if length(find(adjust == i)) ~= 0
        % Draw the ground
        set(ground, 'XData', groundx(i,:), 'YData', groundy(i,:), 'ZData', groundz(i,:))
        
        % Swap colors
        if get(sleg, 'Color') == [0 0 1]
            set(sleg, 'Color', [0 .5 0]);
            set(nsleg, 'Color', [0 0 1]);
        else
            set(sleg, 'Color', [0 0 1]);
            set(nsleg, 'Color', [0 .5 0]);
        end
        if option == 0
            stride = abs(max(groundy(i,:)) - min(groundy(i,:))) - .05; % minus .05 because it isn't realistic if it just walks in place.
            xmin = min(groundx(i,:)) - .5; xmax = norm(groundx(i,:)) + .5;
            ymin = ymin + stride; ymax = ymax + stride;
            axis([ xmin xmax ymin ymax zmin zmax ])
            axis fill
        end
    end
    
    % Rotate viewpoint as you animate - computationally intensive!
%     azi = linspace(30, -30, size(t,1));
%     el = linspace(-25, 25, size(t,1));
%     view([azi(i) el(i)])

    if option == 2
        if  length(find(adjust == i)) ~= 0
            set(sleg, 'XData', sx(i,:), 'YData', sy(i,:), 'ZData', sz(i,:))
            set(nsleg, 'XData', nsx(i,:), 'YData', nsy(i,:), 'ZData', nsz(i,:))
            set(proj, 'XData', projx(i,:), 'YData', projy(i,:), 'ZData', [0 0 0 0])
            set(twod, 'XData', xmax*ones(1,4), 'YData', twody(i,:), 'ZData', twodz(i,:))
            drawnow
        end
    else
        set(sleg, 'XData', sx(i,:), 'YData', sy(i,:), 'ZData', sz(i,:))
        set(nsleg, 'XData', nsx(i,:), 'YData', nsy(i,:), 'ZData', nsz(i,:))
        set(proj, 'XData', projx(i,:), 'YData', projy(i,:), 'ZData', [0 0 0 0])
        set(twod, 'XData', xmax*ones(1,4), 'YData', twody(i,:), 'ZData', twodz(i,:))  
        drawnow
    end
end

% status = robotMovie;
% movie(robotMovie)
end