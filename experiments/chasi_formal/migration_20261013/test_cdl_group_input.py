"""Read the isolated MIT CDL adapter without copying or modifying it."""
from pathlib import Path
import importlib.util
import numpy as np
from cdl_group_input import cdl_group_h

source=Path(r'C:\Users\sypxx\Documents\CF mMIMO TRP\chasi_tr38901_staging\chasi_formal_implementation\tr38901_cdl.py')
if not source.exists():
    raise FileNotFoundError(f'isolated CDL source unavailable: {source}')
spec=importlib.util.spec_from_file_location('isolated_chasi_cdl',source)
module=importlib.util.module_from_spec(spec)
import sys
sys.modules[spec.name]=module
spec.loader.exec_module(module)
links=np.empty((1,2),dtype=object)
for l in range(2):
    links[0,l]=module.make_link('CDL-A',3.5e9,(0.,0.),(60.+l*5.,20.),0.,
                                velocity_xy=(.8,.3),seed=700+l)
gain=np.array([[.02,.04]])
a=cdl_group_h(links,gain,32,16,30e3,0.)
b=cdl_group_h(links,gain,32,16,30e3,0.)
c=cdl_group_h(links,gain,48,16,30e3,.02)
assert a.shape==(1,2,4,64)
np.testing.assert_array_equal(a,b)
assert np.linalg.norm(a-c)>1e-4
print('PASS: isolated CDL-A group-center H shape, deterministic repeat, frequency/time change')
