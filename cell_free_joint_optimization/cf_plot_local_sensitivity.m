function cf_plot_local_sensitivity(summary,resultsDir)
%CF_PLOT_LOCAL_SENSITIVITY Save all requested sensitivity figures.

if ~exist(resultsDir,'dir')
    mkdir(resultsDir);
end

three = summary.threeObjectiveTable;
metric = summary.metricChangeTable;
raw = summary.rawTable;
labels = three.Parameter;

makeSignedBar(labels,three.S_inner_norm,'Normalized sensitivity of J_inner', ...
    'S\_inner\_norm',fullfile(resultsDir,'fig01_inner_sensitivity'));
makeSignedBar(labels,three.S_outer_norm,'Normalized sensitivity of J_outer', ...
    'S\_outer\_norm',fullfile(resultsDir,'fig02_outer_sensitivity'));
makeSignedBar(labels,three.S_true_norm,'Normalized sensitivity of J_true', ...
    'S\_true\_norm',fullfile(resultsDir,'fig03_true_sensitivity'));

fig = figure('Visible','off','Color','w');
bar([three.S_inner_norm three.S_outer_norm three.S_true_norm]);
yline(0,'k-');
set(gca,'XTick',1:height(three),'XTickLabel',labels,'XTickLabelRotation',35);
ylabel('Normalized sensitivity');
legend({'inner','outer','true'},'Location','best');
title('Three-objective local sensitivity');
grid on;
saveFigure(fig,fullfile(resultsDir,'fig04_grouped_three_objectives'));

heatFields = {'S_sumRate_norm','S_jain_norm','S_rate5_norm','S_rate10_norm', ...
    'S_activeLinks_norm','S_fronthaul_norm','S_totalPower_norm'};
heatData = zeros(height(metric),numel(heatFields)+3);
heatData(:,1) = three.S_inner_norm;
heatData(:,2) = three.S_outer_norm;
heatData(:,3) = three.S_true_norm;
for k = 1:numel(heatFields)
    heatData(:,k+3) = metric.(heatFields{k});
end
fig = figure('Visible','off','Color','w');
imagesc(heatData);
colormap(redblue(256));
colorbar;
set(gca,'XTick',1:size(heatData,2), ...
    'XTickLabel',{'J_inner','J_outer','J_true','SumRate','Jain','Rate5','Rate10','ActiveLinks','Fronthaul','TotalPower'}, ...
    'XTickLabelRotation',35);
set(gca,'YTick',1:height(three),'YTickLabel',labels);
title('Normalized local sensitivity heatmap');
saveFigure(fig,fullfile(resultsDir,'fig05_sensitivity_heatmap'));

fig = figure('Visible','off','Color','w','Position',[100 100 1200 900]);
for p = 1:height(three)
    subplot(3,3,p);
    plotResponse(raw,p);
    title(labels{p},'Interpreter','none');
end
saveFigure(fig,fullfile(resultsDir,'fig06_local_response_curves'));

[sortedAbs,order] = sort(abs(three.S_true_norm),'descend');
sortedSigned = three.S_true_norm(order);
sortedLabels = labels(order);
cumShare = cumsum(sortedAbs) / max(sum(sortedAbs),eps);
colors = zeros(numel(order),3);
for k = 1:numel(order)
    if cumShare(k) <= 0.70
        colors(k,:) = [0.15 0.45 0.80];
    elseif cumShare(k) <= 0.90
        colors(k,:) = [0.90 0.55 0.15];
    else
        colors(k,:) = [0.45 0.45 0.45];
    end
end
fig = figure('Visible','off','Color','w');
b = bar(sortedSigned,'FaceColor','flat');
b.CData = colors;
yline(0,'k-');
set(gca,'XTick',1:numel(order),'XTickLabel',sortedLabels,'XTickLabelRotation',35);
ylabel('S\_true\_norm');
title('J\_true sensitivity ranking');
grid on;
saveFigure(fig,fullfile(resultsDir,'fig07_true_sensitivity_ranking'));
end

function makeSignedBar(labels,values,titleText,yText,outBase)
fig = figure('Visible','off','Color','w');
bar(values);
yline(0,'k-');
set(gca,'XTick',1:numel(values),'XTickLabel',labels,'XTickLabelRotation',35);
ylabel(yText);
title(titleText);
grid on;
saveFigure(fig,outBase);
end

function plotResponse(raw,p)
idx = raw.ParameterIndex == p;
pointOrders = unique(raw.PointOrder(idx));
pointOrders = sort(pointOrders(:))';
means = zeros(numel(pointOrders),3);
values = zeros(numel(pointOrders),1);
for k = 1:numel(pointOrders)
    q = idx & raw.PointOrder == pointOrders(k);
    values(k) = mean(raw.ParameterValue(q));
    means(k,1) = mean(raw.J_inner(q));
    means(k,2) = mean(raw.J_outer(q));
    means(k,3) = mean(raw.J_true(q));
end
baseIdx = find(pointOrders == 0,1);
if isempty(baseIdx), baseIdx = ceil(numel(pointOrders)/2); end
normMeans = 100 * (means ./ max(abs(means(baseIdx,:)),eps) - 1);
plot(1:numel(pointOrders),normMeans(:,1),'-o','LineWidth',1.1); hold on;
plot(1:numel(pointOrders),normMeans(:,2),'-s','LineWidth',1.1);
plot(1:numel(pointOrders),normMeans(:,3),'-^','LineWidth',1.1);
yline(0,'k-');
grid on;
set(gca,'XTick',1:numel(pointOrders),'XTickLabel',arrayfun(@shortNumber,values,'UniformOutput',false));
xlabel('parameter value');
ylabel('change from baseline (%)');
if p == 1
    legend({'inner','outer','true'},'Location','best');
end
end

function s = shortNumber(x)
if abs(x) >= 100 || abs(x) < 1e-3
    s = sprintf('%.2g',x);
else
    s = sprintf('%.4g',x);
end
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
