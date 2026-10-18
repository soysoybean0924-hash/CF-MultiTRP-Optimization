"""Sparse scheduled-link, full-273-RB formal scene and measurement events."""
from dataclasses import dataclass
import numpy as np
from .config import Config
from .pathloss import outdoor_pathloss_db,los_probability
from .srs_reuse import update_from_reused_pilots


@dataclass
class Resource:
    rb_start: int
    rb_count: int
    users: np.ndarray                 # global UE IDs [K_g]
    serve: np.ndarray                 # [21,K_g], sparse transmission mask
    h_est: np.ndarray                 # [K_g,21,4,64]
    h_true: np.ndarray                # held out; evaluator only
    error_var: np.ndarray             # [K_g,21,4,4], Cov(vec_F E)=I_64 kron C_rx
    omitted_gain: np.ndarray           # [K_g,21], expected-gain bound for distance-pruned links
    age_ms: float
    measured: bool
    prior_gain: np.ndarray = None      # [K_g,21], large-scale gain; no H_true access
    tx_rb_count: int = None           # active RB within this SRS-aligned optimization group
    srs_diagnostic: list = None       # one entry/TRP in optional pilot-reuse mode


@dataclass
class Scenario:
    config: Config
    trp_xy: np.ndarray
    ue_xy: np.ndarray
    home: np.ndarray
    resources: list
    events: list
    active_prb_ratio: np.ndarray      # [21]
    calibration: dict


def _geometry(cfg, rng):
    center = np.array([450.0, 450.0])
    sites = [center]
    sites += [center + 300.0 * np.array([np.cos(i*np.pi/3), np.sin(i*np.pi/3)]) for i in range(6)]
    sites = np.array(sites)
    xy = np.repeat(sites, 3, axis=0)
    home = np.repeat(np.arange(21), cfg.users_per_cell)
    ux = np.zeros((cfg.users, 2))
    for l in range(21):
        angle = (l % 3) * 2*np.pi/3
        a = angle + rng.uniform(-np.pi/3, np.pi/3, cfg.users_per_cell)
        radius = 25 + 125*np.sqrt(rng.random(cfg.users_per_cell))
        ux[l*cfg.users_per_cell:(l+1)*cfg.users_per_cell] = xy[l] + radius[:, None] * np.stack((np.cos(a), np.sin(a)), axis=1)
    return xy, ux, home


def _rx_covariance():
    idx = np.arange(4)
    return (0.35 ** np.abs(idx[:, None] - idx[None, :])).astype(np.complex128)


def _link_gain(cfg, distance_m, bearing, sector, rng):
    offset = np.angle(np.exp(1j*(bearing - (sector % 3)*2*np.pi/3)))
    sector_gain = 0.08 + 0.92 * max(np.cos(offset), 0.0) ** 4
    if cfg.channel_mode == 'geometry_correlated_surrogate':
        path = (max(distance_m, 10.0) / 100.0) ** -3.2
        return 0.025 * path * sector_gain
    typ=cfg.channel_mode[:3]
    los=rng.random()<los_probability(distance_m,typ)
    pl=outdoor_pathloss_db(distance_m,cfg.frequency_ghz,typ,los)
    shadow_sigma=4.0 if los else (7.82 if typ=='umi' else 6.0)
    pl+=rng.normal(0,shadow_sigma)
    # A beam variable has units sqrt(W) averaged over the full 273-RB band.
    return 10**(-pl/10)*sector_gain/(cfg.noise_watt_per_rb*cfg.rb_total)


def _channel(rng, gain):
    # Four receive ports, 8x4 dual-polarized (64) transmit ports.
    z = (rng.standard_normal((4, 64)) + 1j*rng.standard_normal((4, 64))) / np.sqrt(2)
    return np.sqrt(gain) * (_rx_covariance_chol() @ z)


_RX_CHOL = np.linalg.cholesky(_rx_covariance())


def _rx_covariance_chol():
    return _RX_CHOL


def _schedule(cfg, rng, home):
    # SRS hopping blocks and optimization groups are aligned only as an
    # implementation approximation. tx_rb_count may be smaller than hop width.
    counts = [x[1] for x in cfg.rb_groups]
    active = np.zeros((21, 17), dtype=bool)
    target = round(cfg.prb_utilization * 273)
    tx_counts=np.zeros(17,int)
    if cfg.schedule_mode=='precise_shared_rb':
        # Shared RB positions across TRPs make the one-V-per-group coherent
        # interference model exact under this scheduler. Nearest integer RB
        # is necessary because 50% of 273 equals 136.5 RB.
        remaining=target
        for g in rng.permutation(17):
            tx_counts[g]=min(counts[g],remaining)
            remaining-=tx_counts[g]
            if remaining==0:break
        active[:]=tx_counts[None,:]>0
    else:
        for l in range(21):
            order = rng.permutation(17)
            running = 0
            for g in order:
                if running + counts[g] <= target + 9:
                    active[l, g] = True
                    running += counts[g]
                if running >= target - 8:
                    break
        tx_counts=np.array(counts)
    pools = [rng.permutation(np.flatnonzero(home == l)) for l in range(21)]
    cursors = np.zeros(21, int)
    users_by_group = []
    for g in range(17):
        selected = []
        for l in np.flatnonzero(active[:, g]):
            for _ in range(cfg.users_per_active_cell_rb):
                selected.append(int(pools[l][cursors[l] % len(pools[l])]))
                cursors[l] += 1
        users_by_group.append(np.array(selected, dtype=int))
    ratio = active @ tx_counts / 273.0
    return users_by_group, ratio, active, tx_counts


def _calibrate_independent(cfg, rng):
    # Independent train-only Monte Carlo checks the 2-port SRS + 4-port
    # CSI-RS Gaussian LMMSE posterior covariance used by the optimizer.
    gain = 0.05
    ns=gain/(10**(cfg.pilot_snr_db/10))
    nc=gain/(10**(cfg.csi_rs_snr_db/10))
    prior=gain*_rx_covariance()
    rows=list(cfg.srs_ue_tx_to_rx_rows)
    precision=np.linalg.inv(prior)+np.eye(4)/nc
    precision[rows,rows]+=1/ns
    posterior=np.linalg.inv(precision)
    count=5000
    h=np.linalg.cholesky(prior) @ ((rng.standard_normal((4,count))+1j*rng.standard_normal((4,count)))/np.sqrt(2))
    yc=h+np.sqrt(nc/2)*(rng.standard_normal((4,count))+1j*rng.standard_normal((4,count)))
    ys=h[rows]+np.sqrt(ns/2)*(rng.standard_normal((2,count))+1j*rng.standard_normal((2,count)))
    rhs=yc/nc;rhs[rows]+=ys/ns
    residual=h-posterior@rhs
    empirical=residual@residual.conj().T/count
    relative=float(np.linalg.norm(empirical-posterior)/np.linalg.norm(posterior))
    return {"seed":cfg.seed+101,"samples":count,
            "model":"two-port SRS plus four-port CSI-RS matrix LMMSE; train-only Monte Carlo",
            "relative_covariance_fro_error":relative,
            "analytic_covariance_trace":float(np.trace(posterior).real),
            "empirical_covariance_trace":float(np.trace(empirical).real)}


def generate(cfg):
    cfg.validate()
    rng = np.random.default_rng(cfg.seed)
    # Keep the held-out channel and each observation source fixed when only
    # decision time / measurement coverage changes. Conditional SRS draws
    # must not shift later H_true or CSI-RS samples in the random stream.
    true_rng=np.random.default_rng(cfg.seed+201)
    csi_rng=np.random.default_rng(cfg.seed+202)
    srs_rng=np.random.default_rng(cfg.seed+203)
    trp_xy, ue_xy, home = _geometry(cfg, rng)
    users_by_group, active_ratio, active_by_trp_group, tx_counts = _schedule(cfg, rng, home)
    cal = (_calibrate_independent(cfg, np.random.default_rng(cfg.seed+101))
           if cfg.srs_mode=='awgn_independent' else
           {'status':'not applicable: independent-AWGN calibration does not validate pilot reuse',
            'model':'synthetic equal-power pilot reuse with Gaussian current/past correlation',
            'numerical_unit_test':'python -m chasi_formal_implementation.test_srs_reuse'})
    # Large-scale pathloss/LOS/shadow are common across all 17 resources.
    gains=np.zeros((cfg.users,21),float)
    for u in range(cfg.users):
        for l in range(21):
            d=np.linalg.norm(trp_xy[l]-ue_xy[u])
            bearing=np.arctan2(ue_xy[u,1]-trp_xy[l,1],ue_xy[u,0]-trp_xy[l,0])
            gains[u,l]=_link_gain(cfg,d,bearing,l,rng)
    # A fixed noise floor makes SRS quality link-dependent. The reference is
    # a large-scale home-link median, never H_true; configured pilot_snr_db
    # is reference SNR, not each link's SNR or its resulting pilot SINR.
    srs_reference_gain=float(np.median(gains[np.arange(cfg.users),home]))
    reuse_rng=np.random.default_rng(cfg.seed+204)
    resources = []
    for g, ((rb_start, rb_count), users) in enumerate(zip(cfg.rb_groups, users_by_group)):
        k_count = len(users)
        serve = np.zeros((21, k_count), bool)
        h_est = np.zeros((k_count, 21, 4, 64), np.complex64)
        h_true = np.zeros_like(h_est)
        err = np.zeros((k_count, 21, 4, 4), np.complex64)
        omitted_gain = np.zeros((k_count,21),np.float32)
        first_measurement = g * 20
        measured = cfg.decision_tti >= first_measurement
        if measured:
            cycles = (cfg.decision_tti-first_measurement)//cfg.srs_period_tti
            measured_at = first_measurement+cycles*cfg.srs_period_tti
            age = (cfg.decision_tti-measured_at)*cfg.tti_ms
        else:
            age = -1.0  # unmeasured, no use of a future SRS observation
        csi_age=(cfg.decision_tti % cfg.csi_rs_period_tti)*cfg.tti_ms
        for ki, u in enumerate(users):
            distances = np.linalg.norm(trp_xy - ue_xy[u], axis=1)
            nearest = np.argsort(distances)
            candidates = [int(home[u])] + [int(l) for l in nearest
                                           if l != home[u] and active_by_trp_group[l,g]]
            serve[candidates[:cfg.service_trps], ki] = True
            for l in range(21):
                if distances[l] > cfg.max_interference_distance_m and not serve[l, ki]:
                    omitted_gain[ki,l]=gains[u,l]
                    continue
                gain = gains[u,l]
                true=_channel(true_rng,gain)
                prior=gain*_rx_covariance()
                nc=gain/(10**(cfg.csi_rs_snr_db/10))*np.exp(2*csi_age/cfg.age_coherence_ms)
                precision=np.linalg.inv(prior)+np.eye(4)/nc
                yc=true+np.sqrt(nc/2)*(csi_rng.standard_normal((4,64))+1j*csi_rng.standard_normal((4,64)))
                rhs=yc/nc
                srs_noise=(srs_rng.standard_normal((2,64))+
                           1j*srs_rng.standard_normal((2,64)))/np.sqrt(2)
                if measured and cfg.srs_mode=='awgn_independent':
                    # The 2 UE uplink Tx ports observe only the selected two
                    # rows of the 4-port DL channel under reciprocity. CSI-RS
                    # feedback supplies the remaining four-port observation.
                    rows=list(cfg.srs_ue_tx_to_rx_rows)
                    ns=gain/(10**(cfg.pilot_snr_db/10))*np.exp(2*age/cfg.age_coherence_ms)
                    ys=true[rows]+np.sqrt(ns)*srs_noise
                    precision[rows,rows]+=1/ns
                    rhs[rows]+=ys/ns
                posterior=np.linalg.inv(precision)
                h_est[ki,l]=posterior@rhs
                err[ki,l]=posterior
                # H_true is generated jointly with observations and only sent
                # to held-out evaluation or the explicit ideal-CSI reference.
                h_true[ki,l]=true
        group_srs_diagnostic=[]
        if measured and k_count and cfg.srs_mode=='pilot_reuse_gaussian':
            pilot_ids=users % cfg.srs_pilot_sequences
            noise=srs_reference_gain/(10**(cfg.pilot_snr_db/10))
            for l in range(cfg.trps):
                modeled=omitted_gain[:,l]==0
                if not np.any(modeled):
                    continue
                updated,covariance,diag=update_from_reused_pilots(
                    h_est[:,l],err[:,l],h_true[:,l],gains[users,l],
                    modeled,pilot_ids,noise,reuse_rng,
                    rows=cfg.srs_ue_tx_to_rx_rows,age_ms=age,
                    coherence_ms=cfg.age_coherence_ms)
                h_est[modeled,l]=updated[modeled].astype(np.complex64)
                err[modeled,l]=covariance[modeled].astype(np.complex64)
                diag['trp_id']=l
                group_srs_diagnostic.append(diag)
        resources.append(Resource(rb_start, rb_count, users, serve, h_est, h_true,
                                  err, omitted_gain, age, measured,
                                  gains[users].astype(np.float32),int(tx_counts[g]),
                                  group_srs_diagnostic))
    events = []
    # The decision at T=duration_tti may use the SRS event at that boundary.
    # Traffic remains the half-open window [0, duration_tti).
    for t in range(cfg.duration_tti+1):
        event = {"tti": t, "ms": t*cfg.tti_ms}
        if t % 20 == 0:
            event["srs_group"] = (t//20) % 17
        if t % cfg.csi_rs_period_tti == 0:
            event["csi_rs"] = True
        events.append(event)
    return Scenario(cfg, trp_xy, ue_xy, home, resources, events, active_ratio, cal)
