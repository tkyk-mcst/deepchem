"""
SELFIES mutation / crossover utilities for molecular optimization.
All operations stay within valid SELFIES grammar.
"""
import random
from typing import List, Optional, Tuple

import selfies as sf
from rdkit import Chem

# ── Alphabet ──────────────────────────────────────────────────────────────────
_BASE_ALPHABET = list(sf.get_semantic_robust_alphabet())
# Supplement with common drug-like tokens
_EXTRA = [
    "[C]", "[=C]", "[N]", "[=N]", "[O]", "[=O]", "[S]", "[=S]",
    "[F]", "[Cl]", "[Br]", "[I]", "[P]", "[#C]", "[#N]",
    "[Branch1]", "[Branch2]", "[Ring1]", "[Ring2]",
    "[C@@H1]", "[C@H1]", "[NH1]", "[NH2]", "[OH1]",
    "[CH2]", "[CH3]",
]
ALPHABET = list(set(_BASE_ALPHABET) | set(_EXTRA))


def selfies_to_list(selfies_str: str) -> List[str]:
    """Split SELFIES string into token list."""
    return list(sf.split_selfies(selfies_str))


def list_to_selfies(tokens: List[str]) -> str:
    return "".join(tokens)


def is_valid(selfies_str: str) -> bool:
    """Check if SELFIES decodes to a valid RDKit molecule."""
    try:
        smiles = sf.decoder(selfies_str)
        mol = Chem.MolFromSmiles(smiles)
        return mol is not None and mol.GetNumHeavyAtoms() >= 2
    except Exception:
        return False


def smiles_to_selfies_safe(smiles: str) -> Optional[str]:
    try:
        mol = Chem.MolFromSmiles(smiles)
        if mol is None:
            return None
        return sf.encoder(Chem.MolToSmiles(mol))
    except Exception:
        return None


# ── Mutation operators ─────────────────────────────────────────────────────────

def mutate_random_replacement(selfies_str: str, n_mutations: int = 1) -> str:
    """Replace n random tokens with random alphabet tokens."""
    tokens = selfies_to_list(selfies_str)
    if not tokens:
        return selfies_str
    for _ in range(n_mutations):
        idx = random.randrange(len(tokens))
        tokens[idx] = random.choice(ALPHABET)
    return list_to_selfies(tokens)


def mutate_insertion(selfies_str: str) -> str:
    """Insert one random token at a random position."""
    tokens = selfies_to_list(selfies_str)
    idx = random.randint(0, len(tokens))
    tokens.insert(idx, random.choice(ALPHABET))
    return list_to_selfies(tokens)


def mutate_deletion(selfies_str: str) -> str:
    """Delete one random token (if length > 1)."""
    tokens = selfies_to_list(selfies_str)
    if len(tokens) <= 1:
        return selfies_str
    idx = random.randrange(len(tokens))
    tokens.pop(idx)
    return list_to_selfies(tokens)


def mutate(selfies_str: str,
           n_mutations: int = 1,
           ops: Optional[List[str]] = None) -> str:
    """
    Apply a random mutation. ops can be a subset of
    ['replace', 'insert', 'delete'].
    Returns original string if mutant is invalid after max_tries.
    """
    if ops is None:
        ops = ["replace", "replace", "replace", "insert", "delete"]

    max_tries = 20
    for _ in range(max_tries):
        op = random.choice(ops)
        if op == "replace":
            candidate = mutate_random_replacement(selfies_str, n_mutations)
        elif op == "insert":
            candidate = mutate_insertion(selfies_str)
        else:
            candidate = mutate_deletion(selfies_str)

        if is_valid(candidate):
            return candidate

    return selfies_str  # fall back to original


# ── Crossover ─────────────────────────────────────────────────────────────────

def crossover_single_point(a: str, b: str) -> Tuple[str, str]:
    """Single-point crossover on SELFIES token lists."""
    ta = selfies_to_list(a)
    tb = selfies_to_list(b)
    if len(ta) < 2 or len(tb) < 2:
        return a, b
    pa = random.randint(1, len(ta) - 1)
    pb = random.randint(1, len(tb) - 1)
    c1 = list_to_selfies(ta[:pa] + tb[pb:])
    c2 = list_to_selfies(tb[:pb] + ta[pa:])
    return c1, c2


def crossover(a: str, b: str,
              validate: bool = True) -> Tuple[str, str]:
    """Crossover with validity check; falls back to parents on failure."""
    c1, c2 = crossover_single_point(a, b)
    if validate:
        if not is_valid(c1):
            c1 = a
        if not is_valid(c2):
            c2 = b
    return c1, c2


# ── Population helpers ────────────────────────────────────────────────────────

def random_individual(length: int = 12) -> str:
    """Generate a random (not necessarily valid) SELFIES string."""
    for _ in range(100):
        tokens = [random.choice(ALPHABET) for _ in range(length)]
        candidate = list_to_selfies(tokens)
        if is_valid(candidate):
            return candidate
    # fallback: return aspirin SELFIES
    return "[C][C](=[O])[O][c]1[cH][cH][cH][cH][c]1[C](=[O])[OH]"


def seed_population(seeds: List[str], pop_size: int,
                    mutation_rate: float = 0.3) -> List[str]:
    """
    Build an initial population by:
    1. Including all valid seeds
    2. Filling remaining slots with mutants of seeds
    """
    population: List[str] = []
    valid_seeds = [s for s in seeds if is_valid(s)]

    for s in valid_seeds:
        population.append(s)
        if len(population) >= pop_size:
            return population[:pop_size]

    while len(population) < pop_size:
        parent = random.choice(valid_seeds) if valid_seeds else random_individual()
        child = mutate(parent)
        population.append(child)

    return population
