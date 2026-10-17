function chasi_export_business_probe(runDir,outputPath)
%CHASI_EXPORT_BUSINESS_PROBE Export saved traffic masks for offline parity.
% Read-only with respect to the formal run; no regenerated random traffic.
if nargin<2 || isempty(outputPath) || isfile(outputPath)
    error('CHASI:BusinessProbeOutput','A new separate output MAT path is required');
end
saved=load(fullfile(runDir,'scene.mat'),'traffic');
busy=saved.traffic.busy;
tail=saved.traffic.tail;
terminal=saved.traffic.terminal;
save(outputPath,'busy','tail','terminal','-v7');
fprintf('CHASI_BUSINESS_PROBE=%s\n',outputPath);
end
