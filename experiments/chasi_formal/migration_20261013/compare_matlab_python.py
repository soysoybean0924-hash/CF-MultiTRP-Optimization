"""Same-input numerical comparison of MATLAB port and Python reference."""
from pathlib import Path
from types import SimpleNamespace
import json
import sys
import numpy as np
from scipy.io import loadmat

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(ROOT))
from chasi_formal_implementation import solver as ref  # noqa: E402

inp = loadmat(HERE / 'matlab_fixture_input.mat', simplify_cells=True)
got = loadmat(HERE / 'matlab_fixture_output.mat', simplify_cells=True)['out']
raw = inp['resources']
resources = [SimpleNamespace(**r) for r in np.ravel(raw)]
vs = [np.asarray(v)[..., None] for v in np.ravel(inp['initialV'])]
cfg = inp['cfg']
def weight(r):
    return r.tx_rb_count / 273

states = [ref._state(r.H, r.C, v) for r, v in zip(resources, vs)]
state_errors = []
for g, (r, v, (u, w, rate)) in enumerate(zip(resources, vs, states)):
    # MATLAB output is after two updates; initial states are checked via
    # the first stored MATLAB trajectory objective and independent formulas.
    state_errors.append(float(np.max(np.abs(w - w.conj().transpose(0, 2, 1)))))
initial_obj = sum(weight(r) * s[2].sum() for r, s in zip(resources, states))
traj = got['trajectory']
if isinstance(traj, dict):
    traj = [traj]
objective_errors = [abs(initial_obj - traj[0]['objective'])]
admm_records = []
for outer in range(cfg['outer_iterations']):
    states = [ref._state(r.H, r.C, v) for r, v in zip(resources, vs)]
    parts = [ref._quadratic_parts(r.H, r.C, s[0], s[1], v.shape)
             for r, s, v in zip(resources, states, vs)]
    nxt, history, converged = ref._solve_v_admm(
        resources, [r.H for r in resources], [r.serve for r in resources],
        parts, vs, cfg['budget'], cfg['admm_iterations'],
        cfg['cg_iterations'], cfg['eps_abs'], cfg['eps_rel'], rho=0.05)
    admm_records.append({'iterations': len(history), 'converged': converged,
                         'primal': history[-1]['primal_residual'],
                         'dual': history[-1]['dual_residual']})
    vs = nxt
    states = [ref._state(r.H, r.C, v) for r, v in zip(resources, vs)]
    objective_errors.append(abs(sum(weight(r) * s[2].sum()
                                    for r, s in zip(resources, states))
                                - traj[outer + 1]['objective']))
mat_v = [np.asarray(v)[..., None] for v in np.ravel(got['V'])]
v_error = max(float(np.max(np.abs(a - b))) for a, b in zip(vs, mat_v))
power_error = float(np.max(np.abs(ref.power_by_trp(resources, vs) - got['power'])))
result = {'objective_absolute_errors': objective_errors,
          'max_v_entry_absolute_error': v_error,
          'power_absolute_error_watt': power_error,
          'python_admm': admm_records,
          'matlab_objectives': [float(x['objective']) for x in traj],
          'matlab_power_watt': np.asarray(got['power']).tolist(),
          'max_w_hermitian_error': max(state_errors)}
(HERE / 'matlab_python_comparison.json').write_text(
    json.dumps(result, indent=2), encoding='utf-8')
print(json.dumps(result, indent=2))
assert max(objective_errors) < 1e-6
assert v_error < 1e-5
assert power_error < 1e-7
