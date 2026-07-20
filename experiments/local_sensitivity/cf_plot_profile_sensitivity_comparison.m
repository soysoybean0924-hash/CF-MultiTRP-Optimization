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
% Build two aligned matrices:
% - trueSensitivity stores the signed S_true_norm value shown in each cell.
% - trueRank stores the absolute-sensitivity rank used for the color class.
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

% The plot uses rank classes instead of a continuous colorbar. That makes
% the visual match the interpretation: red/orange/gray mean high/medium/low
% rank groups, not a continuous numerical threshold.
rankClass = nan(size(trueRank));
rankClass(trueRank >= 1 & trueRank <= 3) = 3;
rankClass(trueRank >= 4 & trueRank <= 6) = 2;
rankClass(trueRank >= 7) = 1;

fig = figure('Visible','off','Color','w','Position',[100 100 900 620]);
imagesc(rankClass,[1 3]);
colormap([0.78 0.78 0.78; 0.95 0.64 0.25; 0.78 0.18 0.16]);
set(gca,'XTick',1:numel(profiles),'XTickLabel',profiles);
set(gca,'YTick',1:numel(parameters),'YTickLabel',parameters);
title('Cross-profile J\_true sensitivity rank class');
xlabel('Profile');
ylabel('Parameter');
hold on;

for pi = 1:numel(profiles)
    for pj = 1:numel(parameters)
        value = trueSensitivity(pj,pi);
        rankValue = trueRank(pj,pi);
        if isfinite(value)
            if rankClass(pj,pi) == 3
                textColor = 'w';
            else
                textColor = 'k';
            end
            text(pi,pj,sprintf('%.3g\n#%d',value,rankValue), ...
                'HorizontalAlignment','center','Color',textColor,'FontSize',9);
        end
    end
end

plotDiscreteLegend();
saveFigure(fig,fullfile(resultRoot,'fig08_profile_true_sensitivity_heatmap'));
end

function plotDiscreteLegend()
legendHandles = gobjects(3,1);
legendHandles(1) = patch(nan,nan,[0.78 0.18 0.16]);
legendHandles(2) = patch(nan,nan,[0.95 0.64 0.25]);
legendHandles(3) = patch(nan,nan,[0.78 0.78 0.78]);
legend(legendHandles,{'High sensitivity rank 1-3','Medium sensitivity rank 4-6','Low sensitivity rank 7-9'}, ...
    'Location','eastoutside');
end

function saveFigure(fig,outBase)
savefig(fig,[outBase '.fig']);
print(fig,[outBase '.png'],'-dpng','-r200');
close(fig);
end
