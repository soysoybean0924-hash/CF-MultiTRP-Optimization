function [Jtrue,details] = cf_compute_true_objective(result)
%CF_COMPUTE_TRUE_OBJECTIVE Compute the research objective from b and SLINR.
%
% Mathematical definition used in this experiment:
%
%   J_true = sum_{u,g,s} I(any_r b(r,u,g)=1) * f(SLINR(s,u,g),t_{u,g,s})
%
% with f(SLINR,t)=t*log2(1+SLINR) and t=1 because the current project has
% no independent traffic-weight field t_k. The implementation intentionally
% reads result.b and result.SLINR directly instead of reusing result.Score.

b = result.b;
sinr = result.SLINR;
rankUG = result.r;

[~,U,G] = size(b);
Smax = size(sinr,1);

scheduledUG = false(U,G);
utility = zeros(Smax,U,G);
Jtrue = 0;

for u = 1:U
    for g = 1:G
        scheduledUG(u,g) = any(b(:,u,g) > 0);
        for s = 1:min(rankUG(u,g),Smax)
            if scheduledUG(u,g)
                utility(s,u,g) = log2(1 + max(sinr(s,u,g),0));
                Jtrue = Jtrue + utility(s,u,g);
            end
        end
    end
end

details = struct();
details.definition = 'sum I(any_r b(r,u,g)=1)*log2(1+SLINR(s,u,g)) over scheduled UE/RBG streams';
details.utilityName = 'scheduled-log2-rate';
details.trafficWeight = 1;
details.scheduledUG = scheduledUG;
details.utility = utility;
details.numScheduledUE = sum(any(scheduledUG,2));
details.valueMatchesSumRate = abs(Jtrue - result.SumRate) <= 1e-8*max(1,abs(result.SumRate));
end
