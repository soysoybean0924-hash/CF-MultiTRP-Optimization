"""Blockwise mobile channel, pilot events, fast beams and burst throughput.

This is an RX-correlated Gauss-Markov fading subset, not TR 38.901 7.5.
The optimizer sees posterior means/covariances only. True H creates pilots
and independently scores decisions after each block's beams are frozen.
"""
from time import perf_counter
import numpy as np
from scipy.special import j0
from .solver import rates,power_by_trp,_project,RX,_weight
from .evaluate import traffic_samples
from .second_metrics import second_level_samples
from .burst_metrics import burst_samples
from .protocol_contract import completed_burst_ue_second_candidates, acceptance_contract


def _posterior(mean,cov,truth,rows,noise_var,rng):
    """Matrix LMMSE update for independent TX columns and RX covariance."""
    rows=np.asarray(rows,int)
    s=cov[np.ix_(rows,rows)]+noise_var*np.eye(len(rows))
    gain=np.linalg.solve(s,cov[:,rows].conj().T).conj().T
    noise=(rng.standard_normal((len(rows),mean.shape[1]))+
           1j*rng.standard_normal((len(rows),mean.shape[1])))*np.sqrt(noise_var/2)
    updated=mean+gain@(truth[rows]+noise-mean[rows])
    posterior=cov-gain@cov[rows]
    return updated,(posterior+posterior.conj().T)/2


def _fast_estimated_svd(resources,est,old_v,budget):
    """Refresh directions from allowed CSI, retaining WMMSE link power."""
    new=[]
    for r,h,v in zip(resources,est,old_v):
        vv=np.zeros_like(v)
        for l,k in zip(*np.nonzero(r.serve)):
            p=np.vdot(v[l,k],v[l,k]).real
            if p<=0:continue
            _,_,vh=np.linalg.svd(h[k,l],full_matrices=False)
            d=v.shape[-1]
            vv[l,k]=np.sqrt(p/d)*vh.conj().T[:,:d]
        new.append(vv)
    return _project(resources,new,budget,[r.serve for r in resources])


def simulate(scene,solution,window_tti=1000,offered_mbps=5.0,
             fast_period_tti=40,slow_period_tti=340,beam_policy='estimated_svd',
             traffic_seed=None):
    cfg=scene.config
    hop_tti=cfg.srs_period_tti//cfg.srs_hops
    if window_tti<cfg.srs_period_tti or window_tti%hop_tti:
        raise ValueError('window_tti must cover one SRS period and align to hop interval')
    if offered_mbps<=0:
        raise ValueError('offered_mbps must be positive')
    if fast_period_tti<=0 or slow_period_tti<=0 or fast_period_tti%hop_tti or slow_period_tti%hop_tti:
        raise ValueError('update periods must align to SRS hopping blocks')
    if beam_policy not in ('frozen','estimated_svd'):
        raise ValueError('unknown beam_policy')
    if traffic_seed is None:
        traffic_seed=cfg.seed
    start=perf_counter()
    rng=np.random.default_rng(cfg.seed+90817)
    resources=scene.resources
    truth=[np.asarray(r.h_true,dtype=np.complex64).copy() for r in resources]
    est=[np.asarray(r.h_est,dtype=np.complex64).copy() for r in resources]
    cov=[np.asarray(r.error_var,dtype=np.complex64).copy() for r in resources]
    gain=[np.asarray(r.prior_gain,dtype=np.float64).copy() for r in resources]
    v=[x.copy() for x in solution.precoders]
    ue_xy=scene.ue_xy.copy()
    headings=rng.uniform(0,2*np.pi,cfg.users)
    velocity=(cfg.speed_kmh/3.6)*np.stack((np.cos(headings),np.sin(headings)),axis=1)
    duration_seconds=window_tti*cfg.tti_ms/1000
    traffic_scene=type('TrafficScene',(),{'config':type('TrafficConfig',(),
                         {'users':cfg.users,'duration_tti':window_tti,'seed':traffic_seed,
                          'traffic_model':cfg.traffic_model,'traffic_load':cfg.traffic_load})()})()
    busy,tail,terminal=traffic_samples(traffic_scene)
    valid=(busy&~terminal).sum(axis=1)
    served_tti=np.zeros(cfg.users,int)
    allocated_rb_tti=np.zeros(cfg.users,float)
    volume=np.zeros(cfg.users,float)
    delivered_tti=np.zeros((cfg.users,window_tti),float)
    completed_tti=np.zeros((cfg.users,window_tti),bool)
    offered=np.zeros(cfg.users,float)
    queue=np.zeros(cfg.users,float)
    complete=np.zeros(cfg.users,int)
    bursts=terminal.sum(axis=1)
    occupied_rb_tti=0.0
    physical_sum=0.0
    events=[]
    f_d=(cfg.speed_kmh/3.6)*cfg.frequency_ghz*1e9/299792458.0
    alpha=float(j0(2*np.pi*f_d*hop_tti*cfg.tti_ms/1000))
    chol=np.linalg.cholesky(RX)
    link_masks=[np.any(abs(x)>0,axis=(2,3)) for x in truth]
    max_violation=0.0
    for t in range(0,window_tti,hop_tti):
        if t:
            old_xy=ue_xy.copy()
            ue_xy+=velocity*(hop_tti*cfg.tti_ms/1000)
            for gi,r in enumerate(resources):
                if not len(r.users):continue
                for ki,u in enumerate(r.users):
                    for l in np.flatnonzero(link_masks[gi][ki]):
                        old_d=max(np.linalg.norm(old_xy[u]-scene.trp_xy[l]),10.)
                        new_d=max(np.linalg.norm(ue_xy[u]-scene.trp_xy[l]),10.)
                        new_gain=gain[gi][ki,l]*(old_d/new_d)**3.2
                        drift=np.sqrt(new_gain/max(gain[gi][ki,l],1e-30))
                        z=(rng.standard_normal((4,64))+1j*rng.standard_normal((4,64)))/np.sqrt(2)
                        innovation=np.sqrt(new_gain)*(chol@z)
                        truth[gi][ki,l]=alpha*drift*truth[gi][ki,l]+np.sqrt(max(0,1-alpha*alpha))*innovation
                        est[gi][ki,l]=alpha*drift*est[gi][ki,l]
                        cov[gi][ki,l]=(alpha*drift)**2*cov[gi][ki,l]+(1-alpha*alpha)*new_gain*RX
                        gain[gi][ki,l]=new_gain
        srs_group=(t//hop_tti)%cfg.srs_hops
        csi_event=(t%cfg.csi_rs_period_tti==0)
        if t:
            for gi,r in enumerate(resources):
                if not len(r.users):continue
                if not (csi_event or gi==srs_group):continue
                for ki in range(len(r.users)):
                    for l in np.flatnonzero(link_masks[gi][ki]):
                        base=gain[gi][ki,l]
                        if csi_event:
                            est[gi][ki,l],cov[gi][ki,l]=_posterior(
                                est[gi][ki,l],cov[gi][ki,l],truth[gi][ki,l],
                                range(4),base/10**(cfg.csi_rs_snr_db/10),rng)
                        if gi==srs_group:
                            est[gi][ki,l],cov[gi][ki,l]=_posterior(
                                est[gi][ki,l],cov[gi][ki,l],truth[gi][ki,l],
                                cfg.srs_ue_tx_to_rx_rows,
                                base/10**(cfg.pilot_snr_db/10),rng)
        fast=(beam_policy=='estimated_svd' and t>0 and t%fast_period_tti==0)
        slow=(t>0 and t%slow_period_tti==0)
        if fast:
            v=_fast_estimated_svd(resources,est,v,cfg.power_watt_per_trp)
        # Revisit the fixed user-centric association at the slow boundary.
        # Motion within 1 s is small; changes are counted and deferred to the
        # next solve, so this experiment does not claim dynamic scheduling.
        association_changes=0
        if slow:
            for r in resources:
                for ki,u in enumerate(r.users):
                    old=set(np.flatnonzero(r.serve[:,ki]))
                    active=set(int(scene.home[x]) for x in r.users)
                    ordered=sorted(active,key=lambda l:np.linalg.norm(scene.trp_xy[l]-ue_xy[u]))
                    proposed=set(([int(scene.home[u])]+[l for l in ordered if l!=scene.home[u]])[:cfg.service_trps])
                    association_changes+=old!=proposed
        capacity=np.zeros(cfg.users,float)
        for gi,r in enumerate(resources):
            if not len(r.users):continue
            rr=rates(truth[gi].astype(complex),v[gi])
            capacity[r.users]+=rr*(273*_weight(r))*12*cfg.scs_hz*cfg.tti_ms/1000
            physical_sum+=float(np.sum(rr)*_weight(r))*hop_tti/window_tti
            allocated_rb_tti[r.users]+=(273*_weight(r))*hop_tti
            tx=np.any(abs(v[gi])>1e-10,axis=(2,3))
            for l in range(cfg.trps):
                if np.any(tx[l]):
                    occupied_rb_tti+=(273*_weight(r))*np.count_nonzero(
                        np.any(busy[r.users,t:t+hop_tti][tx[l]],axis=0))
        for tt in range(t,t+hop_tti):
            incoming=busy[:,tt]*np.where(tail[:,tt],2/7,1)*offered_mbps*1e6*cfg.tti_ms/1000
            queue+=incoming
            offered+=incoming
            sent=np.minimum(queue,capacity)
            queue-=sent
            qualified=busy[:,tt]&~terminal[:,tt]
            delivered_tti[:,tt]=sent*qualified
            volume+=delivered_tti[:,tt]
            served_tti+=(sent>0)&busy[:,tt]
            completed_tti[:,tt]=terminal[:,tt]&(queue<1.)
            complete+=completed_tti[:,tt]
        powers=power_by_trp(resources,v)
        max_violation=max(max_violation,float(np.maximum(powers-cfg.power_watt_per_trp,0).max()))
        events.append({'tti':t,'srs_group':srs_group,'csi_rs':csi_event,
                       'fast_beam_update':fast,'slow_association_review':slow,
                       'association_changes_deferred':int(association_changes),
                       'mean_displacement_m':float(np.linalg.norm(ue_xy-scene.ue_xy,axis=1).mean()),
                       'max_trp_power_watt':float(powers.max())})
    valid_users=valid>0
    exp=np.full(cfg.users,np.nan)
    exp[valid_users]=volume[valid_users]/(valid[valid_users]*cfg.tti_ms/1000)/1e6
    second_samples=second_level_samples(delivered_tti,busy,terminal,cfg.tti_ms)
    per_burst=burst_samples(delivered_tti,busy,terminal,cfg.tti_ms)
    protocol_candidate=completed_burst_ue_second_candidates(
        delivered_tti,busy,terminal,cfg.tti_ms,completed_tti=completed_tti)
    return {'model':'mobile RX-correlated Gauss-Markov; J0(2pi fD Delta); not full 38.901',
            'decision':('initial power/beam frozen' if beam_policy=='frozen' else
                        'initial matrix WMMSE power; estimated-SVD fast beam refresh')+
                       '; association review every 340 TTI with changes deferred',
            'beam_policy':beam_policy,
            'traffic_seed':traffic_seed,
            'second_level_burst_filtered_proxy':second_samples,
            'per_burst_throughput_proxy':per_burst,
            'completed_burst_ue_second_candidate':protocol_candidate,
            'acceptance_contract':acceptance_contract(),
            'actual_busy_ue_tti_fraction':float(np.mean(busy)),
            'actual_tail_tti_fraction_of_busy':float(np.sum(tail)/max(np.sum(busy),1)),
            'window_tti':window_tti,'window_seconds':duration_seconds,
            'offered_mbps_per_active_ue':offered_mbps,
            'fast_period_tti':fast_period_tti,'slow_period_tti':slow_period_tti,
            'configured_srs_snr_db':cfg.pilot_snr_db,'srs_condition_below_minus10_db':bool(cfg.pilot_snr_db<-10),
            'doppler_hz':f_d,'twenty_tti_fading_correlation':alpha,
            'srs_events':len(events),'csi_rs_events':sum(x['csi_rs'] for x in events),
            'fast_updates':sum(x['fast_beam_update'] for x in events),
            'slow_reviews':sum(x['slow_association_review'] for x in events),
            'deferred_association_changes':sum(x['association_changes_deferred'] for x in events),
            'users_with_valid_samples':int(valid_users.sum()),
            'valid_tti_total':int(valid.sum()),
            'completed_bursts':int(complete.sum()),'total_bursts':int(bursts.sum()),
            'experience_bottom5_mbps_valid':float(np.percentile(exp[valid_users],5)),
            'experience_bottom5_mbps_all_zero_included':float(np.percentile(np.nan_to_num(exp),5)),
            'experience_mean_mbps_valid':float(np.nanmean(exp)),
            'physical_sum_bits_per_s_hz_time_mean':physical_sum,
            'allocated_prb_fraction_mean':float(np.mean(scene.active_prb_ratio)),
            'actual_prb_fraction_mean':occupied_rb_tti/(cfg.trps*cfg.rb_total*window_tti),
            'max_power_violation_watt':max_violation,
            'runtime_seconds':perf_counter()-start,
            'per_ue_experience_mbps':[None if not np.isfinite(x) else float(x) for x in exp],
            'per_ue_valid_tti':valid.tolist(),'per_ue_served_tti':served_tti.tolist(),
            'per_ue_allocated_rb_tti':allocated_rb_tti.tolist(),
            'per_ue_completed_bursts':complete.tolist(),
            'per_ue_offered_mbit':(offered/1e6).tolist(),
            'per_ue_delivered_mbit':(volume/1e6).tolist(),
            'events':events}
