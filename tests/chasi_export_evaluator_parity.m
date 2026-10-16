function outputFile=chasi_export_evaluator_parity(outputFile)
%CHASI_EXPORT_EVALUATOR_PARITY Explicit one-link scene and traffic masks.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'matlab','chasi'));
if nargin<1
    outputFile=fullfile(root,'tmp','chasi_evaluator_parity.mat');
end
cfg=struct('users',2,'durationTti',4,'ttiMs',1,'rbTotal',273,...
    'scsHz',30000,'seed',1,'trafficModel','legacy_bursts','trafficLoad',.3);
h=complex(zeros(1,1,4,64)); h(1,1,1,1)=1;
resource=struct('H_true',h,'ue_ids',1,'servingMask',true,...
    'tx_rb_count',273,'rb_count',273,'omitted_gain',zeros(1,1),...
    'prior_gain',ones(1,1));
scene=struct('config',cfg,'resources',resource,'active_prb_ratio',1);
v=complex(zeros(1,1,64,1)); v(1,1,1,1)=1;
solution=struct('precoder',{{v}});
traffic=struct('busy',logical([1 1 1 0;0 0 0 0]),...
    'tail',logical([0 1 1 0;0 0 0 0]),...
    'terminal',logical([0 0 1 0;0 0 0 0]));
metrics=chasi_evaluate(scene,solution,traffic);
save(outputFile,'metrics','-v7');
fprintf('CHASI_EVALUATOR_PARITY_OUTPUT=%s\n',outputFile);
end
