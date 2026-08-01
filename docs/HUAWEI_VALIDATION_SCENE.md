# Huawei Validation Scene Configuration

This document records the challenge-material validation parameters that are
now represented by `cf_default_config('huawei')`.

## Implemented Configuration Fields

| Category | Parameter | Value |
|---|---|---|
| Topology | Sites and cells | 7 sites, 3 cells per site |
| Topology | DU/TRP count | 21 sectors |
| Antenna | Base-station antennas | 64TRX |
| Antenna | Array shape | 8 horizontal x 4 vertical x 2 polarization |
| Antenna | Element spacing | 0.5 wavelength |
| UE | UE antenna type | 2T4R, modeled with 4 Rx antennas |
| UE | User distribution | 10-20 UE/cell, represented by 315 total UE |
| Traffic | Load | 30% |
| Traffic | Model | Burst |
| Traffic | PRB utilization | 30%-50% |
| Traffic | Tail data fraction | about 30% |
| Traffic | Tail TTI fraction | about 60% |
| Mobility | Speed | 3 km/h |
| Channel | Frequency | 2.6 GHz / 3.5 GHz |
| Channel | Model label | TR 38.901 UMi/UMa |
| Channel | Inter-site distance | 300 m |
| Bandwidth | Bandwidth | 100 MHz |
| Bandwidth | OFDM numerology | 30 kHz SCS, 273 RB |
| SRS | Channel estimate types | ideal / nonideal |
| SRS | Period | 340 TTI |
| SRS | Hopping | 17 hops, 20 ms hop period |
| SRS | RB per hop | 16 RB, last hop 17 RB |
| CSI-RS | Period | 40 TTI |
| Rank | Measurement rank | adaptive |
| Receiver | UE receiver | IRC |

## Current Scope

This commit adds the scenario configuration and a 7-site sectorized geometry
layout. It does not yet implement the full validation physics:

- burst traffic experience-rate calculation;
- 3GPP ThpVolDl / ThpTimeDl head-tail trimming;
- SRS hopping measurement error and `H_true` / `H_est`;
- CSI-RS periodic measurement behavior;
- full TR 38.901 UMi/UMa channel equations;
- IRC receiver processing.

Those items should be added before final Huawei-scene performance claims.
