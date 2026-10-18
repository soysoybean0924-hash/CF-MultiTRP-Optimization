"""Executable Chasi scene contract. Values not on the three task images are assumptions."""
from dataclasses import dataclass, asdict
from math import ceil


@dataclass
class Config:
    users_per_cell: int = 10
    seed: int = 20261011
    rank: int = 2
    solver: str = "matrix_statistical"
    outer_iterations: int = 2
    admm_iterations: int = 12
    cg_iterations: int = 8
    power_watt_per_trp: float = 20.0
    noise_watt_per_rb: float = 1e-10
    pilot_snr_db: float = -10.0
    srs_mode: str = "awgn_independent"  # or pilot_reuse_gaussian; latter is synthetic, equal-power reuse
    srs_pilot_sequences: int = 8  # assumption, not inferred from 16-RB hop width
    csi_rs_snr_db: float = -3.0  # implementation assumption: DL feedback quality
    srs_ue_tx_to_rx_rows: tuple = (0, 1)  # 2 UL Tx ports map to 2 of 4 DL Rx spatial rows
    age_coherence_ms: float = 120.0
    prb_utilization: float = 0.40
    schedule_mode: str = "legacy_random_full_groups"  # precise_shared_rb permits a partial group
    traffic_load: float = 0.30
    traffic_model: str = "legacy_bursts"  # or target_busy_fraction; explicit UE×TTI duty definition
    users_per_active_cell_rb: int = 0  # auto: 2/3/4 for 10/15/20 UE per cell
    speed_kmh: float = 3.0
    duration_tti: int = 340
    decision_tti: int = 340
    tti_ms: float = 1.0  # assumption: task image gives TTI count and 20 ms hop
    service_trps: int = 2
    frequency_ghz: float = 3.5
    channel_mode: str = "geometry_correlated_surrogate"  # or umi_pathloss_subset / uma_pathloss_subset
    max_interference_distance_m: float = 750.0
    eps_abs: float = 1e-5
    eps_rel: float = 1e-4
    outer_rel_tol: float = 1e-4
    outer_precoder_rel_tol: float = 5e-3
    pf_rate_floor_bits_per_s_hz: float = 1e-2  # utility log(1 + aggregate UE rate / floor)
    initialization_mode: str = "svd"  # optional controlled initial-V sensitivity
    initialization_seed: int = 0

    sites: int = 7
    sectors_per_site: int = 3
    trps: int = 21
    tx_ports: int = 64
    ue_rx_ports: int = 4
    ue_tx_ports: int = 2
    rb_total: int = 273
    bandwidth_hz: float = 100e6
    scs_hz: float = 30e3
    srs_period_tti: int = 340
    srs_hops: int = 17
    csi_rs_period_tti: int = 40

    def __post_init__(self):
        if self.users_per_active_cell_rb == 0:
            self.users_per_active_cell_rb = ceil(self.users_per_cell/5)

    def validate(self):
        assert self.users_per_cell in (10, 15, 20)
        assert 1 <= self.rank <= min(self.tx_ports, self.ue_rx_ports)
        assert self.trps == self.sites * self.sectors_per_site
        assert self.rb_total == 16 * 16 + 17
        assert 0.30 <= self.prb_utilization <= 0.50
        assert self.schedule_mode in ("legacy_random_full_groups","precise_shared_rb")
        assert self.solver in ("matrix_statistical", "matrix_edge_weighted",
                               "matrix_pf_nominal", "matrix_pf_uniform",
                               "matrix_pf_uniform_relative", "matrix_pf_statistical",
                               "matrix_nominal", "ideal", "no_cooperation",
                               "fixed_direction_power")
        assert self.channel_mode in ("geometry_correlated_surrogate","umi_pathloss_subset","uma_pathloss_subset")
        assert self.duration_tti >= self.srs_period_tti
        assert 0 <= self.decision_tti <= self.duration_tti
        assert 1 <= self.service_trps <= self.trps
        assert 1 <= self.users_per_active_cell_rb <= self.tx_ports//self.rank
        assert len(self.srs_ue_tx_to_rx_rows)==self.ue_tx_ports
        assert len(set(self.srs_ue_tx_to_rx_rows))==self.ue_tx_ports
        assert all(0<=x<self.ue_rx_ports for x in self.srs_ue_tx_to_rx_rows)
        assert self.eps_abs > 0 and self.eps_rel > 0
        assert self.outer_rel_tol > 0 and self.outer_precoder_rel_tol > 0
        assert self.pf_rate_floor_bits_per_s_hz > 0
        assert self.initialization_mode in ("svd", "home_biased", "jittered")
        assert self.srs_mode in ("awgn_independent", "pilot_reuse_gaussian")
        assert 1 <= self.srs_pilot_sequences <= self.users
        assert self.traffic_model in ("legacy_bursts", "target_busy_fraction")
        assert 0 < self.traffic_load < 1

    @property
    def users(self):
        return self.trps * self.users_per_cell

    @property
    def rb_groups(self):
        return [(16*i, 16) for i in range(16)] + [(256, 17)]

    def as_dict(self):
        return asdict(self)
