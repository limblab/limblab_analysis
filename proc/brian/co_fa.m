function [lambda,w] = co_fa(bdf, varargin)
% [lambda,w] = co_fa(bdf, [tt])

colors = {'k.', 'b.', 'r.', 'g.', 'ko', 'bo', 'ro', 'go'};

if nargin < 2
    tt = co_trial_table(bdf);
else
    tt = varargin{1};
end

% Find all delay bump trials
%dbtrials = tt( tt(:,3) == double('D') & tt(:,10) == double('R'), :);

% Center-Hold Bumps
bumptrials = tt( tt(:,3) == double('H'), : );
[lambda, proj] = fa_single(bdf, bumptrials(:,4), 0.000, 0.150);

figure; hold on;
for bumpdir = 0:3
    f = bumptrials(:,2) == bumpdir;
    plot3(proj(f,1), proj(f,2), proj(f,3), colors{bumpdir+1});
end
title('Bump');


% Un-bumped Reaches
reachtrials = tt( tt(:,3) == -1 & tt(:,10) == double('R'), :);
[lambda, proj] = fa_single(bdf, reachtrials(:,8), 0.000, 0.400);

figure; hold on;
for reachdir = 0:3
    f = reachtrials(:,5) == reachdir;
    plot3(proj(f,1), proj(f,2), proj(f,3), colors{reachdir+1});
end
title('Target');

% Combined
% combtrials = [bumptrials(:,4); reachtrials(:,7)+0.250];
% trialtype = [bumptrials(:,2)+1; reachtrials(:,5)+5];
% 
% [lambda, proj] = fa_single(bdf, combtrials, 0.000, 0.200);
% 
% figure; hold on;
% for curtype = 1:8
%     f = trialtype == curtype;
%     plot3(proj(f,1), proj(f,2), proj(f,3), colors{curtype});
% end
% title('Combined 1');


combtrials = [bumptrials(:,4); reachtrials(:,8)+.050];
trialtype = [bumptrials(:,2)+1; reachtrials(:,5)+5];

[lambda, proj] = fa_single(bdf, combtrials, 0.000, 0.150);

X = []; y = [];

figure; hold on;
for curtype = 1:8
    f = trialtype == curtype;
    plot3(proj(f,1), proj(f,2), proj(f,3), colors{curtype});
    
    X = [X; proj(f,:)];
    y = [y (2*(curtype<5)-1)*ones(1,sum(f))];
end
title('Combined 2');

% non-firing rate effect plot

figure; hold on;
colors = [0 0 0; 1 0 0 ; 0 1 0; 0 0 1];

for curtype = 1:4
    f = trialtype == curtype;
    plot3(mean(proj(f,1)), mean(proj(f,2)), mean(proj(f,3)), 'o', ...
        'MarkerEdgeColor', colors(curtype,:), ...
        'MarkerFaceColor', colors(curtype,:));
end

for curtype = 5:8
f = trialtype == curtype;
    plot3(mean(proj(f,1)), mean(proj(f,2)), mean(proj(f,3)), 'o', ...
        'MarkerEdgeColor', colors(curtype-4,:), ...
        'MarkerFaceColor', 'none');
end

for curtype = 1:4
    f = trialtype == curtype;
    plot3(mean(proj(f,1))/2, mean(proj(f,2))/2, mean(proj(f,3))/2, '^', ...
        'MarkerEdgeColor', colors(curtype,:), ...
        'MarkerFaceColor', colors(curtype,:));
end

for curtype = 5:8
    f = trialtype == curtype;
    plot3(mean(proj(f,1))/2, mean(proj(f,2))/2, mean(proj(f,3))/2, '^', ...
        'MarkerEdgeColor', colors(curtype-4,:), ...
        'MarkerFaceColor', 'none');
end

mylines = {'k-', 'r-', 'g-', 'b-', 'k--', 'r--', 'g--', 'b--'};
for curtype = 1:8
    f = trialtype == curtype;
    plot3(  [0 mean(proj(f,1))], ...
            [0 mean(proj(f,2))], ...
            [0 mean(proj(f,3))], ...
            mylines{curtype});
end

%return;

% n = 3;
% l = length(y);
% H = eye(n+1);
% H(n+1, n+1) = 0;
% f = zeros(n+1,1);
% Z = [X ones(l,1)];
% A = -diag(y)*Z;
% c = -1 * ones(l,1);
% 
% options = optimset('Display', 'off', 'LargeScale', 'off');
% [w,fval,exitflag] = quadprog(H,f,A,c,[],[],[],[],[], options);
% if exitflag ~= 1
%     error('Optimizer did not converge to a solution');
% end
% 
% [x,y] = meshgrid(-10:5:30);
% z = -(x*w(1) + y*w(2)) / w(3);
% plot3(x,y,z,'k-');
% plot3(x',y',z','k-');

% B = w(1:3);
% la = zeros(size(lambda));
% for i = 1:length(lambda)
%     la(i,:) = lambda(i,:)/norm(lambda(i,:));
% end

plot3(10*lambda(:,1), 10*lambda(:,2), 10*lambda(:,3), 'kx')

f = trialtype <= 4;
bumppoints = mean(proj(f,:));
f = trialtype >= 5;
reachpoints = mean(proj(f,:));
paxis = (bumppoints-reachpoints)/norm(bumppoints-reachpoints);

plot3([bumppoints(1) reachpoints(1)], [bumppoints(2) reachpoints(2)], [bumppoints(3) reachpoints(3)], 'k^-');

la = zeros(size(lambda));
for i = 1:length(lambda)
    la(i,:) = lambda(i,:)/norm(lambda(i,:));
end

figure;
hist(la*paxis',-1:.1:1);

w = la*paxis';

