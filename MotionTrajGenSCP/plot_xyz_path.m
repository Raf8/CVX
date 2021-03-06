function plot_xyz_path(xyz_linspace, isBig)
    T = size(xyz_linspace,2); 
    for i=1:T
        r = 0.01;
        if (isBig == 1)
            r = 0.3;
        end
        c = xyz_linspace(:,i);
        [x,y,z] = sphere;
        x = r*x + c(1)*ones(size(x));
        y = r*y + c(2)*ones(size(y));
        z = r*z + c(3)*ones(size(z));
        surf(x,y,z);
    end
end