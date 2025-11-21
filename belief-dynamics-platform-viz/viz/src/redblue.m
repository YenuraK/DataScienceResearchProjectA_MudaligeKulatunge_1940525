function cmap = redblue()
%REDBLUE  Blue-grey-red colormap for [-1,1] beliefs visualization.
%
% Output:  colormap (128×3 matrix)

b = [0.10 0.20 0.75];
m = [0.85 0.85 0.85];
r = [0.85 0.10 0.10];
cmap = [linspace(b(1),m(1),64)', linspace(b(2),m(2),64)', linspace(b(3),m(3),64)';
        linspace(m(1),r(1),64)', linspace(m(2),r(2),64)', linspace(m(3),r(3),64)'];
end
