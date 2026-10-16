function outputDir=chasi_export_canonical_parity(outputDir)
%CHASI_EXPORT_CANONICAL_PARITY Replay saved explicit fixture inputs.
% Never writes into the historical fixture directory.
root=fileparts(fileparts(mfilename('fullpath')));
fixture=fullfile(root,'experiments','chasi_formal', ...
    'migration_20261013','native_pf_20261014');
addpath(fullfile(root,'matlab','chasi'));
if nargin<1 || isempty(outputDir)
    outputDir=fullfile(root,'tmp', ...
        ['chasi_canonical_parity_' datestr(now,'yyyymmdd_HHMMSS_FFF')]);
end
if isfolder(outputDir)
    if ~isempty(dir(fullfile(outputDir,'*.mat')))
        error('CHASI:ParityOutputExists','Refusing to overwrite MAT output');
    end
else
    mkdir(outputDir);
end
names={'rank1_nominal','rank2_nominal','rank2_uniform', ...
    'rank2_relative','rank2_statistical'};
for j=1:numel(names)
    input=load(fullfile(fixture,[names{j} '_input.mat']));
    for outer=[0 2]
        cfg=input.cfg;
        cfg.outer_iterations=outer;
        cfg.probe_fixed_uw=(outer==2);
        out=chasi_matrix_wmmse(input.resources,cfg,input.initialV);
        destination=fullfile(outputDir, ...
            sprintf('%s_canonical_outer%d.mat',names{j},outer));
        if isfile(destination)
            error('CHASI:ParityOutputExists','Refusing to overwrite %s',destination);
        end
        save(destination,'out','-v7');
    end
end
fprintf('CHASI_CANONICAL_PARITY_OUTPUT=%s\n',outputDir);
end
