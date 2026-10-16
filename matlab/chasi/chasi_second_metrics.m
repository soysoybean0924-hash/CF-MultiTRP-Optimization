function result = chasi_second_metrics(delivered,busy,terminal,ttiMs)
%CHASI_SECOND_METRICS Full-second burst-filtered simulated capacity samples.
if nargin < 4, ttiMs = 1; end
if ~ismatrix(delivered) || ~isequal(size(delivered),size(busy),size(terminal))
    error('chasi_second_metrics:Shape','Expected matching [UE,TTI] arrays.');
end
perSecond = 1000/ttiMs;
if ttiMs <= 0 || abs(perSecond-round(perSecond)) > 1e-9
    error('chasi_second_metrics:Time','One second must contain integer TTIs.');
end
perSecond = round(perSecond);
[numUEs,T] = size(busy); complete = floor(T/perSecond);
samples = nan(numUEs,complete); counts = zeros(numUEs,complete);
eligible = busy & ~terminal;
for s = 1:complete
    ix = (s-1)*perSecond+(1:perSecond);
    counts(:,s) = sum(eligible(:,ix),2);
    bits = sum(delivered(:,ix).*eligible(:,ix),2);
    good = counts(:,s)>0;
    samples(good,s) = bits(good)./(counts(good,s)*ttiMs/1000)/1e6;
end
values = samples(isfinite(samples));
result = struct('complete_seconds',complete, ...
    'discarded_partial_window_tti',T-complete*perSecond, ...
    'potential_ue_second_samples',numUEs*complete, ...
    'valid_ue_second_samples',numel(values), ...
    'ue_second_samples_without_valid_tti',numUEs*complete-numel(values), ...
    'excluded_buffer_empty_tti',nnz(~busy(:,1:complete*perSecond)), ...
    'excluded_burst_terminal_tti',nnz(terminal(:,1:complete*perSecond)), ...
    'valid_tti_total',sum(counts(:)), ...
    'bottom5_mbps_valid_ue_seconds',linear_percentile(values,5), ...
    'mean_mbps_valid_ue_seconds',mean_or_nan(values), ...
    'per_ue_second_mbps',samples, ...
    'per_ue_second_valid_tti',counts, ...
    'scope','full-second burst-filtered simulator throughput proxy; no BLER/MCS/official counter agreement');
end

function value = mean_or_nan(x)
if isempty(x), value = NaN; else, value = mean(x); end
end

function value = linear_percentile(x,p)
if isempty(x), value = NaN; return; end
x = sort(x(:)); pos = 1+(numel(x)-1)*p/100;
lo = floor(pos); hi = ceil(pos);
value = x(lo)+(pos-lo)*(x(hi)-x(lo));
end
