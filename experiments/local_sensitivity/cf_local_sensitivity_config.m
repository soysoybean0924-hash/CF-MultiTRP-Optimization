function [specs,parameterSettings] = cf_local_sensitivity_config(cfg,candidate)
%CF_LOCAL_SENSITIVITY_CONFIG Define the nine tested parameters.
% Theoretical names follow the research request. Actual fields follow the
% current MATLAB implementation.

specs = repmat(emptySpec(),0,1);

% Each spec records two names:
% - TheoreticalName: the name used in reports and discussion.
% - ActualField: the concrete cfg/candidate field changed by the code.
% This separation keeps the experiment readable while preserving the
% implementation's current data structures.
specs(end+1) = makeSpec(1,'betaPF','candidate.betaPF','candidate','betaPF', ...
    'continuous','continuous-linear',candidate.betaPF,cfg.search.betaPFRange,[],0.10,false, ...
    'PF exponent in the inner WPS weight update.');

specs(end+1) = makeSpec(2,'numUEConnections','candidate.numConnections','candidate','numConnections', ...
    'integer','integer',candidate.numConnections,cfg.search.numConnectionsRange,[],1,false, ...
    'Number of candidate DUs/TRPs serving each UE/RBG.');

specs(end+1) = makeSpec(3,'scheduleThreshold','candidate.scheduleThreshold','candidate','scheduleThreshold', ...
    'continuous','continuous-log',candidate.scheduleThreshold,cfg.search.scheduleThresholdRange,[],0.10,false, ...
    'Power threshold used to convert p into active binary b.');

specs(end+1) = makeSpec(4,'duHeight','cfg.duHeight','cfg','duHeight', ...
    'continuous','continuous-linear',cfg.duHeight,[5 60],[],0.10,true, ...
    'DU/TRP antenna height; regenerates geometry-dependent pathloss.');

specs(end+1) = makeSpec(5,'numTransmitAntennas','cfg.numTxAntennas','cfg','numTxAntennas', ...
    'integer','integer-set',cfg.numTxAntennas,[2 16],[2 4 8 16],1,true, ...
    'Number of transmit antennas per DU; changes H and W dimensions.');

specs(end+1) = makeSpec(6,'rhoFronthaul','candidate.rhoLink','candidate','rhoLink', ...
    'continuous','continuous-log',candidate.rhoLink,cfg.search.rhoLinkRange,[],0.10,false, ...
    'Existing link sparsity penalty; used here as fronthaul proxy penalty.');

specs(end+1) = makeSpec(7,'rhoPower','candidate.rhoPower','candidate','rhoPower', ...
    'continuous','continuous-log',candidate.rhoPower,cfg.search.rhoPowerRange,[],0.10,false, ...
    'Power penalty in beam update and objective accounting.');

specs(end+1) = makeSpec(8,'rankThreshold','candidate.rankThreshold','candidate','rankThreshold', ...
    'continuous','continuous-linear',candidate.rankThreshold,cfg.search.rankThresholdRange,[],0.10,false, ...
    'SVD threshold for selecting one or two streams.');

specs(end+1) = makeSpec(9,'repairWeight','candidate.repairPower','candidate','repairPower', ...
    'continuous','continuous-linear',candidate.repairPower,cfg.search.repairPowerRange,[],0.10,false, ...
    'Existing weak-user repair power; closest code field to repairWeight.');

for k = 1:numel(specs)
    % cf_perturb_parameter converts each parameter definition into
    % minus/base/plus test points. Continuous log-scale fields are perturbed
    % multiplicatively; integer fields use legal neighboring values.
    [values,labels,method,note] = cf_perturb_parameter(specs(k),specs(k).BaseValue);
    specs(k).Values = values;
    specs(k).PointLabels = labels;
    specs(k).MinusValue = values(1);
    specs(k).PlusValue = values(end);
    specs(k).PerturbMethod = method;
    specs(k).PerturbNote = note;
end

% parameterSettings is a compact audit table written to CSV/XLSX so the
% numerical results can always be traced back to the exact perturbation
% points used in the experiment.
rows = repmat(struct(),numel(specs),1);
for k = 1:numel(specs)
    rows(k).ParameterIndex = specs(k).Index;
    rows(k).TheoreticalName = specs(k).TheoreticalName;
    rows(k).ActualField = specs(k).ActualField;
    rows(k).DataType = specs(k).DataType;
    rows(k).Baseline = specs(k).BaseValue;
    rows(k).Minus = specs(k).MinusValue;
    rows(k).Plus = specs(k).PlusValue;
    rows(k).MinAllowed = specs(k).Range(1);
    rows(k).MaxAllowed = specs(k).Range(2);
    rows(k).PerturbRatio = specs(k).PerturbRatio;
    rows(k).PerturbMethod = specs(k).PerturbMethod;
    rows(k).AffectsScenario = specs(k).AffectsScenario;
    rows(k).Notes = specs(k).Notes;
    rows(k).PerturbNote = specs(k).PerturbNote;
end
parameterSettings = struct2table(rows);
end

function spec = emptySpec()
spec = struct('Index',[],'TheoreticalName','','ActualField','','Target','', ...
    'Field','','DataType','','Type','','BaseValue',[],'Range',[], ...
    'AllowedValues',[],'PerturbRatio',[],'AffectsScenario',false, ...
    'Notes','','Values',[],'PointLabels',{{}},'MinusValue',[], ...
    'PlusValue',[],'PerturbMethod','','PerturbNote','');
end

function spec = makeSpec(index,theory,actual,target,field,dataType,type,baseValue,range,allowed,ratio,affectsScenario,notes)
spec = emptySpec();
spec.Index = index;
spec.TheoreticalName = theory;
spec.ActualField = actual;
spec.Target = target;
spec.Field = field;
spec.DataType = dataType;
spec.Type = type;
spec.BaseValue = baseValue;
spec.Range = range;
spec.AllowedValues = allowed;
spec.PerturbRatio = ratio;
spec.AffectsScenario = affectsScenario;
spec.Notes = notes;
end
