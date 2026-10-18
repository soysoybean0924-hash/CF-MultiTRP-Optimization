"""Held-out channel and TS 28.554-style burst-aware user throughput proxy."""
import numpy as np
from .solver import rates, power_by_trp,RX,_weight
from .traffic_model import generate_traffic
from .protocol_contract import cdf_candidates, acceptance_contract


def srs_observation_snr_diagnostic(scene):
    """Held-out realization diagnostic; never enters an optimizer decision."""
    cfg=scene.config
    if getattr(cfg,'srs_mode','awgn_independent')=='pilot_reuse_gaussian':
        snr=[];sinr=[];served_snr=[];served_sinr=[];collisions=[]
        measured_groups=0
        for r in scene.resources:
            if not r.measured or not len(r.users):
                continue
            measured_groups+=1
            for d in r.srs_diagnostic or []:
                l=d['trp_id']
                for k,a,b,c in zip(d['observed_group_user_indices'],
                                   d['signal_to_awgn_linear'],
                                   d['signal_to_interference_plus_awgn_linear'],
                                   d['co_pilot_user_count']):
                    snr.append(10*np.log10(max(a,1e-30)))
                    sinr.append(10*np.log10(max(b,1e-30)))
                    collisions.append(c)
                    if r.serve[l,k]:
                        served_snr.append(snr[-1])
                        served_sinr.append(sinr[-1])
        def quantile(values):
            return np.percentile(values,[5,50,95]).tolist() if values else None
        return {'metric_name':'synthetic equal-power pilot-reuse SRS observation SNR and SINR',
                'configured_reference_signal_to_awgn_db':cfg.pilot_snr_db,
                'pilot_sequences_per_hop_assumption':cfg.srs_pilot_sequences,
                'realized_signal_to_awgn_db_p05_p50_p95':quantile(snr),
                'realized_signal_to_interference_plus_awgn_db_p05_p50_p95':quantile(sinr),
                'served_link_snr_db_p05_p50_p95':quantile(served_snr),
                'served_link_sinr_db_p05_p50_p95':quantile(served_sinr),
                'all_modeled_fraction_sinr_below_minus10_db':float(np.mean(np.asarray(sinr)<-10)) if sinr else None,
                'served_fraction_sinr_below_minus10_db':float(np.mean(np.asarray(served_sinr)<-10)) if served_sinr else None,
                'mean_co_pilot_user_count':float(np.mean(collisions)) if collisions else None,
                'sample_links':len(sinr),'served_sample_links':len(served_sinr),
                'measured_srs_groups_with_scheduled_ues':measured_groups,
                'includes_awgn':True,'includes_pilot_interference':True,
                'synthetic_all_modeled_link_median_sinr_db':float(np.median(sinr)) if sinr else None,
                'synthetic_served_link_median_sinr_db':float(np.median(served_sinr)) if served_sinr else None,
                'system_srs_sinr_db':None,
                'system_srs_sinr_status':'official system aggregation/pilot assignment and UE powers are undefined; synthetic all-modeled and served-link SINR distributions are separate',
                'scope':'SRS at measurement event, age-aware Gaussian current/past correlation; reference SNR is not realized SINR; H_true used only to synthesize observation/diagnose'}
    rows=list(cfg.srs_ue_tx_to_rx_rows)
    values=[]
    measured_groups=0
    for r in scene.resources:
        if not r.measured or not len(r.users):
            continue
        measured_groups+=1
        signal=np.mean(abs(r.h_true[:,:,rows,:])**2,axis=(2,3))
        gain=np.asarray(r.prior_gain)
        # Distance-pruned links have no generated true-channel realization.
        valid=(gain>0)&(signal>0)
        if np.any(valid):
            snr=signal[valid]*10**(cfg.pilot_snr_db/10)/gain[valid]
            values.extend((10*np.log10(np.maximum(snr,1e-30))).tolist())
    a=np.asarray(values)
    if not len(a):
        quantiles=None
        below=None
    else:
        quantiles=np.percentile(a,[5,50,95]).tolist()
        below=float(np.mean(a<-10))
    return {'metric_name':'SRS observation SNR',
            'configured_mean_signal_to_awgn_db':cfg.pilot_snr_db,
            'realized_signal_to_awgn_db_p05_p50_p95':quantiles,
            'realized_fraction_below_minus10_db':below,
            'sample_links':len(a),
            'measured_srs_groups_with_scheduled_ues':measured_groups,
            'includes_awgn':True,
            'includes_pilot_interference':False,
            'system_srs_sinr_db':None,
            'system_srs_sinr_status':'not available: pilot reuse/interference is not modeled',
            'scope':'AWGN observation quality only; no pilot interference, hence not system SRS SINR'}


def traffic_samples(scene):
    cfg=scene.config
    return generate_traffic(cfg.users,cfg.duration_tti,cfg.seed,
                            getattr(cfg,'traffic_model','legacy_bursts'),
                            getattr(cfg,'traffic_load',0.30))


def evaluate(scene,solution,traffic=None):
    cfg=scene.config
    busy,tail,terminal=traffic if traffic is not None else traffic_samples(scene)
    busy_fraction=float(np.mean(busy))
    tail_fraction=float(np.sum(tail)/max(np.sum(busy),1))
    demand_weights=np.where(tail,2/7,1.0)*busy
    tail_demand_fraction=float(np.sum(demand_weights*tail)/max(np.sum(demand_weights),1))
    per_ue_physical=np.zeros(cfg.users)
    per_ue_group=np.zeros((cfg.users,17))
    omitted_expected=0.0
    modeled_noise=0.0
    omitted_max=0.0
    for g,(r,v) in enumerate(zip(scene.resources,solution.precoders)):
        rr=rates(np.asarray(r.h_true,dtype=np.complex128),v)
        per_ue_group[r.users,g]=rr
        per_ue_physical[r.users] += rr*_weight(r)
        omitted=r.omitted_gain @ np.sum(abs(v)**2,axis=(1,2,3))*np.trace(RX).real
        omitted_expected += float(np.sum(omitted)*_weight(r))
        modeled_noise += len(r.users)*4*_weight(r)
        omitted_max=max(omitted_max,float(np.max(omitted)) if len(omitted) else 0.0)
    # RB occupied only when the scheduled UE has nonempty buffer.
    occupied=np.zeros((21,cfg.duration_tti))
    scheduled=np.zeros(cfg.users,bool)
    volume=np.zeros(cfg.users)
    allocated_rb=np.zeros(cfg.users)
    scheduled_groups=np.zeros(cfg.users,int)
    service_occurrences=np.zeros(cfg.users,int)
    weighted_tx_power=np.zeros(cfg.users)
    for g,r in enumerate(scene.resources):
        group_occupied=np.zeros((21,cfg.duration_tti),bool)
        for ki,u in enumerate(r.users):
            scheduled[u]=True
            allocated_rb[u]+=273*_weight(r)
            scheduled_groups[u]+=1
            active_trp=np.any(abs(solution.precoders[g][:,ki])>1e-10,axis=(1,2))
            service_occurrences[u]+=int(np.count_nonzero(active_trp))
            weighted_tx_power[u]+=_weight(r)*float(np.sum(abs(solution.precoders[g][:,ki])**2))
            usable=busy[u] & ~terminal[u]
            # 12 subcarriers * 30 kHz; tail-phase demand is an assumption.
            demand=np.where(tail[u],2/7,1.0)
            volume[u] += float((usable*demand).sum()) * per_ue_group[u,g] * (273*_weight(r)) * 12*cfg.scs_hz * cfg.tti_ms/1000
            for l in np.flatnonzero(np.any(abs(solution.precoders[g][:,ki])>1e-10,axis=(1,2))):
                group_occupied[l] |= busy[u]
        # PRB occupancy is a union across MU-MIMO UEs on the same RBG.
        occupied += group_occupied*(273*_weight(r))
    valid=np.sum((busy & ~terminal) & scheduled[:,None],axis=1)
    exp_rate=np.full(cfg.users,np.nan)
    good=valid>0
    exp_rate[good]=volume[good]/(valid[good]*cfg.tti_ms/1000)
    pct=lambda x,p: float(np.percentile(x,p)) if len(x) else None
    exp_good=exp_rate[good]
    static_cdf=cdf_candidates(exp_good/1e6,missing_count=int((~good).sum()))
    powers=power_by_trp(scene.resources,solution.precoders)
    return {
        'users_total':cfg.users,'users_with_valid_samples':int(good.sum()),
        'users_without_valid_samples':int((~good).sum()),
        'valid_sample_count':int(valid.sum()),'duration_tti':cfg.duration_tti,
        'physical_mean_bits_per_s_hz':float(per_ue_physical.mean()),
        'physical_sum_bits_per_s_hz':float(per_ue_physical.sum()),
        'experience_mean_mbps_valid_ues':float(exp_good.mean()/1e6) if len(exp_good) else None,
        'experience_bottom5_mbps_valid_ues':pct(exp_good/1e6,5),
        'experience_bottom5_mbps_all_ues_zero_included':pct(np.nan_to_num(exp_rate,nan=0.0)/1e6,5),
        'static_experience_cdf_candidates':static_cdf,
        'acceptance_contract':acceptance_contract(),
        'experience_zero_included_mean_mbps':float(np.nan_to_num(exp_rate,nan=0.0).mean()/1e6),
        'allocated_prb_fraction_mean':float(np.mean(scene.active_prb_ratio)),
        'actual_prb_fraction_mean':float(np.mean(occupied/cfg.rb_total)),
        'offered_load_target':cfg.traffic_load,
        'traffic_model':getattr(cfg,'traffic_model','legacy_bursts'),
        'traffic_load_definition':'target UE x TTI buffer-nonempty fraction only in target_busy_fraction mode; not confirmed Huawei 30% offered load',
        'actual_busy_ue_tti_fraction':busy_fraction,
        'actual_tail_tti_fraction_of_busy':tail_fraction,
        'actual_tail_demand_fraction_of_arrivals':tail_demand_fraction,
        'total_bursts_started_proxy':int(np.sum(terminal)),
        'omitted_interference_expected_over_noise':omitted_expected/max(modeled_noise,1e-30),
        'omitted_interference_max_ue_rbg_normalized_power':omitted_max,
        'trp_power_watt_mean':float(powers.mean()),
        'trp_power_watt_max':float(powers.max()),
        'total_radiated_power_watt':float(powers.sum()),
        'energy_scope':'radiated TX power only; PA/baseband/fronthaul energy unavailable',
        'sample_definition':'per UE, busy DL TTIs except terminal TTI of each burst; window [0,340) TTI; users without valid samples reported separately',
        'per_ue_physical_bits_per_s_hz':per_ue_physical.tolist(),
        'per_ue_experience_mbps':[None if np.isnan(x) else float(x/1e6) for x in exp_rate],
        'per_ue_weighted_tx_power_watt':weighted_tx_power.tolist(),
        'per_ue_allocated_rb':allocated_rb.astype(int).tolist(),
        'per_ue_scheduled_groups':scheduled_groups.tolist(),
        'per_ue_service_trp_occurrences':service_occurrences.tolist(),
        'per_ue_busy_tti':np.sum(busy,axis=1).tolist(),
        'per_ue_tail_tti':np.sum(tail,axis=1).tolist(),
        'per_ue_terminal_tti':np.sum(terminal,axis=1).tolist(),
        'per_ue_valid_tti':valid.tolist(),
        'per_ue_delivered_bits_proxy':volume.tolist(),
    }
