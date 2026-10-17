function result = chasi_burst_metrics(delivered,busy,terminal,ttiMs)
%CHASI_BURST_METRICS One throughput sample per completed simulated burst.
if nargin < 4, ttiMs = 1; end
validate_masks(delivered,busy,terminal);
numUEs = size(busy,1); T = size(busy,2);
rates = []; perUe = cell(numUEs,1); empty = 0; incomplete = 0;
for globalUeId = 1:numUEs
    ueRates = []; bits = 0; count = 0; open = false;
    for t = 1:T
        if busy(globalUeId,t)
            open = true;
            if ~terminal(globalUeId,t)
                bits = bits + delivered(globalUeId,t); count = count + 1;
            end
        end
        if terminal(globalUeId,t)
            if count > 0
                value = bits/(count*ttiMs/1000)/1e6;
                ueRates(end+1) = value; %#ok<AGROW>
                rates(end+1) = value; %#ok<AGROW>
            else
                empty = empty + 1;
            end
            bits = 0; count = 0; open = false;
        end
    end
    if open, incomplete = incomplete + 1; end
    perUe{globalUeId} = ueRates;
end
result = struct('valid_burst_samples',numel(rates), ...
    'bursts_without_valid_tti',empty,'unfinished_bursts_excluded',incomplete, ...
    'bottom5_mbps_across_bursts',linear_percentile(rates,5), ...
    'mean_mbps_across_bursts',mean_or_nan(rates), ...
    'per_ue_burst_mbps',{perUe}, ...
    'scope','one sample per simulated burst, excluding final TTI; not yet official UE-second CDF or packet counter');
end

function validate_masks(delivered,busy,terminal)
if ~ismatrix(delivered) || ~isequal(size(delivered),size(busy),size(terminal))
    error('chasi_burst_metrics:Shape','Matching [UE,TTI] inputs required.');
end
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
