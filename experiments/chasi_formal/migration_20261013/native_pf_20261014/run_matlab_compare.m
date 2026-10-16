% Consume only the explicit inputs saved by prepare_compare.py.
here=fileparts(mfilename('fullpath'));
root=fileparts(fileparts(fileparts(fileparts(here))));
addpath(fullfile(root,'matlab','chasi'));
names={'rank1_nominal','rank2_nominal','rank2_uniform',...
       'rank2_relative','rank2_statistical'};
for j=1:numel(names)
    input=load(fullfile(here,[names{j} '_input.mat']));
    for outer=[0 2]
        cfg=input.cfg; cfg.outer_iterations=outer;
        out=chasi_matrix_wmmse(input.resources,cfg,input.initialV);
        destination=fullfile(here,sprintf('%s_matlab_outer%d.mat',names{j},outer));
        if isfile(destination), error('Refusing to overwrite %s',destination); end
        save(destination,'out','-v7');
        fprintf('%s outer %d objective %.12g power %.12g\n',...
            names{j},outer,out.optimization_objective,max(out.power));
    end
end
