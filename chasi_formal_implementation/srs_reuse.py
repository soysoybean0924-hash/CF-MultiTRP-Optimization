"""Optional explicit uplink SRS pilot-reuse observation and Gaussian posterior.

This is an auditable simulation hypothesis, not a claim of Huawei pilot
assignment or a complete 3GPP receiver. Pilot collisions are simultaneous
linear sums at a TRP. CSI-RS posterior means/covariances are the priors.
"""
import numpy as np


def update_from_reused_pilots(means, covariances, true_channels, prior_gain,
                              modeled, pilot_ids, noise_variance, rng,
                              rows=(0, 1),age_ms=0.0,coherence_ms=120.0):
    """Update one resource group / one TRP; arrays [K,4,Nt], [K,4,4].

    A distance-pruned co-pilot link is sampled for the SRS observation only;
    it is not added to the downlink optimizer or held-out evaluator.
    Only marginal Cov(vec_F E_k)=I_Nt kron C_rx,k is returned. Cross-UE
    posterior covariances induced by pilot reuse are not returned.
    """
    means=np.asarray(means,dtype=np.complex128)
    cov=np.asarray(covariances,dtype=np.complex128).copy()
    truth=np.asarray(true_channels,dtype=np.complex128).copy()
    gain=np.asarray(prior_gain,float)
    modeled=np.asarray(modeled,bool)
    pilot_ids=np.asarray(pilot_ids,int)
    rows=np.asarray(rows,int)
    k_count,nr,nt=means.shape
    if (cov.shape!=(k_count,nr,nr) or truth.shape!=means.shape or
            gain.shape!=(k_count,) or modeled.shape!=(k_count,) or
            pilot_ids.shape!=(k_count,) or noise_variance<=0 or
            age_ms<0 or coherence_ms<=0):
        raise ValueError('invalid pilot-reuse array dimensions or noise')
    if len(set(rows.tolist()))!=len(rows) or np.any(rows<0) or np.any(rows>=nr):
        raise ValueError('invalid observed RX rows')
    output=means.copy()
    # RX covariance of unmodeled remote links follows the scene's current
    # surrogate prior. Those links affect pilot collisions but remain pruned
    # from downlink precoder/rate arrays.
    rx=(0.35 ** np.abs(np.arange(nr)[:,None]-np.arange(nr)[None,:])).astype(complex)
    chol=np.linalg.cholesky(rx)
    alpha=float(np.exp(-age_ms/coherence_ms))
    for k in np.flatnonzero(~modeled):
        cov[k]=gain[k]*rx
        z=(rng.standard_normal((nr,nt))+1j*rng.standard_normal((nr,nt)))/np.sqrt(2)
        truth[k]=np.sqrt(gain[k])*(chol@z)
    past=np.empty_like(truth)
    for k in range(k_count):
        z=(rng.standard_normal((nr,nt))+1j*rng.standard_normal((nr,nt)))/np.sqrt(2)
        innovation=np.sqrt(gain[k])*(chol@z)
        past[k]=alpha*truth[k]+np.sqrt(max(0.0,1-alpha*alpha))*innovation
    snr=[]
    sinr=[]
    collision=[]
    observed_indices=[]
    for pid in np.unique(pilot_ids):
        idx=np.flatnonzero(pilot_ids==pid)
        total=np.sum(past[idx][:,rows,:],axis=0)
        noise=(rng.standard_normal((len(rows),nt))+1j*rng.standard_normal((len(rows),nt)))*np.sqrt(noise_variance/2)
        observation=total+noise
        expected=alpha*np.sum(means[idx][:,rows,:],axis=0)
        s=noise_variance*np.eye(len(rows),dtype=complex)
        for k in idx:
            observed_cov=alpha*alpha*cov[k]+(1-alpha*alpha)*gain[k]*rx
            s+=observed_cov[np.ix_(rows,rows)]
        inv_s=np.linalg.inv(s)
        innovation=observation-expected
        for k in idx:
            if not modeled[k]:
                continue
            gain_matrix=alpha*cov[k][:,rows]@inv_s
            output[k]=means[k]+gain_matrix@innovation
            updated=cov[k]-gain_matrix@(alpha*cov[k][rows,:])
            cov[k]=(updated+updated.conj().T)/2
            desired=past[k,rows,:]
            interference=total-desired
            signal_power=float(np.mean(np.abs(desired)**2))
            interference_power=float(np.mean(np.abs(interference)**2))
            snr.append(signal_power/noise_variance)
            sinr.append(signal_power/(noise_variance+interference_power))
            collision.append(len(idx)-1)
            observed_indices.append(int(k))
    return output,cov,{'signal_to_awgn_linear':snr,
                       'signal_to_interference_plus_awgn_linear':sinr,
                       'co_pilot_user_count':collision,
                       'observed_group_user_indices':observed_indices,
                       'pilot_noise_variance':float(noise_variance),
                       'measurement_age_ms':float(age_ms),
                       'current_past_correlation':alpha,
                       'pilot_sequences_in_group':int(len(np.unique(pilot_ids))),
                       'modeled_observed_links':int(np.count_nonzero(modeled))}
