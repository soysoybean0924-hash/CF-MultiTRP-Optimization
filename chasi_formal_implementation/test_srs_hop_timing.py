"""Reference scene must use its configured SRS hop interval, not 20 TTI."""
from .config import Config
from .scenario import generate
from .time_evolution import simulate
from types import SimpleNamespace
import numpy as np


def main():
    cfg = Config(users_per_cell=10, srs_period_tti=170,
                 duration_tti=170, decision_tti=170)
    scene = generate(cfg)
    assert scene.events[10]["srs_group"] == 1
    assert scene.events[20]["srs_group"] == 2
    assert scene.resources[0].age_ms == 0
    assert scene.resources[1].age_ms == 160
    assert scene.resources[2].age_ms == 150
    zero_beams = [np.zeros((21, len(r.users), 64, cfg.rank), complex)
                  for r in scene.resources]
    replay = simulate(scene, SimpleNamespace(precoders=zero_beams),
                      window_tti=170, fast_period_tti=10,
                      slow_period_tti=170, beam_policy="frozen")
    assert len(replay["events"]) == 17
    assert [x["tti"] for x in replay["events"][:3]] == [0,10,20]
    assert [x["srs_group"] for x in replay["events"][:3]] == [0,1,2]
    try:
        Config(srs_period_tti=171).validate()
    except AssertionError:
        pass
    else:
        raise AssertionError("nonintegral SRS hop interval was accepted")
    print("PASS reference configured SRS hop timing")


if __name__ == "__main__":
    main()
