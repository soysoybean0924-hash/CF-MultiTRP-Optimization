function [busy,tail,terminal] = chasi_traffic(users,durationTti,seed,mode,busyFractionTarget)
%CHASI_TRAFFIC Reproducible burst/idle trace on a half-open TTI window.
if nargin < 4 || isempty(mode), mode = 'legacy_bursts'; end
if nargin < 5 || isempty(busyFractionTarget), busyFractionTarget = 0.30; end
if ~ismember(string(mode),["legacy_bursts","target_busy_fraction"])
    error('chasi_traffic:Mode','Unknown traffic mode.');
end
if ~(isscalar(busyFractionTarget) && busyFractionTarget > 0 && busyFractionTarget < 1)
    error('chasi_traffic:Load','Busy fraction target must lie in (0,1).');
end
if users < 0 || durationTti < 0 || users ~= fix(users) || durationTti ~= fix(durationTti)
    error('chasi_traffic:Shape','Users and duration must be nonnegative integers.');
end
stream = RandStream('mt19937ar','Seed',seed+303);
busy = false(users,durationTti); tail = busy; terminal = busy;
for globalUeId = 1:users
    t = 0; % Zero-based position, matching the Python half-open window.
    while t < durationTti
        if strcmp(mode,'legacy_bursts')
            gap = randi(stream,5);
        else
            meanGap = 20*(1-busyFractionTarget)/busyFractionTarget;
            gapEndProbability = 1/(meanGap+1);
            gap = floor(log(max(realmin,rand(stream)))/log1p(-gapEndProbability));
        end
        t = t + gap;
        if t >= durationTti, break; end
        lengthTti = randi(stream,[10,30]);
        finish = min(t+lengthTti,durationTti);
        busy(globalUeId,t+1:finish) = true;
        tailStart = t+floor(0.4*(finish-t));
        tail(globalUeId,tailStart+1:finish) = true;
        terminal(globalUeId,finish) = true;
        t = finish;
    end
end
end
