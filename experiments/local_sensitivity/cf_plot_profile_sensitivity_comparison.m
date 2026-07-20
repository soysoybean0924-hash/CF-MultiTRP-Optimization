function cf_plot_profile_sensitivity_comparison(comparisonTable,resultRoot)
%CF_PLOT_PROFILE_SENSITIVITY_COMPARISON Plot cross-profile sensitivity.

if ischar(comparisonTable) || isstring(comparisonTable)
    comparisonTable = readtable(comparisonTable);
end
if ~exist(resultRoot,'dir')
    mkdir(resultRoot);
end

profiles = {'quick','standard','paper'};
parameters = comparisonTable.Parameter(strcmp(comparisonTable.Profile,profiles{1}));
if isempty(parameters)
    parameters = unique(comparisonTable.Parameter,'stable');
end

trueSensitivity = nan(numel(parameters),numel(profiles));
trueRank = nan(numel(parameters),numel(profiles));
for pi = 1:numel(profiles)
    for pj = 1:numel(parameters)
        idx = strcmp(comparisonTable.Profile,profiles{pi}) & ...
            strcmp(comparisonTable.Parameter,parameters{pj});
        if any(idx)
            trueSensitivity(pj,pi) = comparisonTable.S_true_norm(find(idx,1));
            trueRank(pj,pi) = comparisonTable.TrueRank(find(idx,1));
        end
    end
end

fig = figure('Visible','off','Color','w','Position',[100 100 900 620]);
imagesc(trueSensitivity);
colormap(redblue(256));
colorbar;
cmax = max(abs(trueSensitivity(:)));
if isfinite(cmax) && cmax > 0
    caxis([-cmax cmax]);
end
set(gca,'XTick',1:numel(profiles),'XTickLabel',profiles);
set(gca,'YTick',1:numel(parameters),'YTickLabel',parameters);
title('Cross-profile J\_true normalized sensitivity');
xlabel('Profile');
ylabel('Parameter');

for pi = 1:numel(profiles)
    for pj = 1:numel(parameters)
        value = trueSensitivity(pj,pi);
        rankValue = trueRank(pj,pi);
        if isfinite(value)
            if abs(value) > 0.55*cmax
                textColor = 'w';
            else
                textColor = 'k';
            end
            text(pi,pj,sprintf('%.3g\n#%d',value,rankValue), ...
                'HorizontalAlignment','center','Color',textColor,'FontSize',9);
        end
    end
end

saveFigure(fig,fullfile(resultRoot,'fig08_profile_true_sensitivity_heatmap'));
end

function saveFigure(fig,outBase)
savefig(fig,[outBase '.fig']);
print(fig,[outBase '.png'],'-dpng','-r200');
close(fig);
end

function cmap = redblue(n)
if nargin < 1, n = 256; end
bottom = [0.10 0.25 0.70];
middle = [1.00 1.00 1.00];
top = [0.75 0.10 0.10];
x = linspace(0,1,n)';
cmap = zeros(n,3);
for i = 1:n
    if x(i) < 0.5
        a = x(i)/0.5;
        cmap(i,:) = (1-a)*bottom + a*middle;
    else
        a = (x(i)-0.5)/0.5;
        cmap(i,:) = (1-a)*middle + a*top;
    end
end
end
