"""Compare fixed-U/W matrix quadratic arrays from Python and MATLAB."""
from pathlib import Path
import json
import numpy as np
from scipy.io import loadmat

HERE=Path(__file__).resolve().parent
names=('rank1_nominal','rank2_nominal','rank2_uniform',
       'rank2_relative','rank2_statistical')
report={}
for name in names:
    matlab=loadmat(HERE/f'{name}_matlab_operator.mat',simplify_cells=True)['fixed_uw_probe']
    python=np.load(HERE/f'{name}_python_operator.npz')
    record={}
    for field in ('M','B','D','QV'):
        record[field]=0.0
        for g in range(2):
            expected=python[f'{field}{g}']
            actual=np.asarray(matlab[g][field]).reshape(expected.shape)
            record[field]=max(record[field],float(np.max(abs(actual-expected))))
        assert record[field]<1e-8,(name,field,record[field])
    report[name]=record
(HERE/'operator_comparison.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('PASS fixed-U/W M, B, error diagonal and Q(V) on all five fixtures')
print('max error:',max(max(v.values()) for v in report.values()))
