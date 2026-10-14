here=fileparts(mfilename('fullpath'));
root=fileparts(fileparts(fileparts(fileparts(here))));
addpath(fullfile(root,'experiments','chasi_formal','migration_20261013'));
names={'rank1_nominal','rank2_nominal','rank2_uniform',...
       'rank2_relative','rank2_statistical'};
for j=1:numel(names)
    input=load(fullfile(here,[names{j} '_input.mat']));
    cfg=input.cfg; cfg.outer_iterations=2; cfg.probe_fixed_uw=true;
    out=chasi_matrix_wmmse(input.resources,cfg,input.initialV);
    fixed_uw_probe=out.fixed_uw_probe;
    destination=fullfile(here,[names{j} '_matlab_operator.mat']);
    if isfile(destination), error('Refusing to overwrite %s',destination); end
    save(destination,'fixed_uw_probe','-v7');
end
