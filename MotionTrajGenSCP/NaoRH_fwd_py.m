% These are the forward kinematics functions from the NaoRH
function py = NaoRH_fwd_py(thetas)

    shoulderOffsetY = 0.098*10;%98/1000;
    elbowOffsetY = 0.015*10;%15/1000;
    upperArmLength = 0.105*10;%105/1000;
    shoulderOffsetZ = 0.100*10;%;100/1000;
    HandOffsetX = 0.05775*10;%57.75/1000;
    HandOffsetZ = 0.01231*10;%12.31/1000;
    LowerArmLength = 0.05595*10;%55.95/1000;

    y1 = -shoulderOffsetY;
    z1 = shoulderOffsetZ;
    x2 = upperArmLength; 
    y2 = -elbowOffsetY;
    x3 = LowerArmLength;
    x4 = HandOffsetX;
    z4 = -HandOffsetZ;
    
    t1 = thetas(1); t2 = thetas(2); t3 = thetas(3); t4 = thetas(4); %t5 = 0; 

    % How to remove affect of t5: declare everything as syms, then:
    % px = subs(px, t5, 0)
    
    py = (21*sin(t2))/20 + (1137*cos(t4)*sin(t2))/1000 + (1137*cos(t2)*cos(t3)*sin(t4))/1000 - 113/100;
 
    
    %py = y1 + x3*(cos(t4)*sin(t2) + cos(t2)*cos(t3)*sin(t4)) + x4*(cos(t4)*sin(t2) + cos(t2)*cos(t3)*sin(t4)) + y2*cos(t2) + x2*sin(t2) - z4*cos(t2)*sin(t3);
    
    %px = x3*(sin(t4)*(sin(t1)*sin(t3) - cos(t1)*cos(t3)*sin(t2)) + cos(t1)*cos(t2)*cos(t4)) - z4*(sin(t5)*(cos(t4)*(sin(t1)*sin(t3) - cos(t1)*cos(t3)*sin(t2)) - cos(t1)*cos(t2)*sin(t4)) - cos(t5)*(cos(t3)*sin(t1) + cos(t1)*sin(t2)*sin(t3))) + x4*(sin(t4)*(sin(t1)*sin(t3) - cos(t1)*cos(t3)*sin(t2)) + cos(t1)*cos(t2)*cos(t4)) + x2*cos(t1)*cos(t2) - y2*cos(t1)*sin(t2);
    %py = y1 + x3*(cos(t4)*sin(t2) + cos(t2)*cos(t3)*sin(t4)) + x4*(cos(t4)*sin(t2) + cos(t2)*cos(t3)*sin(t4)) + y2*cos(t2) + x2*sin(t2) + z4*(sin(t5)*(sin(t2)*sin(t4) - cos(t2)*cos(t3)*cos(t4)) - cos(t2)*cos(t5)*sin(t3));
    %pz = z1 - z4*(sin(t5)*(cos(t4)*(cos(t1)*sin(t3) + cos(t3)*sin(t1)*sin(t2)) + cos(t2)*sin(t1)*sin(t4)) - cos(t5)*(cos(t1)*cos(t3) - sin(t1)*sin(t2)*sin(t3))) + x3*(sin(t4)*(cos(t1)*sin(t3) + cos(t3)*sin(t1)*sin(t2)) - cos(t2)*cos(t4)*sin(t1)) + x4*(sin(t4)*(cos(t1)*sin(t3) + cos(t3)*sin(t1)*sin(t2)) - cos(t2)*cos(t4)*sin(t1)) - x2*cos(t2)*sin(t1) + y2*sin(t1)*sin(t2);
    
    %rx = atan2(cos(t5)*(cos(t4)*(cos(t1)*sin(t3) + cos(t3)*sin(t1)*sin(t2)) + cos(t2)*sin(t1)*sin(t4)) + sin(t5)*(cos(t1)*cos(t3) - sin(t1)*sin(t2)*sin(t3)),cos(t5)*(cos(t1)*cos(t3) - sin(t1)*sin(t2)*sin(t3)) - sin(t5)*(cos(t4)*(cos(t1)*sin(t3) + cos(t3)*sin(t1)*sin(t2)) + cos(t2)*sin(t1)*sin(t4)));
    %ry = atan2(cos(t2)*cos(t4)*sin(t1) - sin(t4)*(cos(t1)*sin(t3) + cos(t3)*sin(t1)*sin(t2)), ((cos(t5)*(cos(t4)*(cos(t1)*sin(t3) + cos(t3)*sin(t1)*sin(t2)) + cos(t2)*sin(t1)*sin(t4)) + sin(t5)*(cos(t1)*cos(t3) - sin(t1)*sin(t2)*sin(t3)))^2 + (sin(t5)*(cos(t4)*(cos(t1)*sin(t3) + cos(t3)*sin(t1)*sin(t2)) + cos(t2)*sin(t1)*sin(t4)) - cos(t5)*(cos(t1)*cos(t3) - sin(t1)*sin(t2)*sin(t3)))^2)^(1/2));
    %rz = atan2(cos(t4)*sin(t2) + cos(t2)*cos(t3)*sin(t4),sin(t4)*(sin(t1)*sin(t3) - cos(t1)*cos(t3)*sin(t2)) + cos(t1)*cos(t2)*cos(t4));
    
end