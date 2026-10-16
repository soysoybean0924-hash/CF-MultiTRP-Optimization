function result = chasi_load_precoder_result(path)
%CHASI_LOAD_PRECODER_RESULT Read-only CHASI saved-array schema converter.
% This function is for historical analysis only; chasi_run never calls it.
% Legacy CF result.W is a different model and is deliberately not accepted.
saved=load(path);
if isfield(saved,'resultSchemaVersion') && saved.resultSchemaVersion==3
    required={'precoder','rxCombiner','mseMatrix','mseWeight',...
        'userWeight','scheduleMask','servingMask','ueIds',...
        'resourceWeightNu','numStreams'};
    for j=1:numel(required)
        if ~isfield(saved,required{j})
            error('CHASI:SavedSchema','Missing v3 field %s',required{j});
        end
    end
    result=saved;
elseif isfield(saved,'resultSchemaVersion') && saved.resultSchemaVersion==2
    required={'precoder','rxCombiner','mseMatrix','mseWeight',...
        'userWeight','scheduleMask','servingMask','ueIDs','numStreams'};
    for j=1:numel(required)
        if ~isfield(saved,required{j})
            error('CHASI:SavedSchema','Missing v2 field %s',required{j});
        end
    end
    result=saved;
    result.ueIds=saved.ueIDs;
    result=rmfield(result,'ueIDs');
    result.resourceWeightNu=[]; % v2 did not save this field.
elseif all(isfield(saved,{'precoderV','receiverU','mseMatrixE','mseWeightW'}))
    result=struct('resultSchemaVersion',1,...
        'precoder',{saved.precoderV},'rxCombiner',{saved.receiverU},...
        'mseMatrix',{saved.mseMatrixE},'mseWeight',{saved.mseWeightW});
    if isfield(saved,'serve'), result.servingMask=saved.serve; end
    if isfield(saved,'ueIDs'), result.ueIds=saved.ueIDs; end
    if isfield(saved,'streamRank'), result.numStreams=saved.streamRank; end
    result.scheduleMask=[]; % v1 file alone did not store global schedule.
    result.userWeight=[]; % v1 file alone did not store objective weights.
    result.resourceWeightNu=[]; % v1 file alone did not store this field.
else
    error('CHASI:SavedSchema',...
        'Only CHASI v1/v2/v3 precoder MAT files are supported; old CF result.W is distinct.');
end
end
