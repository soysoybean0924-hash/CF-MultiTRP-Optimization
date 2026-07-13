function fig=cf_plot_search(searchOutput)
history=searchOutput.History;
fig=figure('Name',['Search - ' searchOutput.Method],'NumberTitle','off');
plot(history.Evaluation,history.Score,'o-','LineWidth',1); hold on;
plot(history.Evaluation,history.BestScore,'LineWidth',2); grid on;
xlabel('Candidate evaluation'); ylabel('Score');
legend('Current candidate','Best so far','Location','best');
title(sprintf('%s search, best Score = %.4f',searchOutput.Method,searchOutput.BestScore));
end
