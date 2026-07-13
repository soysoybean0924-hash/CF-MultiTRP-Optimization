function comparisonTable=cf_print_result(result,label)
if nargin<2, label='Cell-Free result'; end
metric={'SumRate';'MeanRate';'MinRate';'Rate5';'Rate10';'Jain';'ActiveLinks';'TotalPower';'ActiveStreams'};
baseline=[result.baseline.SumRate;result.baseline.MeanRate;result.baseline.MinRate; ...
    result.baseline.Rate5;result.baseline.Rate10;result.baseline.Jain; ...
    result.baseline.ActiveLinks;result.baseline.TotalPower;sum(result.baseline.r(:))];
proposed=[result.SumRate;result.MeanRate;result.MinRate;result.Rate5;result.Rate10; ...
    result.Jain;result.ActiveLinks;result.TotalPower;result.ActiveStreams];
change=proposed-baseline; changePercent=100*change./(abs(baseline)+eps);
comparisonTable=table(metric,baseline,proposed,change,changePercent, ...
    'VariableNames',{'Metric','Baseline','Proposed','Change','ChangePercent'});
fprintf('\n================ %s ================\n',label);
fprintf('Score = %.6f\n',result.Score); disp(result.Candidate); disp(comparisonTable);
end
