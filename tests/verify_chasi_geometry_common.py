"""Check MATLAB/Python topology on identical explicit uniform arrays."""
import sys
from pathlib import Path
import numpy as np
from scipy.io import loadmat
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from chasi_formal_implementation.config import Config
from chasi_formal_implementation.scenario import _geometry_from_samples


def main(path):
    data=loadmat(path,simplify_cells=True)
    cfg=Config(users_per_cell=10)
    sites, ue, home=_geometry_from_samples(
        cfg, data['angleUniform'].T, data['radiusUniform'].T)
    errors={
        'trp_xy_m':float(np.max(np.abs(sites-data['trpXy']))),
        'ue_xy_m':float(np.max(np.abs(ue-data['ueXy']))),
        'home_id':int(np.max(np.abs(home+1-data['homeTrp'].ravel()))),
    }
    print(errors)
    assert errors['trp_xy_m']<1e-10
    assert errors['ue_xy_m']<1e-10
    assert errors['home_id']==0


if __name__=='__main__':main(sys.argv[1])
