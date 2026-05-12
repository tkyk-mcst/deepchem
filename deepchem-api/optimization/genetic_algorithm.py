"""
Single-objective Genetic Algorithm for molecular optimization using SELFIES.
Supports maximize / minimize / target modes for any property in compute_fast().
"""
import random
from typing import Callable, Dict, List, Optional, Tuple

from .selfies_utils import crossover, mutate, seed_population, is_valid


Molecule = str  # SELFIES string
ScoreFn = Callable[[str], float]  # SELFIES → scalar score


def _tournament_select(pop: List[Molecule],
                        scores: List[float],
                        k: int = 3) -> Molecule:
    idxs = random.sample(range(len(pop)), min(k, len(pop)))
    best = max(idxs, key=lambda i: scores[i])
    return pop[best]


def make_score_fn(fitness_config: Dict,
                  compute_fn: Callable) -> ScoreFn:
    """
    fitness_config example:
      {
        "qed":        {"mode": "maximize", "weight": 1.0},
        "sa_score":   {"mode": "minimize", "weight": 0.5},
        "logP":       {"mode": "target",   "target": 2.5, "weight": 0.8},
      }
    mode: 'maximize' | 'minimize' | 'target'
    """
    configs = fitness_config

    def _score(selfies_str: str) -> float:
        props = compute_fn(selfies_str)
        if not props.get("valid", False):
            return -1e9
        total = 0.0
        for prop_name, cfg in configs.items():
            val = props.get(prop_name)
            if val is None:
                continue
            mode   = cfg.get("mode", "maximize")
            weight = cfg.get("weight", 1.0)
            if mode == "maximize":
                contrib = float(val)
            elif mode == "minimize":
                contrib = -float(val)
            else:  # target
                tgt = float(cfg.get("target", 0.0))
                contrib = -abs(float(val) - tgt)
            total += weight * contrib
        return total

    return _score


def run_ga(
    seeds: List[str],
    score_fn: ScoreFn,
    pop_size: int = 50,
    n_generations: int = 30,
    crossover_prob: float = 0.5,
    mutation_rate: float = 0.3,
    elitism: int = 5,
    progress_cb: Optional[Callable[[int, int, float, str], None]] = None,
) -> List[Dict]:
    """
    Run a genetic algorithm.

    progress_cb(generation, total_generations, best_score, best_selfies)

    Returns a list of dicts sorted by score (best first):
      [{"selfies": ..., "smiles": ..., "score": ..., "generation": ...}, ...]
    """
    import selfies as sf
    from rdkit import Chem

    def _to_smiles(sel):
        try:
            mol = Chem.MolFromSmiles(sf.decoder(sel))
            return Chem.MolToSmiles(mol) if mol else ""
        except Exception:
            return ""

    # ── initialise population ────────────────────────────────────────────────
    population = seed_population(seeds, pop_size, mutation_rate)
    scores = [score_fn(ind) for ind in population]

    hall_of_fame: List[Tuple[float, str]] = []  # (score, selfies)

    for gen in range(n_generations):
        # ── elitism: keep top-k ──────────────────────────────────────────────
        elite_idxs = sorted(range(len(scores)),
                             key=lambda i: scores[i], reverse=True)[:elitism]
        elites = [population[i] for i in elite_idxs]
        elite_scores = [scores[i] for i in elite_idxs]

        # Update hall of fame
        for s, ind in zip(elite_scores, elites):
            hall_of_fame.append((s, ind))
        hall_of_fame.sort(key=lambda x: x[0], reverse=True)
        hall_of_fame = hall_of_fame[:pop_size]  # cap size

        # ── breed next generation ────────────────────────────────────────────
        new_pop = list(elites)
        while len(new_pop) < pop_size:
            p1 = _tournament_select(population, scores)
            if random.random() < crossover_prob:
                p2 = _tournament_select(population, scores)
                c1, c2 = crossover(p1, p2)
                children = [c1, c2]
            else:
                children = [p1]

            for child in children:
                if random.random() < mutation_rate:
                    child = mutate(child)
                if is_valid(child) and len(new_pop) < pop_size:
                    new_pop.append(child)

        population = new_pop
        scores = [score_fn(ind) for ind in population]

        best_idx = max(range(len(scores)), key=lambda i: scores[i])
        if progress_cb:
            progress_cb(gen + 1, n_generations,
                        scores[best_idx], population[best_idx])

    # ── collect unique results ────────────────────────────────────────────────
    seen_smiles = set()
    results = []
    for score, sel in hall_of_fame:
        smiles = _to_smiles(sel)
        if smiles and smiles not in seen_smiles:
            seen_smiles.add(smiles)
            results.append({
                "selfies": sel,
                "smiles": smiles,
                "score": round(score, 4),
                "method": "GA",
            })

    return results[:pop_size]
