function test_chasi_native_scene()
% Formal scene contract: full RB partition, sparse schedule and CSI state.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'matlab','chasi'));
cfg = chasi_config(struct('seed',17,'prbUtilization',0.30, ...
    'scheduleMode','precise_shared_rb','decisionTti',0, ...
    'maxInterferenceDistanceM',100));
scene = chasi_generate_scene(cfg);
assert(isequal(size(scene.trp_xy),[21 2]));
assert(isequal(size(scene.ue_xy),[210 2]));
assert(isequal(scene.home(:),repelem((1:21)',10)));
assert(isequal(size(scene.scheduleMask),[210 17]));
assert(numel(scene.resources)==17);
assert(sum([scene.resources.rb_count])==273);
assert(sum([scene.resources.tx_rb_count])==82); % round(0.3*273)
assert(all(abs(scene.active_prb_ratio - 82/273)<1e-12));
assert(numel(scene.events)==341);
assert(scene.events(1).srs_group==1 && scene.events(1).csi_rs);
assert(scene.resources(1).measured && scene.resources(1).age_ms==0);
assert(~scene.resources(2).measured && scene.resources(2).age_ms==-1);
checkedCsiPosterior=false;
for g=1:17
    r=scene.resources(g);
    k=numel(r.ue_ids);
    assert(isequal(size(r.H),[k 21 4 64]));
    assert(isequal(size(r.H_true),[k 21 4 64]));
    assert(isequal(size(r.C),[k 21 4 4]));
    assert(isequal(size(r.servingMask),[21 k]));
    assert(all(r.ue_ids>=1 & r.ue_ids<=cfg.users));
    assert(isequal(find(scene.scheduleMask(:,g)),sort(r.ue_ids(:))));
    assert(isequal(r.home_trp(:),scene.home(r.ue_ids(:))));
    assert(all(sum(r.servingMask,1)>=1 & sum(r.servingMask,1)<=cfg.serviceTrps));
    assert(r.rb_start>=1 && r.rb_start+r.rb_count-1<=273);
    if k>0
        assert(all(scene.home(r.ue_ids)>=1));
        for j=1:k
            assert(r.servingMask(scene.home(r.ue_ids(j)),j));
        end
        modeled=r.omitted_gain==0;
        assert(all(isfinite(r.prior_gain(:)) & r.prior_gain(:)>0));
        assert(all(r.omitted_gain(~modeled)>0));
        assert(all(abs(r.H(repmat(~modeled,1,1,4,64)))==0));
        assert(all(abs(r.H_true(repmat(~modeled,1,1,4,64)))==0));
        [ki,li]=find(modeled,1);
        if ~isempty(ki)
            c=squeeze(r.C(ki,li,:,:));
            assert(norm(c-c','fro')<1e-5);
            assert(min(eig(double(c)))>0);
            assert(norm(squeeze(r.H(ki,li,:,:))-squeeze(r.H_true(ki,li,:,:)),'fro')>0);
            if ~r.measured && ~checkedCsiPosterior
                gain=double(r.prior_gain(ki,li));
                rx=0.35.^abs((1:4)'-(1:4));
                nc=gain/10^(cfg.csiRsSnrDb/10);
                expected=(inv(gain*rx)+eye(4)/nc)\eye(4);
                assert(norm(double(c)-expected,'fro')/norm(expected,'fro')<1e-5);
                checkedCsiPosterior=true;
            end
        end
    end
end
assert(checkedCsiPosterior);
test_pilot_reuse();
fprintf('CHASI_NATIVE_SCENE_PASS\n');
end

function test_pilot_reuse()
cfg=chasi_config(struct('seed',19,'prbUtilization',0.30, ...
    'scheduleMode','precise_shared_rb','srsMode','pilot_reuse_gaussian', ...
    'srsPilotSequences',1,'maxInterferenceDistanceM',100));
scene=chasi_generate_scene(cfg);
assert(isfield(scene.calibration,'status'));
found=false;
for g=1:numel(scene.resources)
    r=scene.resources(g);
    if isempty(r.ue_ids), continue; end
    assert(r.measured);
    if isempty(r.srs_diagnostic), continue; end
    for j=1:numel(r.srs_diagnostic)
        d=r.srs_diagnostic(j);
        if isempty(d.co_pilot_user_count), continue; end
        assert(all(d.co_pilot_user_count==numel(r.ue_ids)-1));
        assert(d.current_past_correlation>0 && d.current_past_correlation<=1);
        assert(all(d.signal_to_interference_plus_awgn_linear<=d.signal_to_awgn_linear+1e-10));
        found=true;
    end
end
assert(found);
end
