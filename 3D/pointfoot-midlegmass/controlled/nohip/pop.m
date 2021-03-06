
%
% Just an easy way to get those default variables out.

global M Mp g l w slope alpha dim invalidResults c

% xi = [ S NS P Sdot NSdot Pdot ];

% Pointfeet
    invalidResults = 0; 
    M = 5
    Mp = 10
    g = 9.8
    l = 1
    w = 0
    c = 8
    alpha = pi/50
    slope = 0
    
%     Calc the phi IC's using the control law from the 2D walker
%     xi = [-0.28835506235061 0.28835506235061 -1.60086714362546 -1.97621521334708];
    xi = [-0.28840000000000 0.28840000000000 -1.60090000000000 -1.97620000000000];
    s = xi(1); ns = xi(2);
    p0 = -.2;
    pdot = (-8*c*p0)/(l*l*(6*M + 4*Mp) + l*l*(M*cos(2*ns) - 8*M*cos(ns)*cos(s) + (5*M + 4*Mp)*cos(2*s)));
    xi = [p0 xi(1) xi(2) pdot xi(3) xi(4)]

%     xi = [-0.20000000000000 -0.28840000000000   0.28840000000000  0.13926576168206 -1.60090000000000  -1.97620000000000]
%         xi = [p0 -0.28840000000000   0.28840000000000  pdot -1.60090000000000  -1.97620000000000]
    % Above IC comes directly from the 2D walker.
    
    dim = 6
    
    
    