function fig=cf_plot_search(searchOutput)
history=searchOutput.History;
fig=figure('Name',['Search - ' searchOutput.Method],'NumberTitle','off');
if ismember('Objective',history.Properties.VariableNames)
    current = history.Objective;
    best = history.BestObjective;
else
    current = history.Score;
    best = history.BestScore;
end
plot(history.Evaluation,current,'o-','LineWidth',1); hold on;
plot(history.Evaluation,best,'LineWidth',2); grid on;
xlabel('Candidate evaluation'); ylabel('Objective J\_true');
legend('Current candidate','Best so far','Location','best');
title(sprintf('%s search, best objective = %.4f',searchOutput.Method,searchOutput.BestScore));
end
