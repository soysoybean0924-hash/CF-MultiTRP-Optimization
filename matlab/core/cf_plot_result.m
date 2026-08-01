function fig=cf_plot_result(result,figureName)
%CF_PLOT_RESULT Plot b/r as discrete integer resources and p as continuous.
if nargin<2, figureName='Cell-Free b/p/r/W result'; end
fig=figure('Name',figureName,'NumberTitle','off','Units','normalized', ...
    'Position',[0.06 0.08 0.88 0.82]);
layout=tiledlayout(fig,2,3,'TileSpacing','compact','Padding','compact');

ax=nexttile(layout);
scatter3(ax,result.scenario.duPosition(:,1),result.scenario.duPosition(:,2), ...
    result.scenario.duPosition(:,3),80,'filled'); hold(ax,'on');
scatter3(ax,result.scenario.uePosition(:,1),result.scenario.uePosition(:,2), ...
    result.scenario.uePosition(:,3),45,'x','LineWidth',1.5);
grid(ax,'on'); xlabel(ax,'x / m'); ylabel(ax,'y / m'); zlabel(ax,'height / m');
legend(ax,'DU/TRP','UE','Location','best'); title(ax,'Network topology');

ax=nexttile(layout);
bar(ax,[result.baseline.userRate,result.userRate]); grid(ax,'on');
xlabel(ax,'UE'); ylabel(ax,'Rate');
legend(ax,'MRT baseline','Optimized','Location','best'); title(ax,'Per-UE total rate');

% bCount can only be 0,1,...,numRBGs. It must not use a continuous gradient.
ax=nexttile(layout); bCount=round(sum(result.b,3));
plotDiscreteIntegerHeatmap(ax,bCount,0:size(result.b,3), ...
    'b: active RBG count (integer)','UE','DU/TRP');

% p is a continuous power variable: values such as 0.5 are physically valid.
ax=nexttile(layout); pSum=sum(result.p,3);
plotContinuousHeatmap(ax,pSum,'p: continuous power summed over RBGs','UE','DU/TRP');

% r can only be integer streams, currently 1 or 2.
ax=nexttile(layout); rankValues=1:max(1,max(result.r(:)));
plotDiscreteIntegerHeatmap(ax,round(result.r),rankValues, ...
    'r: streams per UE/RBG (integer)','RBG','UE');

ax=nexttile(layout);
if ~isempty(result.history.objective)
    yyaxis(ax,'left'); plot(ax,result.history.objective,'o-','LineWidth',1.5);
    ylabel(ax,'Inner objective'); yyaxis(ax,'right');
    plot(ax,result.history.Jain,'s-','LineWidth',1.5); ylabel(ax,'Jain index');
    xlabel(ax,'Inner iteration'); grid(ax,'on'); title(ax,'WPS/beam iteration');
else
    [baseRate,baseCDF]=experienceCDF(result.baseline);
    [finalRate,finalCDF]=experienceCDF(result);
    plot(ax,baseRate,baseCDF,'--','LineWidth',1.5); hold(ax,'on');
    plot(ax,finalRate,finalCDF,'LineWidth',1.5); grid(ax,'on');
    xlabel(ax,'UE experience rate'); ylabel(ax,'CDF');
    legend(ax,'Baseline','Result','Location','best'); title(ax,'Experience-rate CDF');
end
title(layout,sprintf('%s | Objective %.3f',figureName,result.Score));
end

function plotDiscreteIntegerHeatmap(ax,data,allowedValues,plotTitle,xLabelText,yLabelText)
% One color per integer state; colorbar contains integer ticks only.
data=round(data); allowedValues=unique(round(allowedValues(:)'));
if isempty(allowedValues), allowedValues=0; end
imagesc(ax,data); colormap(ax,parula(max(1,numel(allowedValues))));
clim(ax,[allowedValues(1)-0.5,allowedValues(end)+0.5]);
cb=colorbar(ax); cb.Ticks=allowedValues; cb.TickLabels=compose('%d',allowedValues);
axis(ax,'tight'); set(ax,'YDir','normal','TickLength',[0 0]);
xticks(ax,1:size(data,2)); yticks(ax,1:size(data,1)); grid(ax,'off');
xlabel(ax,xLabelText); ylabel(ax,yLabelText); title(ax,plotTitle);
if numel(data)<=200
    for row=1:size(data,1)
        for column=1:size(data,2)
            text(ax,column,row,sprintf('%d',data(row,column)), ...
                'HorizontalAlignment','center','VerticalAlignment','middle', ...
                'Color',contrastTextColor(data(row,column),allowedValues), ...
                'FontWeight','bold','FontSize',8);
        end
    end
end
drawCellBoundaries(ax,size(data,1),size(data,2));
end

function plotContinuousHeatmap(ax,data,plotTitle,xLabelText,yLabelText)
% Power is continuous, but its matrix cells still need edge-aligned borders.
imagesc(ax,data); colorbar(ax);
axis(ax,'tight'); set(ax,'YDir','normal','TickLength',[0 0]);
xticks(ax,1:size(data,2)); yticks(ax,1:size(data,1)); grid(ax,'off');
xlabel(ax,xLabelText); ylabel(ax,yLabelText); title(ax,plotTitle);
drawCellBoundaries(ax,size(data,1),size(data,2));
end

function drawCellBoundaries(ax,rowCount,columnCount)
% Draw at half-integer edges. Integer ticks remain at cell centers.
wasHeld=ishold(ax); hold(ax,'on');
innerColor=[0.72 0.72 0.72];
for x=1.5:1:(columnCount-0.5)
    plot(ax,[x x],[0.5 rowCount+0.5],'-','Color',innerColor,'LineWidth',0.9);
end
for y=1.5:1:(rowCount-0.5)
    plot(ax,[0.5 columnCount+0.5],[y y],'-','Color',innerColor,'LineWidth',0.9);
end
rectangle(ax,'Position',[0.5 0.5 columnCount rowCount], ...
    'EdgeColor',[0.25 0.25 0.25],'LineWidth',1.4);
if ~wasHeld, hold(ax,'off'); end
end

function color=contrastTextColor(value,allowedValues)
if numel(allowedValues)<=1, normalized=0;
else, normalized=(value-allowedValues(1))/(allowedValues(end)-allowedValues(1)); end
if normalized>0.55, color=[1 1 1]; else, color=[0 0 0]; end
end

function [sortedData,cdfValue]=empiricalCDF(data)
sortedData=sort(data(:)); cdfValue=(1:numel(sortedData))'/numel(sortedData);
end

function [sortedData,cdfValue]=experienceCDF(resultPart)
if isfield(resultPart,'ExperienceRate')
    sortedData=resultPart.ExperienceRate.CdfRate;
    cdfValue=resultPart.ExperienceRate.CdfProbability;
else
    [sortedData,cdfValue]=empiricalCDF(resultPart.userRate);
end
end
