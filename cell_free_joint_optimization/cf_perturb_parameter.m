function [values,labels,method,note] = cf_perturb_parameter(spec,baseValue)
%CF_PERTURB_PARAMETER Build legal minus/base/plus perturbations.
% Continuous-linear uses a range-relative central step. Continuous-log uses
% a central step in log10 space. Integer parameters use adjacent legal values.

labels = {'minus','base','plus'};
note = '';

switch spec.Type
    case 'continuous-linear'
        lo = spec.Range(1);
        hi = spec.Range(2);
        delta = spec.PerturbRatio * (hi - lo);
        minusValue = max(lo,baseValue - delta);
        plusValue = min(hi,baseValue + delta);
        if minusValue == baseValue && plusValue < hi
            plusValue = min(hi,baseValue + 2*delta);
            note = 'Baseline near lower boundary; used one-sided extension.';
        elseif plusValue == baseValue && minusValue > lo
            minusValue = max(lo,baseValue - 2*delta);
            note = 'Baseline near upper boundary; used one-sided extension.';
        end
        values = [minusValue baseValue plusValue];
        method = sprintf('central linear step %.4g (%.1f%% of range)',delta,100*spec.PerturbRatio);

    case 'continuous-log'
        lo = spec.Range(1);
        hi = spec.Range(2);
        logLo = log10(lo);
        logHi = log10(hi);
        logBase = log10(baseValue);
        logDelta = spec.PerturbRatio * (logHi - logLo);
        minusValue = 10^max(logLo,logBase - logDelta);
        plusValue = 10^min(logHi,logBase + logDelta);
        values = [minusValue baseValue plusValue];
        method = sprintf('central log10 step %.4g decades',logDelta);

    case 'integer'
        lo = ceil(spec.Range(1));
        hi = floor(spec.Range(2));
        baseInt = round(baseValue);
        minusValue = max(lo,baseInt - 1);
        plusValue = min(hi,baseInt + 1);
        values = [minusValue baseInt plusValue];
        method = 'adjacent integer values';
        if minusValue == baseInt || plusValue == baseInt
            note = 'Integer baseline touches a boundary; one side is clipped.';
        end

    case 'integer-set'
        allowed = unique(round(spec.AllowedValues(:)'));
        [~,idx] = min(abs(allowed - baseValue));
        minusValue = allowed(max(1,idx-1));
        plusValue = allowed(min(numel(allowed),idx+1));
        values = [minusValue allowed(idx) plusValue];
        method = sprintf('adjacent set values from %s',mat2str(allowed));
        if minusValue == allowed(idx) || plusValue == allowed(idx)
            note = 'Set baseline touches a boundary; one side is clipped.';
        end

    otherwise
        error('Unknown perturbation type: %s',spec.Type);
end

if isempty(note)
    note = 'Central local perturbation used.';
end
end
