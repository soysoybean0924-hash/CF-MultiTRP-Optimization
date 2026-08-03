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
| Edge UE | Classification | M3-style large-scale pathloss delta, 3 dB |

## Current Scope

The current implementation adds the scenario configuration, a 7-site
sectorized geometry layout, a lightweight burst-traffic trace, and an
experience-rate metric compatible with the `ThpVolDl / ThpTimeDl` definition.
The burst trace records per-UE non-empty buffer samples, burst identifiers,
tail-packet samples, and PRB-utilization targets. Experience-rate calculation
excludes idle samples and removes tail samples before computing the user
experience-rate CDF and bottom-5% edge rate.

The scenario also contains a first SRS nonideal measurement model:

- `scenario.H_true`: validation channel;
- `scenario.H_est`: scheduler-visible channel estimate;
- `scenario.H`: currently points to `H_est` for backward compatibility;
- `scenario.srs.SrsPresinrDb`: TRP/UE/RB SRS Presinr;
- `scenario.srs.SrsMeasuredMask`: RBs covered by the SRS hopping snapshot;
- `scenario.srs.ErrorVariance`: channel-estimation uncertainty used to form
  `H_est`.
- `scenario.edge.EdgeUserMask`: M3-style cell-edge users whose long-term
  pathloss to at least two TRPs is within the configured threshold;
- `scenario.edge.NonEdgeUserMask`: users kept on their primary TRP by default;
- `scenario.edge.ServingMask`: candidate serving TRPs used to limit the
  initial association search space.

The edge classification follows the M3 scheduler idea: cell-edge users are
the only users allowed to start with multi-TRP joint-transmission candidates,
while non-edge users start from their primary TRP and can be used for
single-TRP/MU-MIMO-style scheduling diagnostics. Huawei acceptance metrics
still use the 3GPP-style experience-rate CDF and bottom-5% rate, so the M3
classification is a scheduling-space reduction mechanism rather than a
replacement for the final edge-experience KPI.

The robust beam-weight update uses SRS uncertainty during the inner loop by
shrinking high-uncertainty effective channels and adding an uncertainty
penalty, then reports validation metrics on `H_true`.

It does not yet implement the full validation physics:

- packet-level burst arrivals with queue evolution;
- CSI-RS periodic measurement behavior;
- full TR 38.901 UMi/UMa channel equations;
- IRC receiver processing.

Those items should be added before final Huawei-scene performance claims.
