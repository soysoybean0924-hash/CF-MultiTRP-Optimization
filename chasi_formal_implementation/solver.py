"""Matrix WMMSE with sparse-link operator and cross-resource centralized ADMM.

The V=Z split is centralized; this is not a distributed TRP implementation.
Same user data is coherently summed across serving TRPs. Error covariance is
link-independent with Cov(vec_F E_kl)=I_64 kron C_rx,kl.
"""
from dataclasses import dataclass
from time import perf_counter
import numpy as np

RX = (0.35 ** np.abs(np.arange(4)[:, None]-np.arange(4)[None, :])).astype(np.complex128)


@dataclass
class Solution:
    precoders: list
    receivers: list
    weights: list
    proxy_rate: float
    trajectory: list
    converged: bool
    reason: str
    outer_iterations: int
    primal_residual: float
    dual_residual: float
    eps_primal: float
    eps_dual: float
    max_power_violation: float
    runtime_seconds: float
    branch: str
    optimization_objective: float = 0.0
    objective_name: str = 'estimated_sum_rate_bits_per_s_hz'
    estimated_sum_rate: float = 0.0
    estimated_per_ue_rate: list = None
    final_user_weights: list = None


def _norm(xs):
    return float(np.sqrt(sum(np.vdot(x, x).real for x in xs)))


def _weight(resource):
    active = getattr(resource, 'tx_rb_count', None)
    return (resource.rb_count if active is None else active)/273.0


def power_by_trp(resources, vs):
    return sum((_weight(r))*np.sum(abs(v)**2, axis=(1,2,3))
               for r, v in zip(resources, vs))


def _project(resources, xs, budget, masks):
    out = [np.array(x, copy=True) for x in xs]
    for x, mask in zip(out, masks):
        x *= mask[:, :, None, None]
    weighted = power_by_trp(resources, out)
    for l in range(out[0].shape[0]):
        if weighted[l] <= budget:
            continue
        lo, hi = 0.0, 1.0
        while sum((_weight(r))*np.vdot(x[l],x[l]).real /
                  (1+hi*_weight(r))**2 for r,x in zip(resources,out)) > budget:
            hi *= 2
        for _ in range(35):
            lam = (lo+hi)/2
            val = sum((_weight(r))*np.vdot(x[l],x[l]).real /
                      (1+lam*_weight(r))**2 for r,x in zip(resources,out))
            if val > budget: lo = lam
            else: hi = lam
        for r,x in zip(resources,out):
            x[l] /= 1+hi*_weight(r)
    return out


def _effective(h, v):
    # k = receiving UE, i = data stream owner; sum_l is coherent JT.
    return np.einsum('klrn,linq->kirq', h, v, optimize=True)


def rates(h, v):
    g = _effective(h, v)
    k_count, _, nr, _ = g.shape
    out = np.zeros(k_count)
    for k in range(k_count):
        interference = np.eye(nr, dtype=complex)
        for i in range(k_count):
            if i != k:
                interference += g[k,i] @ g[k,i].conj().T
        all_signal = interference + g[k,k] @ g[k,k].conj().T
        out[k] = max(0.0, (np.linalg.slogdet(all_signal)[1]-np.linalg.slogdet(interference)[1])/np.log(2))
    return out


def _state(h, error_cov, v):
    g = _effective(h, v)
    k_count = h.shape[0]
    trp_power = np.sum(abs(v)**2, axis=(1,2,3))
    u = np.zeros((k_count,4,v.shape[-1]), complex)
    w = np.zeros((k_count,v.shape[-1],v.shape[-1]), complex)
    proxy = np.zeros(k_count)
    for k in range(k_count):
        ryy = np.eye(4, dtype=complex)
        for i in range(k_count):
            ryy += g[k,i] @ g[k,i].conj().T
        ryy += np.einsum('l,lrs->rs',trp_power,error_cov[k],optimize=True)
        u[k] = np.linalg.solve(ryy,g[k,k])
        e = np.eye(v.shape[-1]) - u[k].conj().T @ g[k,k] - g[k,k].conj().T @ u[k] + u[k].conj().T @ ryy @ u[k]
        e = (e+e.conj().T)/2
        w[k] = np.linalg.inv(e)
        proxy[k] = -np.linalg.slogdet(e)[1]/np.log(2)
    return u,w,proxy


def _quadratic_parts(h, error_cov, u, w, shape, user_weights=None):
    k_count, l_count, _, nt = h.shape
    if user_weights is None:
        user_weights=np.ones(k_count)
    weighted_w=w*user_weights[:,None,None]
    m = np.einsum('krd,kde,kse->krs',u,weighted_w,u.conj(),optimize=True)
    uw = np.einsum('krd,kde->kre',u,weighted_w,optimize=True)
    b = np.einsum('klrn,krd->lknd',h.conj(),uw,optimize=True)
    err_diag = np.einsum('krs,klsr->l',m,error_cov,optimize=True).real
    return m,b,err_diag


def _edge_weights(scene, resource):
    """PF-inspired fixed weights from large-scale CSI, with no test-H access."""
    if not len(resource.users):return np.empty(0)
    home=scene.home[resource.users]
    gain=np.asarray(resource.prior_gain)[np.arange(len(home)),home]
    potential=np.log2(1+scene.config.power_watt_per_trp*scene.config.tx_ports*gain)
    raw=np.median(np.maximum(potential,0.01))/np.maximum(potential,0.01)
    return np.clip(raw,0.25,8.0)


def _aggregate_user_rates(scene, resources, states):
    """Aggregate estimated per-resource rates onto global UE IDs."""
    out=np.zeros(scene.config.users)
    for r,state in zip(resources,states):
        out[r.users]+=_weight(r)*state[2]
    return out


def _pf_derivatives(scene, per_ue_rate):
    """Derivative of sum log(R_u+floor), normalized by one common scalar."""
    floor=scene.config.pf_rate_floor_bits_per_s_hz
    derivative=1/np.maximum(per_ue_rate+floor,floor)
    scheduled=np.unique(np.concatenate([r.users for r in scene.resources
                                        if len(r.users)]))
    scale=np.median(derivative[scheduled]) if len(scheduled) else 1.0
    return derivative/max(scale,1e-30)


def _objective_snapshot(scene, resources, states, branch, fixed_weights=None):
    per_ue=_aggregate_user_rates(scene,resources,states)
    estimated_sum=float(np.sum(per_ue))
    if branch in ('matrix_pf_nominal','matrix_pf_uniform',
                  'matrix_pf_uniform_relative','matrix_pf_statistical'):
        floor=scene.config.pf_rate_floor_bits_per_s_hz
        # This differs from sum log(R+floor) only by a constant per scheduled
        # UE, but gives zero utility at zero rate and a meaningful stop scale.
        scheduled=np.unique(np.concatenate([r.users for r in resources
                                            if len(r.users)]))
        objective=float(np.sum(np.log1p(per_ue[scheduled]/floor)))
        derivatives=_pf_derivatives(scene,per_ue)
        weights=[derivatives[r.users] for r in resources]
        name=('sum_log_nominal_estimated_user_rate_plus_floor'
              if branch=='matrix_pf_nominal' else
              'sum_log_uniform_error_wmmse_user_proxy_plus_floor'
              if branch=='matrix_pf_uniform' else
              'sum_log_uniform_relative_error_wmmse_user_proxy_plus_floor'
              if branch=='matrix_pf_uniform_relative' else
              'sum_log_statistical_wmmse_user_proxy_plus_floor')
    elif branch=='matrix_edge_weighted':
        weights=fixed_weights
        objective=float(sum(_weight(r)*np.dot(ww,state[2])
                            for r,ww,state in zip(resources,weights,states)))
        name='fixed_large_scale_weighted_statistical_wmmse_proxy'
    else:
        weights=[np.ones(len(r.users)) for r in resources]
        objective=estimated_sum
        name=('statistical_error_aware_wmmse_proxy_sum_bits_per_s_hz'
              if branch=='matrix_statistical' else
              'true_channel_local_wmmse_sum_rate_bits_per_s_hz'
              if branch=='ideal' else
              'nominal_estimated_sum_rate_bits_per_s_hz')
    surrogate=float(sum(_weight(r)*np.dot(ww,state[2])
                        for r,ww,state in zip(resources,weights,states)))
    return objective,name,estimated_sum,per_ue,weights,surrogate


def _q_apply(h,m,err_diag,x,mask):
    g = _effective(h,x)
    mg = np.einsum('krs,kisd->kird',m,g,optimize=True)
    y = np.einsum('klrn,kird->lind',h.conj(),mg,optimize=True)
    y += err_diag[:,None,None,None]*x
    return y*mask[:,:,None,None]


def _cg(apply, rhs, initial, max_iter, tol=1e-5):
    x = np.array(initial,copy=True)
    r = rhs-apply(x)
    p = r.copy()
    rr = np.vdot(r,r).real
    target = tol*tol*max(1.0,np.vdot(rhs,rhs).real)
    for _ in range(max_iter):
        if rr <= target: break
        ap = apply(p)
        alpha = rr/max(np.vdot(p,ap).real,1e-30)
        x += alpha*p
        r -= alpha*ap
        rr_new = np.vdot(r,r).real
        p = r + (rr_new/max(rr,1e-30))*p
        rr = rr_new
    return x


def _v_objective(resources, hs, masks, parts, vs):
    """Fixed-U/W quadratic, including exactly one RB weight per resource."""
    value = 0.0
    for r, h, mask, (m, b, diag), v in zip(resources, hs, masks, parts, vs):
        qv = _q_apply(h, m, diag, v, mask)
        value += (_weight(r)) * (np.vdot(v, qv).real - 2*np.vdot(b, v).real)
    return float(value)


def _solve_v_admm(resources, hs, masks, parts, initial, budget, max_iter,
                  cg_iter, eps_abs, eps_rel, rho=0.05):
    """Centralized V=Z ADMM. Z is feasible even when the iteration limit is hit."""
    z = [v.copy() for v in initial]
    y = [np.zeros_like(v) for v in z]  # scaled dual; reset when U/W changes
    x = [v.copy() for v in z]
    n_complex = sum(v.size for v in z)
    history = []
    converged = False
    for inner in range(1, max_iter+1):
        new = []
        cg_relative = 0.0
        for r,h,mask,(m,b,diag),v,zg,yg in zip(resources,hs,masks,parts,x,z,y):
            weight = _weight(r)
            apply = lambda a,h=h,m=m,diag=diag,mask=mask,weight=weight: weight*_q_apply(h,m,diag,a,mask)+(rho/2)*a
            rhs = (weight*b+(rho/2)*(zg-yg))*mask[:,:,None,None]
            candidate = _cg(apply,rhs,v,cg_iter)*mask[:,:,None,None]
            cg_relative = max(cg_relative, float(_norm([apply(candidate)-rhs])/max(_norm([rhs]),1e-30)))
            new.append(candidate)
        oldz = z
        z = _project(resources,[v+yy for v,yy in zip(new,y)],budget,masks)
        y = [yy+v-zz for yy,v,zz in zip(y,new,z)]
        primal = _norm([v-zz for v,zz in zip(new,z)])
        dual = rho*_norm([zz-oo for zz,oo in zip(z,oldz)])
        epsp = np.sqrt(n_complex)*eps_abs+eps_rel*max(_norm(new),_norm(z))
        epsd = np.sqrt(n_complex)*eps_abs+eps_rel*rho*_norm(y)
        power = power_by_trp(resources,z)
        record = {'inner':inner,'rho':float(rho),'primal_residual':primal,
                  'dual_residual':dual,'eps_primal':epsp,'eps_dual':epsd,
                  'cg_max_relative_residual':cg_relative,
                  'max_power_violation_watt':float(np.maximum(power-budget,0).max()),
                  'fixed_uw_v_objective':_v_objective(resources,hs,masks,parts,z)}
        if not all(np.isfinite(v) for v in record.values()):
            raise FloatingPointError('nonfinite ADMM iterate diagnostics')
        history.append(record)
        x = new
        if primal<=epsp and dual<=epsd and cg_relative<=max(1e-3,10*eps_rel):
            converged=True
            break
        # Residual balancing changes the scaled dual as y := (old/new)*y.
        if inner % 10 == 0 and primal > 10*dual and rho < 10:
            rho_new = rho*2
            y = [yy*(rho/rho_new) for yy in y]
            rho = rho_new
        elif inner % 10 == 0 and dual > 10*primal and rho > 1e-5:
            rho_new = rho/2
            y = [yy*(rho/rho_new) for yy in y]
            rho = rho_new
    return z,history,converged


def _initial(resources, hs, masks, rank, budget):
    vs=[]
    for r,h,mask in zip(resources,hs,masks):
        k_count=h.shape[0]
        v=np.zeros((21,k_count,64,rank),complex)
        for k in range(k_count):
            for l in np.flatnonzero(mask[:,k]):
                _,_,vh=np.linalg.svd(h[k,l],full_matrices=False)
                v[l,k] = vh.conj().T[:,:rank]
        vs.append(v)
    return _project(resources,vs,budget,masks)


def solve(scene, branch=None, progress_callback=None, initial_precoders=None):
    cfg=scene.config
    branch=branch or cfg.solver
    if initial_precoders is not None and branch in ('fixed_direction_power','no_cooperation'):
        raise ValueError('precoder continuation is only supported for matrix WMMSE branches')
    if branch=='fixed_direction_power':
        return _solve_fixed_direction(scene)
    if branch=='no_cooperation':
        return _solve_local_mrt(scene)
    start=perf_counter()
    resources=scene.resources
    fixed_weights=([_edge_weights(scene,r) for r in resources]
                   if branch=='matrix_edge_weighted' else None)
    masks=[]; hs=[]; es=[]
    if branch in ('matrix_pf_uniform','matrix_pf_uniform_relative'):
        from .uniform_error import (uniform_group_covariances,
                                    uniform_relative_group_covariances)
        uniform_covariances=(uniform_group_covariances(resources)
                             if branch=='matrix_pf_uniform' else
                             uniform_relative_group_covariances(resources))
    for r in resources:
        mask=r.serve.copy()
        if branch == 'no_cooperation':
            mask[:]=False
            mask[scene.home[r.users],np.arange(len(r.users))]=True
        masks.append(mask)
        hs.append(np.asarray(r.h_true if branch=='ideal' else r.h_est,dtype=np.complex128))
        es.append(np.zeros_like(r.error_var) if branch in ('ideal','matrix_nominal',
                                                           'matrix_pf_nominal','no_cooperation')
                  else uniform_covariances[len(es)]
                  if branch in ('matrix_pf_uniform','matrix_pf_uniform_relative')
                  else np.asarray(r.error_var,dtype=np.complex128))
    if initial_precoders is None:
        vs=_initial(resources,hs,masks,cfg.rank,cfg.power_watt_per_trp)
        if cfg.initialization_mode!='svd':
            from .initializers import vary_initial
            vs=vary_initial(scene,vs,masks,cfg.initialization_mode,
                            cfg.seed+cfg.initialization_seed)
    else:
        if len(initial_precoders)!=len(resources):
            raise ValueError('continuation resource count differs from scene')
        vs=[]
        for g,(r,h,mask,v) in enumerate(zip(resources,hs,masks,initial_precoders)):
            v=np.asarray(v,dtype=np.complex128)
            expected=(h.shape[1],h.shape[0],h.shape[3],cfg.rank)
            if v.shape!=expected or not np.all(np.isfinite(v)):
                raise ValueError(f'continuation V_{g:02d} shape or finiteness mismatch')
            if np.any(abs(v[~mask])>1e-6):
                raise ValueError(f'continuation V_{g:02d} violates serving mask')
            vs.append(v.copy())
        if np.max(power_by_trp(resources,vs))>cfg.power_watt_per_trp+1e-4:
            raise ValueError('continuation exceeds per-TRP power budget')
    trajectory=[]
    converged=False; reason='max_outer_iterations'
    rnorm=snorm=epsp=epsd=float('inf')
    last_objective=-np.inf
    user_weights=[np.ones(len(r.users)) for r in resources]
    final_per_ue=np.zeros(cfg.users)
    estimated_sum=0.0
    objective=0.0
    objective_name='estimated_sum_rate_bits_per_s_hz'
    receivers=[]; weights=[]
    for outer in range(cfg.outer_iterations+1):
        states=[_state(h,e,v) for h,e,v in zip(hs,es,vs)]
        receivers=[s[0] for s in states]
        weights=[s[1] for s in states]
        (objective,objective_name,estimated_sum,final_per_ue,user_weights,
         surrogate)=_objective_snapshot(scene,resources,states,branch,fixed_weights)
        relative_change=(abs(objective-last_objective)/max(1.0,abs(last_objective))
                         if outer>0 else None)
        trajectory.append({'outer':outer,'optimization_objective':objective,
                           'objective_name':objective_name,
                           'estimated_sum_rate_bits_per_s_hz':estimated_sum,
                           'weighted_proxy_bits_per_s_hz':surrogate,
                           'outer_relative_objective_change':relative_change,
                           'max_power_watt':float(max(power_by_trp(resources,vs))),
                           'max_power_violation_watt':float(max(np.maximum(power_by_trp(resources,vs)-cfg.power_watt_per_trp,0))),
                           'primal_residual':rnorm if np.isfinite(rnorm) else None,
                           'dual_residual':snorm if np.isfinite(snorm) else None})
        if progress_callback is not None:
            progress_callback(trajectory)
        if outer>0 and objective<last_objective-1e-7*max(1,abs(last_objective)):
            reason='optimization_objective_decrease';break
        if outer>0 and relative_change<=cfg.outer_rel_tol:
            previous=trajectory[-2]
            if (previous.get('admm_converged',False) and
                    previous.get('precoder_relative_change',float('inf'))
                    <=cfg.outer_precoder_rel_tol):
                converged=True
                reason='relative_objective_precoder_and_admm_tolerance'
            elif not previous.get('admm_converged',False):
                reason='outer_stalled_with_inexact_admm'
            else:
                reason='outer_objective_stalled_precoder_not_stationary'
            if converged:
                break
        if outer==cfg.outer_iterations:
            reason=('max_outer_iterations_with_latest_inexact_admm'
                    if trajectory[:-1] and not trajectory[-2].get('admm_converged',True)
                    else 'max_outer_iterations')
            break
        last_objective=objective
        parts=[_quadratic_parts(h,e,u,w,v.shape,ww)
               for h,e,u,w,v,ww in zip(hs,es,receivers,weights,vs,user_weights)]
        candidate,inner_trace,inner_converged=_solve_v_admm(
            resources,hs,masks,parts,vs,cfg.power_watt_per_trp,
            cfg.admm_iterations,cfg.cg_iterations,cfg.eps_abs,cfg.eps_rel)
        rnorm=inner_trace[-1]['primal_residual']
        snorm=inner_trace[-1]['dual_residual']
        epsp=inner_trace[-1]['eps_primal']
        epsd=inner_trace[-1]['eps_dual']
        # An inexact ADMM step need not improve WMMSE. Accept only a feasible
        # nondecreasing step; no test-channel information enters this check.
        accepted=False
        step=1.0
        old_vs=vs
        for _ in range(12):
            trial=[old+step*(new-old) for old,new in zip(old_vs,candidate)]
            trial_states=[_state(h,e,v) for h,e,v in zip(hs,es,trial)]
            trial_objective=_objective_snapshot(
                scene,resources,trial_states,branch,fixed_weights)[0]
            if trial_objective>=objective-1e-7*max(1,abs(objective)):
                vs=trial;accepted=True;break
            step*=0.5
        relative_v_change=(_norm([new-old for old,new in zip(old_vs,vs)]) /
                           max(1.0,_norm(old_vs))) if accepted else 0.0
        trajectory[-1].update({'admm_iterations':len(inner_trace),
                               'admm_converged':inner_converged,
                               'admm_trace':inner_trace,
                               'accepted_step':step if accepted else 0.0,
                               'accepted_objective':float(trial_objective),
                               'precoder_relative_change':relative_v_change,
                               'primal_residual':rnorm,'dual_residual':snorm,
                               'eps_primal':epsp,'eps_dual':epsd})
        if progress_callback is not None:
            progress_callback(trajectory)
        if not accepted:
            reason='inexact_v_step_no_proxy_improvement'
            break
        if not inner_converged:
            reason='inner_inexact_continued'
    final_states=[_state(h,e,v) for h,e,v in zip(hs,es,vs)]
    receivers=[s[0] for s in final_states]
    weights=[s[1] for s in final_states]
    (objective,objective_name,estimated_sum,final_per_ue,user_weights,
     proxy)=_objective_snapshot(scene,resources,final_states,branch,fixed_weights)
    powers=power_by_trp(resources,vs)
    return Solution(vs,receivers,weights,proxy,trajectory,converged,reason,outer,
                    rnorm,snorm,epsp,epsd,float(max(np.maximum(powers-cfg.power_watt_per_trp,0))),
                    perf_counter()-start,branch,objective,objective_name,estimated_sum,
                    final_per_ue.tolist(),[x.tolist() for x in user_weights])


def _solve_local_mrt(scene):
    """Strict no-cooperation baseline: home TRP local SVD, local power ball.

    Each TRP uses only its own estimated channels to its scheduled home UEs.
    No cross-TRP CSI, exchange, or interference-aware transmit update occurs.
    """
    cfg=scene.config; start=perf_counter();rs=scene.resources
    hs=[np.asarray(r.h_est,dtype=np.complex128) for r in rs]
    masks=[]
    for r in rs:
        mask=np.zeros_like(r.serve)
        mask[scene.home[r.users],np.arange(len(r.users))]=True
        masks.append(mask)
    vs=_initial(rs,hs,masks,cfg.rank,cfg.power_watt_per_trp)
    # Defined local policy: every active TRP spends its own full cross-RB
    # budget on its scheduled MRT beams. This is policy construction, not an
    # evaluator-side feasibility repair or post-hoc score rescaling.
    initial_power=power_by_trp(rs,vs)
    for l in range(21):
        if initial_power[l]>0:
            scale=np.sqrt(cfg.power_watt_per_trp/initial_power[l])
            for v in vs:v[l]*=scale
    states=[_state(h,np.zeros_like(r.error_var),v) for h,r,v in zip(hs,rs,vs)]
    proxy=float(sum((_weight(r))*np.sum(s[2]) for r,s in zip(rs,states)))
    per_ue=_aggregate_user_rates(scene,rs,states)
    power=power_by_trp(rs,vs)
    return Solution(vs,[s[0] for s in states],[s[1] for s in states],proxy,
                    [{'outer':0,'weighted_proxy_bits_per_s_hz':proxy}],True,
                    'local_mrt_full_budget_no_cooperation',0,0.0,0.0,0.0,0.0,
                    float(max(np.maximum(power-cfg.power_watt_per_trp,0))),
                    perf_counter()-start,'no_cooperation',proxy,
                    'local_policy_estimated_sum_rate_bits_per_s_hz',proxy,
                    per_ue.tolist(),[np.ones(len(r.users)).tolist() for r in rs])

def _solve_fixed_direction(scene):
    """2023 scalar-power WMMSE/ADMM idea on fixed SVD beams, with new constraints.

    Unlike the reference real scalar a/B formula, this derives the quadratic
    from the actual coherent Nr x Nt channels and a one-stream receiver.
    """
    cfg=scene.config
    start=perf_counter()
    rs=scene.resources
    hs=[np.asarray(r.h_est,dtype=np.complex128) for r in rs]
    masks=[r.serve for r in rs]
    dirs=[]; mus=[]
    for h,mask in zip(hs,masks):
        k_count=h.shape[0]
        d=np.zeros((21,k_count,64,1),complex)
        mu=np.zeros((21,k_count),float)
        for l,k in zip(*np.nonzero(mask)):
            _,_,vh=np.linalg.svd(h[k,l],full_matrices=False)
            d[l,k,:,0]=vh.conj().T[:,0]
            mu[l,k]=1.0
        dirs.append(d);mus.append(mu)

    def as_v(coeff):
        return [d*x[:,:,None,None] for d,x in zip(dirs,coeff)]

    def project(coeff):
        out=[np.maximum(x,0)*mask for x,mask in zip(coeff,masks)]
        power=sum((_weight(r))*np.sum(x*x,axis=1) for r,x in zip(rs,out))
        for l in range(cfg.trps):
            if power[l]>cfg.power_watt_per_trp:
                lo,hi=0.0,1.0
                def projected_power(lam):
                    return sum(_weight(r)*np.dot(x[l],x[l])/(1+lam*_weight(r))**2
                               for r,x in zip(rs,out))
                while projected_power(hi)>cfg.power_watt_per_trp:
                    hi*=2
                for _ in range(45):
                    mid=(lo+hi)/2
                    if projected_power(mid)>cfg.power_watt_per_trp:lo=mid
                    else:hi=mid
                for r,x in zip(rs,out):x[l]/=1+hi*_weight(r)
        return out

    mus=project(mus)
    trajectory=[];converged=False;reason='max_outer_iterations'
    rnorm=snorm=epsp=epsd=float('inf')
    previous=-np.inf;rho=0.05
    receivers=[];weights=[]
    for outer in range(cfg.outer_iterations+1):
        vs=as_v(mus)
        states=[_state(h,np.zeros_like(r.error_var),v) for h,r,v in zip(hs,rs,vs)]
        receivers=[s[0] for s in states];weights=[s[1] for s in states]
        proxy=float(sum((_weight(r))*np.sum(s[2]) for r,s in zip(rs,states)))
        trajectory.append({'outer':outer,'weighted_proxy_bits_per_s_hz':proxy,
                           'primal_residual':rnorm,'dual_residual':snorm})
        if outer>0 and abs(proxy-previous)<=1e-4*max(1,abs(previous)):
            converged=True;reason='relative_proxy_tolerance';break
        if outer>0 and proxy<previous-1e-5:
            reason='proxy_decrease';break
        if outer==cfg.outer_iterations:break
        previous=proxy
        parts=[_quadratic_parts(h,np.zeros_like(r.error_var),u,w,v.shape)
               for h,r,u,w,v in zip(hs,rs,receivers,weights,vs)]
        z=[x.copy() for x in mus];y=[np.zeros_like(x) for x in mus]
        n=sum(x.size for x in mus)
        inner_converged=False
        inner_trace=[]
        for inner in range(1,cfg.admm_iterations+1):
            new=[]
            cg_relative=0.0
            for r,h,mask,d,(m,b,diag),x,zz,yy in zip(rs,hs,masks,dirs,parts,mus,z,y):
                weight=_weight(r)
                def apply(a,h=h,m=m,diag=diag,mask=mask,d=d,weight=weight):
                    q=_q_apply(h,m,diag,d*a[:,:,None,None],mask)
                    return weight*np.sum((d.conj()*q).real,axis=(2,3))+(rho/2)*a
                bscalar=np.sum((d.conj()*b).real,axis=(2,3))
                rhs=(weight*bscalar+(rho/2)*(zz-yy))*mask
                candidate=_cg(apply,rhs,x,cfg.cg_iterations)*mask
                cg_relative=max(cg_relative,_norm([apply(candidate)-rhs])/max(_norm([rhs]),1e-30))
                new.append(candidate)
            old=z
            z=project([x+yy for x,yy in zip(new,y)])
            y=[yy+x-zz for yy,x,zz in zip(y,new,z)]
            rnorm=_norm([x-zz for x,zz in zip(new,z)])
            snorm=rho*_norm([zz-oo for zz,oo in zip(z,old)])
            epsp=np.sqrt(n)*cfg.eps_abs+cfg.eps_rel*max(_norm(new),_norm(z))
            epsd=np.sqrt(n)*cfg.eps_abs+cfg.eps_rel*rho*_norm(y)
            mus=new
            inner_trace.append({'inner':inner,'rho':rho,'primal_residual':rnorm,
                                'dual_residual':snorm,'eps_primal':epsp,'eps_dual':epsd,
                                'cg_max_relative_residual':float(cg_relative),
                                'max_power_violation_watt':float(np.maximum(
                                    power_by_trp(rs,as_v(z))-cfg.power_watt_per_trp,0).max()),
                                'fixed_uw_v_objective':_v_objective(rs,hs,masks,parts,as_v(z))})
            if rnorm<=epsp and snorm<=epsd and cg_relative<=max(1e-3,10*cfg.eps_rel):
                inner_converged=True;break
        mus=z
        trajectory[-1].update({'admm_iterations':inner,'admm_converged':inner_converged,
                               'admm_trace':inner_trace,
                               'primal_residual':rnorm,'dual_residual':snorm,
                               'eps_primal':epsp,'eps_dual':epsd})
        if not inner_converged:
            reason='inner_max_iterations';break
    vs=as_v(mus)
    final_states=[_state(h,np.zeros_like(r.error_var),v) for h,r,v in zip(hs,rs,vs)]
    receivers=[s[0] for s in final_states];weights=[s[1] for s in final_states]
    proxy=float(sum((_weight(r))*np.sum(s[2]) for r,s in zip(rs,final_states)))
    per_ue=_aggregate_user_rates(scene,rs,final_states)
    powers=power_by_trp(rs,vs)
    return Solution(vs,receivers,weights,proxy,trajectory,converged,reason,outer,
                    rnorm,snorm,epsp,epsd,float(max(np.maximum(powers-cfg.power_watt_per_trp,0))),
                    perf_counter()-start,'fixed_direction_power',proxy,
                    'fixed_direction_estimated_sum_rate_bits_per_s_hz',proxy,
                    per_ue.tolist(),[np.ones(len(r.users)).tolist() for r in rs])
