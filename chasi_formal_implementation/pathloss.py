"""TR 38.901 v18 Table 7.4.1-1 / 7.4.2-1 outdoor pathloss subset.

LOS probability, LOS/NLOS distance loss and shadowing only. The full 7.5
clustered fast-fading model, O2I, blockage and spatial consistency are absent.
Source: ETSI TR 138 901 V18.0.0, pp. 28-30.
"""
import numpy as np


def outdoor_pathloss_db(d2d_m, fc_ghz, scenario, los, h_ut=1.5):
    if scenario not in ('umi','uma') or not (0.5 <= fc_ghz <= 100):
        raise ValueError('supported: UMi/UMa at 0.5..100 GHz')
    d2d=max(float(d2d_m),10.0)
    h_bs=10.0 if scenario=='umi' else 25.0
    d3d=np.hypot(d2d,h_bs-h_ut)
    breakpoint=4*(h_bs-1)*(h_ut-1)*fc_ghz*1e9/3e8
    if scenario=='umi':
        los1=32.4+21*np.log10(d3d)+20*np.log10(fc_ghz)
        los2=32.4+40*np.log10(d3d)+20*np.log10(fc_ghz) - 9.5*np.log10(breakpoint**2+(h_bs-h_ut)**2)
        los_pl=los1 if d2d<=breakpoint else los2
        nlos_pl=max(los_pl,35.3*np.log10(d3d)+22.4+21.3*np.log10(fc_ghz)-0.3*(h_ut-1.5))
    else:
        los1=28.0+22*np.log10(d3d)+20*np.log10(fc_ghz)
        los2=28.0+40*np.log10(d3d)+20*np.log10(fc_ghz) - 9*np.log10(breakpoint**2+(h_bs-h_ut)**2)
        los_pl=los1 if d2d<=breakpoint else los2
        nlos_pl=max(los_pl,13.54+39.08*np.log10(d3d)+20*np.log10(fc_ghz)-0.6*(h_ut-1.5))
    return float(los_pl if los else nlos_pl)


def los_probability(d2d_m, scenario, h_ut=1.5):
    d=max(float(d2d_m),0.0)
    if d<=18:return 1.0
    a=18/d
    if scenario=='umi':return float(a+(1-a)*np.exp(-d/36))
    if scenario=='uma':
        c=0.0 if h_ut<=13 else ((h_ut-13)/10)**1.5
        return float((a+(1-a)*np.exp(-d/63))*(1+c*(5/4)*(d/100)**3*np.exp(-d/150)))
    raise ValueError('scenario must be umi or uma')
