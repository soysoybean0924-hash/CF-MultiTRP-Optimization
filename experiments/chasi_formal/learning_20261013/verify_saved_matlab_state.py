"""Read already saved MATLAB input/output; compare final U/W/rate to Python.

No solver run, no change to the historical fixture or MATLAB implementation.
"""
from pathlib import Path
from types import SimpleNamespace
import json
import sys
import numpy as np
from scipy.io import loadmat

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
SOURCE=ROOT/'experiments/chasi_formal/migration_20261013'
sys.path.insert(0,str(ROOT))
from chasi_formal_implementation import solver  # noqa: E402

inp=loadmat(SOURCE/'matlab_fixture_input.mat',simplify_cells=True)
out=loadmat(SOURCE/'matlab_fixture_output.mat',simplify_cells=True)['out']
resources=[SimpleNamespace(**r) for r in np.ravel(inp['resources'])]
vs=[np.asarray(v)[...,None] for v in np.ravel(out['V'])]
errors=[]
for r,v,mu,mw,mrate in zip(resources,vs,np.ravel(out['U']),np.ravel(out['W']),np.ravel(out['rate'])):
    u,w,rate=solver._state(r.H,r.C,v)
    errors.append({'U_max_abs':float(np.max(np.abs(u-np.asarray(mu)[...,None]))),
                   'W_max_abs':float(np.max(np.abs(w-np.asarray(mw)[:,None,None]))),
                   'rate_max_abs_bits_per_s_hz':float(np.max(np.abs(rate-np.asarray(mrate))))})
result={'scope':'final saved two-TRP rank-one fixture state, no new optimizer run',
        'per_resource':errors,
        'max_U_abs':max(r['U_max_abs'] for r in errors),
        'max_W_abs':max(r['W_max_abs'] for r in errors),
        'max_rate_abs_bits_per_s_hz':max(r['rate_max_abs_bits_per_s_hz'] for r in errors)}
assert max(result[k] for k in ('max_U_abs','max_W_abs','max_rate_abs_bits_per_s_hz'))<1e-10
(HERE/'saved_matlab_state_check.json').write_text(json.dumps(result,indent=2),encoding='utf8')
print(json.dumps(result,indent=2))
