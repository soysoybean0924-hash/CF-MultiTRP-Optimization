"""Check same-input initial and two-outer-step Python/MATLAB parity."""
from pathlib import Path
import json
import numpy as np
from scipy.io import loadmat

HERE=Path(__file__).resolve().parent
reference=json.loads((HERE/'python_reference.json').read_text(encoding='utf-8'))
report={}
for name,observations in reference.items():
    report[name]={}
    for outer in (0,2):
        py=observations[str(outer)]
        mat=loadmat(HERE/f'{name}_matlab_outer{outer}.mat',simplify_cells=True)['out']
        arrays=np.load(HERE/f'{name}_python_outer{outer}.npz')
        entry={'objective_abs':abs(float(mat['optimization_objective'])-py['objective']),
               'estimated_sum_abs':abs(float(mat['estimated_sum_rate'])-py['estimated_sum']),
               'true_sum_abs':abs(float(mat['true_sum_rate'])-py['true_sum']),
               'power_max_abs':float(np.max(abs(np.asarray(mat['power']).ravel()-py['power']))),
               'V_max_abs':0.,'U_max_abs':0.,'W_max_abs':0.,
               'reason_match':str(mat['reason'])==py['reason'],
               'trajectory_objective_max_abs':0.,'accepted_step_max_abs':0.,
               'admm_primal_max_abs':0.,'admm_dual_max_abs':0.}
        for axis in ('V','U','W'):
            for g in range(2):
                expected=arrays[f'{axis}{g}']
                actual=np.asarray(mat[axis][g]).reshape(expected.shape)
                diff=np.max(abs(actual-expected))
                entry[f'{axis}_max_abs']=max(entry[f'{axis}_max_abs'],float(diff))
        mt=mat['trajectory']
        if isinstance(mt,dict):mt=[mt]
        if len(mt)!=len(py['trajectory']):raise AssertionError('trajectory length')
        for m,p in zip(mt,py['trajectory']):
            entry['trajectory_objective_max_abs']=max(entry['trajectory_objective_max_abs'],
                abs(float(m['objective'])-p['objective']))
            if p['accepted_step'] is not None:
                entry['accepted_step_max_abs']=max(entry['accepted_step_max_abs'],
                    abs(float(m['accepted_step'])-p['accepted_step']))
                last=m['admm_last']
                entry['admm_primal_max_abs']=max(entry['admm_primal_max_abs'],
                    abs(float(last['primal'])-p['primal']))
                entry['admm_dual_max_abs']=max(entry['admm_dual_max_abs'],
                    abs(float(last['dual'])-p['dual']))
        report[name][str(outer)]=entry
        assert entry['objective_abs']<1e-6 and entry['true_sum_abs']<1e-6
        assert entry['power_max_abs']<1e-6 and entry['V_max_abs']<1e-5
        assert entry['U_max_abs']<1e-5 and entry['W_max_abs']<1e-4
        assert entry['admm_primal_max_abs']<1e-4 and entry['admm_dual_max_abs']<1e-4
        assert entry['accepted_step_max_abs']==0 and entry['reason_match']
(HERE/'comparison.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('PASS: 5 cases x initial/final, PF, true rate, power, V/U/W, ADMM ends, acceptance')
print('max V abs:',max(v['2']['V_max_abs'] for v in report.values()))
