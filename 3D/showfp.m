


pts = size(XFix);
steps = 10;
for i=1:pts(1)
    slope = XFix(i, 1);
    fp = XFix(i, 2:end);
    walk3(fp, steps, 1)
    pause
    close all
end
    