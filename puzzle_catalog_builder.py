#!/usr/bin/env python3
"""
Sudoku puzzle generator for the Sudoku iOS app.
Generates puzzles.json with puzzles classified by difficulty.

Difficulty levels and techniques:
  - easy:    Naked Singles only
  - medium:  + Hidden Singles
  - hard:    + Naked Pairs/Triples/Quads, Pointing Pairs, Box/Line Reduction
  - expert:  + Hidden Pairs/Triples/Quads, X-Wing, Skyscraper,
               Simple Coloring, Unique Rectangle
  - extreme: + Swordfish, Jellyfish, Finned X-Wing, XY-Wing, XYZ-Wing,
               WXYZ-Wing, or bifurcation (trial & error)

Optimizations vs naive approach:
  - Fast uniqueness checker using constraint propagation + backtracking
  - Difficulty checked only once after all cells removed (not per-removal)
  - Multiprocessing across all CPU cores
"""

import json
import random
import time
import signal
import argparse
import sys
import os
from itertools import combinations
from multiprocessing import Pool, cpu_count, Manager

# ---------------------------------------------------------------------------
# Grid utilities (precomputed)
# ---------------------------------------------------------------------------

def _compute_peers(r, c):
    result = set()
    for i in range(9):
        result.add((r, i))
        result.add((i, c))
    br, bc = (r // 3) * 3, (c // 3) * 3
    for dr in range(3):
        for dc in range(3):
            result.add((br + dr, bc + dc))
    result.discard((r, c))
    return result

PEERS = [[_compute_peers(r, c) for c in range(9)] for r in range(9)]

# Flat peers indexed by cell index (0-80) for fast uniqueness check
PEERS_FLAT = []
for r in range(9):
    for c in range(9):
        PEERS_FLAT.append(frozenset(pr * 9 + pc for pr, pc in PEERS[r][c]))

ROWS = [[(r, c) for c in range(9)] for r in range(9)]
COLS = [[(r, c) for r in range(9)] for c in range(9)]
BOXES = []
for br in range(3):
    for bc in range(3):
        BOXES.append([(br*3+dr, bc*3+dc) for dr in range(3) for dc in range(3)])
ALL_UNITS = ROWS + COLS + BOXES

BOX_OF = [[0]*9 for _ in range(9)]
for idx, box in enumerate(BOXES):
    for r, c in box:
        BOX_OF[r][c] = idx

# ---------------------------------------------------------------------------
# Fast grid generation
# ---------------------------------------------------------------------------

def generate_complete_grid():
    grid = [0] * 81
    if _fill_fast(grid, 0):
        return grid
    return generate_complete_grid()

def _fill_fast(grid, pos):
    if pos == 81:
        return True
    digits = list(range(1, 10))
    random.shuffle(digits)
    peers = PEERS_FLAT[pos]
    used = set()
    for p in peers:
        if grid[p] != 0:
            used.add(grid[p])
    for d in digits:
        if d not in used:
            grid[pos] = d
            if _fill_fast(grid, pos + 1):
                return True
            grid[pos] = 0
    return False

# ---------------------------------------------------------------------------
# Fast uniqueness check with constraint propagation
# ---------------------------------------------------------------------------

def has_unique_solution(grid_flat):
    """Check if puzzle has exactly one solution. Uses constraint propagation
    + backtracking. Returns True if unique."""
    # Represent candidates as bitmasks for speed
    cands = [0x1FF] * 81  # bits 0-8 represent digits 1-9
    # Place given digits
    for i in range(81):
        if grid_flat[i] != 0:
            cands[i] = 0
            bit = 1 << (grid_flat[i] - 1)
            for p in PEERS_FLAT[i]:
                cands[p] &= ~bit

    count = [0]
    _unique_bt(grid_flat[:], cands, count)
    return count[0] == 1

def _unique_bt(grid, cands, count):
    # Propagate naked singles
    changed = True
    assigned = []
    while changed:
        changed = False
        for i in range(81):
            if grid[i] == 0 and cands[i] != 0:
                b = cands[i]
                if b & (b - 1) == 0:  # exactly one bit set
                    d = b.bit_length()
                    grid[i] = d
                    cands[i] = 0
                    bit = 1 << (d - 1)
                    for p in PEERS_FLAT[i]:
                        cands[p] &= ~bit
                    assigned.append(i)
                    changed = True
                elif b == 0:
                    # Contradiction - undo
                    for ai in assigned:
                        grid[ai] = 0
                    return

    # Check if solved
    if all(grid[i] != 0 for i in range(81)):
        count[0] += 1
        for ai in assigned:
            grid[ai] = 0
        return

    if count[0] >= 2:
        for ai in assigned:
            grid[ai] = 0
        return

    # Find MRV cell
    best_i = -1
    best_cnt = 10
    for i in range(81):
        if grid[i] == 0:
            bc = bin(cands[i]).count('1')
            if bc == 0:
                for ai in assigned:
                    grid[ai] = 0
                return
            if bc < best_cnt:
                best_cnt = bc
                best_i = i

    # Branch
    save_grid = grid[:]
    save_cands = cands[:]
    b = cands[best_i]
    while b:
        lowest = b & (-b)
        d = lowest.bit_length()
        # Restore state
        for k in range(81):
            grid[k] = save_grid[k]
            cands[k] = save_cands[k]
        grid[best_i] = d
        cands[best_i] = 0
        bit = 1 << (d - 1)
        for p in PEERS_FLAT[best_i]:
            cands[p] &= ~bit
        _unique_bt(grid, cands, count)
        if count[0] >= 2:
            break
        b &= b - 1

    # Restore for caller
    for k in range(81):
        grid[k] = save_grid[k]
        cands[k] = save_cands[k]
    for ai in assigned:
        grid[ai] = 0

# ---------------------------------------------------------------------------
# Puzzle creation: remove cells, then classify
# ---------------------------------------------------------------------------

def remove_cells(grid_flat, target_clues):
    """Remove cells from a complete grid down to target_clues, ensuring uniqueness."""
    puzzle = grid_flat[:]
    positions = list(range(81))
    random.shuffle(positions)
    clues = 81

    for pos in positions:
        if clues <= target_clues:
            break
        if puzzle[pos] == 0:
            continue
        old = puzzle[pos]
        puzzle[pos] = 0
        if has_unique_solution(puzzle):
            clues -= 1
        else:
            puzzle[pos] = old

    return puzzle, clues

# ---------------------------------------------------------------------------
# Solver state for technique-based classification
# ---------------------------------------------------------------------------

LEVEL_ORDER = {'easy': 0, 'medium': 1, 'hard': 2, 'expert': 3, 'extreme': 4, 'diabolic': 5}

class SolverState:
    __slots__ = ('grid', 'candidates')

    def __init__(self, grid_flat):
        self.grid = list(grid_flat)
        self.candidates = [set() for _ in range(81)]
        for i in range(81):
            if self.grid[i] == 0:
                used = set()
                for p in PEERS_FLAT[i]:
                    if self.grid[p] != 0:
                        used.add(self.grid[p])
                self.candidates[i] = set(range(1, 10)) - used

    def assign(self, i, d):
        self.grid[i] = d
        self.candidates[i] = set()
        bit = d
        for p in PEERS_FLAT[i]:
            self.candidates[p].discard(bit)

    def eliminate(self, i, d):
        if d in self.candidates[i]:
            self.candidates[i].discard(d)
            return True
        return False

    def is_solved(self):
        return all(self.grid[i] != 0 for i in range(81))

    def is_valid(self):
        return all(self.grid[i] != 0 or len(self.candidates[i]) > 0 for i in range(81))

    def copy(self):
        s = SolverState.__new__(SolverState)
        s.grid = self.grid[:]
        s.candidates = [c.copy() for c in self.candidates]
        return s

# Helper to convert flat index to (row, col)
def _rc(i):
    return i // 9, i % 9

def _idx(r, c):
    return r * 9 + c

# ---------------------------------------------------------------------------
# Technique implementations (operate on flat indices internally)
# ---------------------------------------------------------------------------

def _naked_singles(state, upgrade):
    progress = False
    for i in range(81):
        if state.grid[i] == 0 and len(state.candidates[i]) == 1:
            state.assign(i, next(iter(state.candidates[i])))
            progress = True
    return progress

def _hidden_singles(state, upgrade):
    found = False
    for unit in ALL_UNITS:
        for d in range(1, 10):
            places = [_idx(r, c) for r, c in unit if d in state.candidates[_idx(r, c)]]
            if len(places) == 1:
                state.assign(places[0], d)
                upgrade('medium')
                found = True
            elif len(places) == 0:
                # Check: digit must already be placed somewhere in the unit
                if not any(state.grid[_idx(r, c)] == d for r, c in unit):
                    # Also check if there's a cell with 0 candidates (real contradiction)
                    # vs just needing naked singles propagation first
                    has_empty_cands = any(
                        state.grid[_idx(r, c)] == 0 and len(state.candidates[_idx(r, c)]) == 0
                        for r, c in unit
                    )
                    if has_empty_cands:
                        return None  # true contradiction
                    # Otherwise digit might be placeable after naked singles resolve
                    # Don't declare unsolvable yet - just skip
    return found

def _naked_subsets(state, upgrade, size, level):
    found = False
    for unit in ALL_UNITS:
        empty = [_idx(r, c) for r, c in unit if state.grid[_idx(r, c)] == 0 and len(state.candidates[_idx(r, c)]) <= size]
        if len(empty) < size:
            continue
        for combo in combinations(empty, size):
            union = set()
            for i in combo:
                union |= state.candidates[i]
            if len(union) == size:
                combo_set = set(combo)
                for r, c in unit:
                    idx = _idx(r, c)
                    if state.grid[idx] == 0 and idx not in combo_set:
                        for d in union:
                            if state.eliminate(idx, d):
                                upgrade(level)
                                found = True
    return found

def _naked_pairs(state, upgrade):
    return _naked_subsets(state, upgrade, 2, 'hard')

def _naked_triples(state, upgrade):
    return _naked_subsets(state, upgrade, 3, 'hard')

def _naked_quads(state, upgrade):
    return _naked_subsets(state, upgrade, 4, 'hard')

def _pointing_pairs_and_box_line(state, upgrade):
    found = False
    for box in BOXES:
        box_set = set(_idx(r, c) for r, c in box)
        for d in range(1, 10):
            places = [_idx(r, c) for r, c in box if d in state.candidates[_idx(r, c)]]
            if len(places) < 2:
                continue
            rows = set(p // 9 for p in places)
            cols = set(p % 9 for p in places)
            if len(rows) == 1:
                row = next(iter(rows))
                for c in range(9):
                    idx = row * 9 + c
                    if idx not in box_set:
                        if state.eliminate(idx, d):
                            upgrade('hard')
                            found = True
            if len(cols) == 1:
                col = next(iter(cols))
                for r in range(9):
                    idx = r * 9 + col
                    if idx not in box_set:
                        if state.eliminate(idx, d):
                            upgrade('hard')
                            found = True
    for d in range(1, 10):
        for row in range(9):
            places = [c for c in range(9) if d in state.candidates[row * 9 + c]]
            if len(places) >= 2 and len(set(c // 3 for c in places)) == 1:
                bc = (places[0] // 3) * 3
                br = (row // 3) * 3
                for r in range(br, br + 3):
                    if r != row:
                        for c in range(bc, bc + 3):
                            if state.eliminate(r * 9 + c, d):
                                upgrade('hard')
                                found = True
        for col in range(9):
            places = [r for r in range(9) if d in state.candidates[r * 9 + col]]
            if len(places) >= 2 and len(set(r // 3 for r in places)) == 1:
                br = (places[0] // 3) * 3
                bc = (col // 3) * 3
                for c in range(bc, bc + 3):
                    if c != col:
                        for r in range(br, br + 3):
                            if state.eliminate(r * 9 + c, d):
                                upgrade('hard')
                                found = True
    return found

def _hidden_subsets(state, upgrade, size, level):
    found = False
    for unit in ALL_UNITS:
        empty = [_idx(r, c) for r, c in unit if state.grid[_idx(r, c)] == 0]
        if len(empty) < size:
            continue
        for digits in combinations(range(1, 10), size):
            places = set()
            valid = True
            for d in digits:
                dp = [i for i in empty if d in state.candidates[i]]
                if not dp:
                    # This digit appears nowhere in the unit — not a valid hidden subset.
                    # (Without this guard the union can reach `size` cells using only
                    # other digits in the group, producing a false positive that
                    # incorrectly restricts — and corrupts — candidate sets.)
                    valid = False
                    break
                places.update(dp)
            if not valid or len(places) != size:
                continue
            dset = set(digits)
            for i in places:
                if state.candidates[i] - dset:
                    state.candidates[i] &= dset
                    upgrade(level)
                    found = True
    return found

def _hidden_pairs(state, upgrade):
    return _hidden_subsets(state, upgrade, 2, 'expert')

def _hidden_triples(state, upgrade):
    return _hidden_subsets(state, upgrade, 3, 'expert')

def _hidden_quads(state, upgrade):
    return _hidden_subsets(state, upgrade, 4, 'expert')

def _fish(state, upgrade, size, level):
    """Generalized fish: X-Wing (2), Swordfish (3), Jellyfish (4)."""
    found = False
    for d in range(1, 10):
        # Row-based
        rp = {}
        for r in range(9):
            cols = [c for c in range(9) if d in state.candidates[r * 9 + c]]
            if 2 <= len(cols) <= size:
                rp[r] = set(cols)
        for rows in combinations(rp, size):
            ucols = set()
            for r in rows:
                ucols |= rp[r]
            if len(ucols) == size:
                for c in ucols:
                    for r in range(9):
                        if r not in rows:
                            if state.eliminate(r * 9 + c, d):
                                upgrade(level)
                                found = True
        # Column-based
        cp = {}
        for c in range(9):
            rows = [r for r in range(9) if d in state.candidates[r * 9 + c]]
            if 2 <= len(rows) <= size:
                cp[c] = set(rows)
        for cols in combinations(cp, size):
            urows = set()
            for c in cols:
                urows |= cp[c]
            if len(urows) == size:
                for r in urows:
                    for c in range(9):
                        if c not in cols:
                            if state.eliminate(r * 9 + c, d):
                                upgrade(level)
                                found = True
    return found

def _x_wing(state, upgrade):
    return _fish(state, upgrade, 2, 'expert')

def _swordfish(state, upgrade):
    return _fish(state, upgrade, 3, 'extreme')

def _jellyfish(state, upgrade):
    return _fish(state, upgrade, 4, 'extreme')

def _skyscraper(state, upgrade):
    found = False
    for d in range(1, 10):
        rp = {}
        for r in range(9):
            cols = [c for c in range(9) if d in state.candidates[r * 9 + c]]
            if len(cols) == 2:
                rp[r] = cols
        for r1, r2 in combinations(rp, 2):
            shared = set(rp[r1]) & set(rp[r2])
            if len(shared) != 1:
                continue
            sc = next(iter(shared))
            ns1 = rp[r1][1] if rp[r1][0] == sc else rp[r1][0]
            ns2 = rp[r2][1] if rp[r2][0] == sc else rp[r2][0]
            common = PEERS[r1][ns1] & PEERS[r2][ns2]
            for cr, cc in common:
                if state.eliminate(cr * 9 + cc, d):
                    upgrade('expert')
                    found = True
        cp = {}
        for c in range(9):
            rows = [r for r in range(9) if d in state.candidates[r * 9 + c]]
            if len(rows) == 2:
                cp[c] = rows
        for c1, c2 in combinations(cp, 2):
            shared = set(cp[c1]) & set(cp[c2])
            if len(shared) != 1:
                continue
            sr = next(iter(shared))
            ns1 = cp[c1][1] if cp[c1][0] == sr else cp[c1][0]
            ns2 = cp[c2][1] if cp[c2][0] == sr else cp[c2][0]
            common = PEERS[ns1][c1] & PEERS[ns2][c2]
            for cr, cc in common:
                if state.eliminate(cr * 9 + cc, d):
                    upgrade('expert')
                    found = True
    return found

def _simple_coloring(state, upgrade):
    found = False
    for d in range(1, 10):
        graph = {}
        for unit in ALL_UNITS:
            places = [_idx(r, c) for r, c in unit if d in state.candidates[_idx(r, c)]]
            if len(places) == 2:
                a, b = places
                graph.setdefault(a, set()).add(b)
                graph.setdefault(b, set()).add(a)
        if not graph:
            continue
        visited = {}
        components = []
        for start in graph:
            if start in visited:
                continue
            color = {start: 0}
            queue = [start]
            while queue:
                node = queue.pop(0)
                for nb in graph.get(node, []):
                    if nb not in color:
                        color[nb] = 1 - color[node]
                        queue.append(nb)
            visited.update(color)
            components.append(color)
        for color_map in components:
            g0 = [i for i, c in color_map.items() if c == 0]
            g1 = [i for i, c in color_map.items() if c == 1]
            for group in (g0, g1):
                contradiction = False
                for x in range(len(group)):
                    for y in range(x+1, len(group)):
                        if group[y] in PEERS_FLAT[group[x]]:
                            contradiction = True
                            break
                    if contradiction:
                        break
                if contradiction:
                    for i in group:
                        if state.eliminate(i, d):
                            upgrade('expert')
                            found = True
            for i in range(81):
                if i in color_map or d not in state.candidates[i]:
                    continue
                sees0 = any(ci in PEERS_FLAT[i] for ci in g0)
                sees1 = any(ci in PEERS_FLAT[i] for ci in g1)
                if sees0 and sees1:
                    if state.eliminate(i, d):
                        upgrade('expert')
                        found = True
    return found

def _unique_rectangle(state, upgrade):
    found = False
    bi = set()
    for i in range(81):
        if state.grid[i] == 0 and len(state.candidates[i]) == 2:
            bi.add(i)
    for r1, r2 in combinations(range(9), 2):
        for c1, c2 in combinations(range(9), 2):
            corners = [r1*9+c1, r1*9+c2, r2*9+c1, r2*9+c2]
            boxes = set(BOX_OF[i//9][i%9] for i in corners)
            if len(boxes) != 2:
                continue
            if any(state.grid[i] != 0 for i in corners):
                continue
            bi_corners = [i for i in corners if i in bi]
            if len(bi_corners) < 3:
                continue
            pair = state.candidates[bi_corners[0]]
            if not all(state.candidates[i] == pair for i in bi_corners):
                continue
            non_bi = [i for i in corners if i not in bi]
            if len(non_bi) == 1:
                i = non_bi[0]
                if pair.issubset(state.candidates[i]):
                    for d in pair:
                        if state.eliminate(i, d):
                            upgrade('expert')
                            found = True
    return found

def _finned_x_wing(state, upgrade):
    found = False
    for d in range(1, 10):
        rp = {}
        for r in range(9):
            cols = [c for c in range(9) if d in state.candidates[r*9+c]]
            if 2 <= len(cols) <= 3:
                rp[r] = cols
        for r1, r2 in combinations(rp, 2):
            c1s, c2s = set(rp[r1]), set(rp[r2])
            if len(c1s) == 2 and len(c2s) == 2:
                continue
            for base_r, base_cols, fin_r, fin_cols in [
                (r1, c1s, r2, c2s), (r2, c2s, r1, c1s)
            ]:
                if len(base_cols) != 2 or not base_cols.issubset(fin_cols):
                    continue
                fins = fin_cols - base_cols
                if len(fins) != 1:
                    continue
                fin_c = next(iter(fins))
                fin_box = BOX_OF[fin_r][fin_c]
                for tc in base_cols:
                    for r in range(9):
                        if r != base_r and r != fin_r and BOX_OF[r][tc] == fin_box:
                            if state.eliminate(r*9+tc, d):
                                upgrade('extreme')
                                found = True
        cp = {}
        for c in range(9):
            rows = [r for r in range(9) if d in state.candidates[r*9+c]]
            if 2 <= len(rows) <= 3:
                cp[c] = rows
        for c1, c2 in combinations(cp, 2):
            r1s, r2s = set(cp[c1]), set(cp[c2])
            if len(r1s) == 2 and len(r2s) == 2:
                continue
            for base_c, base_rows, fin_c, fin_rows in [
                (c1, r1s, c2, r2s), (c2, r2s, c1, r1s)
            ]:
                if len(base_rows) != 2 or not base_rows.issubset(fin_rows):
                    continue
                fins = fin_rows - base_rows
                if len(fins) != 1:
                    continue
                fin_r = next(iter(fins))
                fin_box = BOX_OF[fin_r][fin_c]
                for tr in base_rows:
                    for c in range(9):
                        if c != base_c and c != fin_c and BOX_OF[tr][c] == fin_box:
                            if state.eliminate(tr*9+c, d):
                                upgrade('extreme')
                                found = True
    return found

def _xy_wing(state, upgrade):
    found = False
    bi = [(i, state.candidates[i]) for i in range(81)
          if state.grid[i] == 0 and len(state.candidates[i]) == 2]
    bi_set = set(i for i, _ in bi)
    for pivot, cands_p in bi:
        wings = []
        for p in PEERS_FLAT[pivot]:
            if p in bi_set:
                wc = state.candidates[p]
                if len(cands_p & wc) == 1:
                    wings.append((p, wc))
        for i in range(len(wings)):
            for j in range(i+1, len(wings)):
                p1, w1 = wings[i]
                p2, w2 = wings[j]
                if (cands_p & w1) == (cands_p & w2):
                    continue
                e1, e2 = w1 - cands_p, w2 - cands_p
                if e1 == e2 and len(e1) == 1:
                    z = next(iter(e1))
                    common = PEERS_FLAT[p1] & PEERS_FLAT[p2]
                    for ci in common:
                        if ci != pivot:
                            if state.eliminate(ci, z):
                                upgrade('extreme')
                                found = True
    return found

def _xyz_wing(state, upgrade):
    found = False
    for pi in range(81):
        if state.grid[pi] != 0 or len(state.candidates[pi]) != 3:
            continue
        pc = state.candidates[pi]
        wings = []
        for p in PEERS_FLAT[pi]:
            if state.grid[p] == 0 and len(state.candidates[p]) == 2:
                if state.candidates[p].issubset(pc):
                    wings.append(p)
        for i in range(len(wings)):
            for j in range(i+1, len(wings)):
                w1, w2 = wings[i], wings[j]
                wc1, wc2 = state.candidates[w1], state.candidates[w2]
                if wc1 | wc2 != pc:
                    continue
                z_set = wc1 & wc2
                if len(z_set) != 1:
                    continue
                z = next(iter(z_set))
                common = PEERS_FLAT[pi] & PEERS_FLAT[w1] & PEERS_FLAT[w2]
                for ci in common:
                    if state.eliminate(ci, z):
                        upgrade('extreme')
                        found = True
    return found

def _wxyz_wing(state, upgrade):
    found = False
    for pi in range(81):
        if state.grid[pi] != 0 or len(state.candidates[pi]) != 4:
            continue
        pc = state.candidates[pi]
        wings = []
        for p in PEERS_FLAT[pi]:
            if state.grid[p] == 0 and len(state.candidates[p]) == 2:
                if state.candidates[p].issubset(pc):
                    wings.append(p)
        if len(wings) < 3:
            continue
        for combo in combinations(wings, 3):
            union = set()
            for w in combo:
                union |= state.candidates[w]
            if union != pc:
                continue
            common_d = state.candidates[combo[0]]
            for w in combo[1:]:
                common_d = common_d & state.candidates[w]
            if len(common_d) != 1:
                continue
            z = next(iter(common_d))
            common = PEERS_FLAT[pi]
            for w in combo:
                common = common & PEERS_FLAT[w]
            for ci in common:
                if state.eliminate(ci, z):
                    upgrade('extreme')
                    found = True
    return found

def _remote_pairs(state, upgrade):
    """
    Remote Pairs: bivalue cells sharing the same two candidates form a network.
    2-colour the connected components. Any external cell seeing one cell of each
    colour (for either candidate) can eliminate both candidates.
    Requires a component of at least 4 cells (chain length >= 4).
    """
    found = False
    pair_to_cells = {}
    for i in range(81):
        if state.grid[i] == 0 and len(state.candidates[i]) == 2:
            pair = frozenset(state.candidates[i])
            pair_to_cells.setdefault(pair, []).append(i)

    for pair, cells in pair_to_cells.items():
        if len(cells) < 4:
            continue
        d1, d2 = tuple(pair)
        cell_set = set(cells)
        visited = set()

        for start in cells:
            if start in visited:
                continue
            # BFS 2-colouring within this pair's connected subgraph
            color = {start: 0}
            queue = [start]
            bipartite = True
            while queue:
                cur = queue.pop(0)
                for p in PEERS_FLAT[cur]:
                    if p not in cell_set:
                        continue
                    expected = 1 - color[cur]
                    if p not in color:
                        color[p] = expected
                        queue.append(p)
                    elif color[p] != expected:
                        bipartite = False

            comp = set(color.keys())
            visited |= comp

            if not bipartite or len(comp) < 4:
                continue

            peers0, peers1 = set(), set()
            for c, cl in color.items():
                if cl == 0:
                    peers0 |= PEERS_FLAT[c]
                else:
                    peers1 |= PEERS_FLAT[c]

            for ci in peers0 & peers1:
                if state.grid[ci] != 0 or ci in comp:
                    continue
                for d in (d1, d2):
                    if state.eliminate(ci, d):
                        upgrade('extreme')
                        found = True
    return found


def _empty_rectangle(state, upgrade):
    """
    Empty Rectangle: when a digit is confined to a single row (or column)
    within a box, a conjugate pair in that row/col creates an elimination.

    Pattern (row variant):
      - Box B: digit d candidates all lie in row R  (>= 2 cells)
      - Column Col_s (outside B): exactly 2 candidates for d, in rows R and R2
      - Elimination: cells at (R2, c) for c in box B's column range
    """
    found = False
    for d in range(1, 10):
        for box_idx in range(9):
            box_r = (box_idx // 3) * 3
            box_c = (box_idx % 3) * 3
            box_cells = [r * 9 + c
                         for r in range(box_r, box_r + 3)
                         for c in range(box_c, box_c + 3)]
            cands_in_box = [ci for ci in box_cells
                            if state.grid[ci] == 0 and d in state.candidates[ci]]
            if len(cands_in_box) < 2:
                continue

            rows = {ci // 9 for ci in cands_in_box}
            cols = {ci % 9 for ci in cands_in_box}

            # --- row-confined ER ---
            if len(rows) == 1:
                er_row = next(iter(rows))
                for col_s in range(9):
                    if box_c <= col_s < box_c + 3:
                        continue
                    col_d = [r * 9 + col_s for r in range(9)
                             if state.grid[r * 9 + col_s] == 0
                             and d in state.candidates[r * 9 + col_s]]
                    if len(col_d) != 2:
                        continue
                    r1, r2 = col_d[0] // 9, col_d[1] // 9
                    if er_row == r1:
                        target_row = r2
                    elif er_row == r2:
                        target_row = r1
                    else:
                        continue
                    if box_r <= target_row < box_r + 3:
                        continue  # target inside box — redundant
                    for c in range(box_c, box_c + 3):
                        ti = target_row * 9 + c
                        if state.grid[ti] == 0 and d in state.candidates[ti]:
                            if state.eliminate(ti, d):
                                upgrade('extreme')
                                found = True

            # --- column-confined ER ---
            if len(cols) == 1:
                er_col = next(iter(cols))
                for row_s in range(9):
                    if box_r <= row_s < box_r + 3:
                        continue
                    row_d = [row_s * 9 + c for c in range(9)
                             if state.grid[row_s * 9 + c] == 0
                             and d in state.candidates[row_s * 9 + c]]
                    if len(row_d) != 2:
                        continue
                    c1, c2 = row_d[0] % 9, row_d[1] % 9
                    if er_col == c1:
                        target_col = c2
                    elif er_col == c2:
                        target_col = c1
                    else:
                        continue
                    if box_c <= target_col < box_c + 3:
                        continue  # target inside box — redundant
                    for r in range(box_r, box_r + 3):
                        ti = r * 9 + target_col
                        if state.grid[ti] == 0 and d in state.candidates[ti]:
                            if state.eliminate(ti, d):
                                upgrade('extreme')
                                found = True
    return found


def _aic(state, upgrade):
    """
    AIC (Alternating Inference Chains) via extended 2-colouring.

    Builds a strong-link graph whose nodes are (cell, digit) pairs:
      - same-digit conjugate pairs within any unit
      - different-digit strong links inside bivalue cells

    2-colours each connected component. Any external (cell, d) that sees
    one node of each colour class (for digit d) can eliminate d.
    Also detects when two same-colour nodes see each other (contradiction
    for that colour class) and eliminates d from every node in that class.

    This subsumes simple_coloring, X-chains, W-wings, and many full AICs.
    """
    found = False

    # Build strong-link graph
    strong = {}
    for unit in ALL_UNITS:
        for d in range(1, 10):
            places = [_idx(r, c) for r, c in unit
                      if d in state.candidates[_idx(r, c)]]
            if len(places) == 2:
                a, b = places
                strong.setdefault((a, d), set()).add((b, d))
                strong.setdefault((b, d), set()).add((a, d))
    for ci in range(81):
        if state.grid[ci] == 0 and len(state.candidates[ci]) == 2:
            d1, d2 = tuple(state.candidates[ci])
            strong.setdefault((ci, d1), set()).add((ci, d2))
            strong.setdefault((ci, d2), set()).add((ci, d1))

    visited = set()
    for start in list(strong.keys()):
        if start in visited:
            continue

        color = {start: 0}
        queue = [start]
        bipartite = True
        while queue:
            node = queue.pop(0)
            for nb in strong.get(node, set()):
                expected = 1 - color[node]
                if nb not in color:
                    color[nb] = expected
                    queue.append(nb)
                elif color[nb] != expected:
                    bipartite = False

        comp = set(color.keys())
        visited |= comp

        if not bipartite or len(comp) < 4:
            continue

        # Group by digit and colour
        digit_colors = {}
        for (cell, d), c in color.items():
            if d not in digit_colors:
                digit_colors[d] = [[], []]
            digit_colors[d][c].append(cell)

        for d, (c0, c1) in digit_colors.items():
            if not c0 or not c1:
                continue
            # Contradiction: two same-colour nodes see each other → that class is false
            for group, label in ((c0, 0), (c1, 1)):
                if any(group[j] in PEERS_FLAT[group[i]]
                       for i in range(len(group))
                       for j in range(i + 1, len(group))):
                    for ci in group:
                        if state.eliminate(ci, d):
                            upgrade('diabolic')
                            found = True
            # Elimination: external cell seeing both colour classes
            peers0 = set().union(*(PEERS_FLAT[c] for c in c0))
            peers1 = set().union(*(PEERS_FLAT[c] for c in c1))
            for ck in peers0 & peers1:
                if state.grid[ck] == 0 and d in state.candidates[ck]:
                    if (ck, d) not in comp:
                        if state.eliminate(ck, d):
                            upgrade('diabolic')
                            found = True
    return found


def _forcing_chains(state, upgrade):
    """
    Cell Forcing Chains: for each bivalue cell, assume each candidate in turn,
    propagate naked singles, then look for common consequences across all branches.

    For catalog generation we intentionally reject contradiction-based forcing
    chains. They are logically valid, but they feel too close to trial-and-error
    for the kind of human-friendly puzzle set we want.

    Accepted forcing-chain progress is therefore limited to non-contradictory
    common consequences:
    - all branches remain valid
    - all branches eliminate the same candidate elsewhere, or
    - all branches place the same digit in another cell
    """
    found = False

    def propagate(s):
        """Naked-singles propagation. Returns False on contradiction."""
        changed = True
        while changed:
            changed = False
            for i in range(81):
                if s.grid[i] == 0:
                    if len(s.candidates[i]) == 0:
                        return False
                    if len(s.candidates[i]) == 1:
                        s.assign(i, next(iter(s.candidates[i])))
                        changed = True
        return True

    for ci in range(81):
        if state.grid[ci] != 0 or len(state.candidates[ci]) != 2:
            continue
        cands = list(state.candidates[ci])

        branches = []
        for d in cands:
            s = state.copy()
            s.assign(ci, d)
            ok = propagate(s)
            branches.append(s if ok else None)

        # Reject contradiction-based forcing chains for generated catalogs.
        # If any assumption fails, this pivot is not considered human-friendly.
        if any(s is None for s in branches):
            continue
        valid = branches

        # Common consequences across all valid branches
        for cj in range(81):
            if state.grid[cj] != 0:
                continue
            for d in list(state.candidates[cj]):
                # Eliminated in every branch
                if all((s.grid[cj] != 0 and s.grid[cj] != d) or
                       (s.grid[cj] == 0 and d not in s.candidates[cj])
                       for s in valid):
                    if state.eliminate(cj, d):
                        upgrade('diabolic')
                        found = True
                # Placed as d in every branch
                if all(s.grid[cj] == d for s in valid):
                    if state.grid[cj] == 0 and d in state.candidates[cj]:
                        state.assign(cj, d)
                        upgrade('diabolic')
                        found = True
    return found


# ---------------------------------------------------------------------------
# Solver dispatcher
# ---------------------------------------------------------------------------

NAMED_TECHNIQUES = [
    # easy (1)
    ('naked_singles',    _naked_singles),
    # medium (2)
    ('hidden_singles',   _hidden_singles),
    # hard (3-6)
    ('naked_pairs',      _naked_pairs),
    ('naked_triples',    _naked_triples),
    ('naked_quads',      _naked_quads),
    ('pointing_pairs',   _pointing_pairs_and_box_line),
    # expert (7-13)
    ('hidden_pairs',     _hidden_pairs),
    ('hidden_triples',   _hidden_triples),
    ('hidden_quads',     _hidden_quads),
    ('x_wing',           _x_wing),
    ('skyscraper',       _skyscraper),
    ('simple_coloring',  _simple_coloring),
    ('unique_rectangle', _unique_rectangle),
    # extreme (14-21)
    ('swordfish',        _swordfish),
    ('jellyfish',        _jellyfish),
    ('finned_x_wing',    _finned_x_wing),
    ('xy_wing',          _xy_wing),
    ('xyz_wing',         _xyz_wing),
    ('wxyz_wing',        _wxyz_wing),
    ('remote_pairs',     _remote_pairs),
    ('empty_rectangle',  _empty_rectangle),
    # diabolic (22-23)
    ('aic',              _aic),
    ('forcing_chains',   _forcing_chains),
]

# Number of techniques available at each difficulty level (cumulative prefix of NAMED_TECHNIQUES)
LEVEL_TECHNIQUE_COUNTS = {
    'easy':     1,   # naked_singles only
    'medium':   2,   # + hidden_singles
    'hard':     6,   # + naked pairs/triples/quads, pointing_pairs
    'expert':  13,   # + hidden pairs/triples/quads, x_wing, skyscraper, simple_coloring, unique_rectangle
    'extreme': 21,   # + swordfish, jellyfish, finned_x_wing, xy/xyz/wxyz_wing, remote_pairs, empty_rectangle
    'diabolic': 23,  # + aic, forcing_chains
}

LEVEL_NAMES = ['easy', 'medium', 'hard', 'expert', 'extreme', 'diabolic']

def solve_with_techniques(grid_flat):
    """
    Classify puzzle difficulty and record which techniques were needed.

    Returns (difficulty_string, techniques_list) on success, or None if unsolvable.

    Difficulty is the minimum level whose technique set fully solves the puzzle.
    Uses a single progressive solve: the technique set is extended level by level
    whenever the current set stalls — no redundant work compared to N independent
    probes from scratch.

    Progress means either placing a digit (state.assign) or eliminating a candidate
    (state.eliminate). Both trigger a restart from the simplest technique so that
    simpler techniques are always re-tried after a harder one clears the way.

    Bifurcation (trial-and-error) is tried last, only after all 23 logical
    techniques are exhausted.
    """
    state = SolverState(grid_flat)
    noop = lambda _level: None   # no-op for the upgrade param — not needed here
    used = []                    # techniques that made progress, in order of first use
    seen = set()

    for level in LEVEL_NAMES:
        subset = NAMED_TECHNIQUES[:LEVEL_TECHNIQUE_COUNTS[level]]

        # Run until this level's technique set stalls
        for _ in range(500):
            if state.is_solved():
                return (level, used)
            progress = False
            stalled = False
            for name, fn in subset:
                result = fn(state, noop)
                if result is None:
                    # A technique detected a contradiction.  This can happen when
                    # advanced candidate-elimination techniques incorrectly remove
                    # valid candidates (a known limitation in some expert+ techniques).
                    # Treat as a stall and fall through to bifurcation with a clean state.
                    stalled = True
                    break
                if result:             # progress: digit placed OR candidate eliminated
                    if name not in seen:
                        seen.add(name)
                        used.append(name)
                    progress = True
                    break              # restart from simplest technique
            if stalled or not progress:
                break                  # stalled → extend technique set to next level

        if state.is_solved():
            return (level, used)

    # All 23 logical techniques exhausted (or state became contradictory due to technique
    # limitations).  Rebuild candidates from placed digits only — this discards any
    # incorrect eliminations made by advanced techniques — then apply bifurcation.
    state_clean = SolverState(grid_flat)
    for i in range(81):
        if state.grid[i] != 0 and state_clean.grid[i] == 0:
            state_clean.assign(i, state.grid[i])
    if _bifurcation_solve(state_clean):
        return (LEVEL_NAMES[-1], used + ['bifurcation'])

    # Last resort: bifurcation from the original puzzle (ignores all technique work)
    state_orig = SolverState(grid_flat)
    if _bifurcation_solve(state_orig):
        return (LEVEL_NAMES[-1], used + ['bifurcation'])

    return None

def _bifurcation_solve(state):
    best, best_cnt = -1, 10
    for i in range(81):
        if state.grid[i] == 0:
            cnt = len(state.candidates[i])
            if cnt < best_cnt:
                best_cnt = cnt
                best = i
    if best == -1:
        return True
    for d in list(state.candidates[best]):
        s2 = state.copy()
        s2.assign(best, d)
        if s2.is_valid() and _bifurcation_fill(s2):
            state.grid[:] = s2.grid
            state.candidates[:] = s2.candidates
            return True
    return False

def _bifurcation_fill(state):
    changed = True
    while changed:
        changed = False
        for i in range(81):
            if state.grid[i] == 0:
                if len(state.candidates[i]) == 0:
                    return False
                if len(state.candidates[i]) == 1:
                    state.assign(i, next(iter(state.candidates[i])))
                    changed = True
    if state.is_solved():
        return True
    best, best_cnt = -1, 10
    for i in range(81):
        if state.grid[i] == 0:
            cnt = len(state.candidates[i])
            if cnt < best_cnt:
                best_cnt = cnt
                best = i
    if best == -1:
        return False
    for d in list(state.candidates[best]):
        s2 = state.copy()
        s2.assign(best, d)
        if s2.is_valid() and _bifurcation_fill(s2):
            state.grid[:] = s2.grid
            state.candidates[:] = s2.candidates
            return True
    return False

# ---------------------------------------------------------------------------
# Puzzle generation (single puzzle, called by workers)
# ---------------------------------------------------------------------------

CLUE_TARGETS = {
    'easy':     (36, 45),
    'medium':   (30, 35),
    'hard':     (26, 32),
    'expert':   (23, 29),
    'extreme':  (20, 27),
    'diabolic': (20, 26),
}

def try_generate_one(difficulty):
    """Try to generate one puzzle of given difficulty. Returns dict or None."""
    min_clues, max_clues = CLUE_TARGETS[difficulty]

    clue_target = random.randint(min_clues, max_clues)

    grid = generate_complete_grid()
    puzzle, actual_clues = remove_cells(grid, clue_target)

    if actual_clues > max_clues:
        return None

    result = solve_with_techniques(puzzle)
    if result is None:
        return None
    diff, techniques = result
    if diff == difficulty:
        values = [puzzle[r*9:(r+1)*9] for r in range(9)]
        return {"difficulty": difficulty, "values": values, "clues": actual_clues, "techniques": techniques}
    return None

def try_generate_hard_plus(_seed):
    """Generate a minimal puzzle (remove as many cells as possible) and classify it.
    Used for expert/extreme/diabolic: we strip the grid maximally and classify."""
    random.seed(_seed)
    grid = generate_complete_grid()
    # Aggressively remove cells - aim for 20-26 clues
    puzzle, actual_clues = remove_cells(grid, random.randint(20, 26))

    result = solve_with_techniques(puzzle)
    if result is None:
        return None
    diff, techniques = result
    if diff in ('expert', 'extreme', 'diabolic'):
        min_techniques = MIN_TECHNIQUES_BY_DIFFICULTY[diff]
        if len(techniques) < min_techniques:
            return None  # reject: not rich enough for this difficulty tier
        if diff in ('extreme', 'diabolic'):
            if 'bifurcation' in techniques:
                return None  # reject: must be solvable by pure logic
        values = [puzzle[r*9:(r+1)*9] for r in range(9)]
        return {"difficulty": diff, "values": values, "clues": actual_clues, "techniques": techniques}
    return None

def worker_generate(args):
    """Worker function for multiprocessing."""
    difficulty, seed = args
    random.seed(seed)
    for _ in range(20):
        result = try_generate_one(difficulty)
        if result is not None:
            return result
    return None

def worker_generate_hard_plus(seed):
    """Worker for expert/extreme: try multiple times."""
    random.seed(seed)
    for _ in range(10):
        result = try_generate_hard_plus(random.randint(0, 2**31))
        if result is not None:
            return result
    return None

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

OUTPUT_PATH = "puzzle_catalog.json"

TARGETS = {
    'easy':      200,
    'medium':    300,
    'hard':      500,
    'expert':   1000,
    'extreme':  1000,
    'diabolic':  500
}

MIN_TECHNIQUES_BY_DIFFICULTY = {
    'expert': 6,
    'extreme': 8,
    'diabolic': 10,
}

def save_puzzles(puzzles):
    puzzles.sort(key=lambda p: (LEVEL_ORDER[p["difficulty"]], p["id"]))
    for i, p in enumerate(puzzles):
        p["id"] = i + 1
    with open(OUTPUT_PATH, "w") as f:
        json.dump(puzzles, f, indent=2)

def print_status(puzzles, elapsed, counts, label="Status"):
    total = sum(TARGETS.values())
    generated = len(puzzles)
    rate = generated / elapsed if elapsed > 0 else 0
    print(f"\n{'='*60}", flush=True)
    print(f"  {label} | Elapsed: {elapsed:.1f}s | Rate: {rate:.2f} puzzles/s", flush=True)
    print(f"  Total: {generated}/{total}", flush=True)
    print(f"  {'─'*50}", flush=True)
    for d in TARGETS:
        target = TARGETS[d]
        done = counts.get(d, 0)
        bar_len = 20
        filled = int(bar_len * done / target) if target > 0 else 0
        bar = '█' * filled + '░' * (bar_len - filled)
        pct = 100 * done / target if target > 0 else 0
        print(f"  {d:8s} [{bar}] {done:4d}/{target:4d} ({pct:5.1f}%)", flush=True)
    print(f"{'='*60}\n", flush=True)

def main():
    parser = argparse.ArgumentParser(description="Generate Sudoku puzzles")
    parser.add_argument("--timeout", type=int, default=0,
                        help="Max runtime in seconds (0 = unlimited)")
    parser.add_argument("--resume", action="store_true",
                        help="Resume from existing puzzles_generated.json")
    parser.add_argument("--workers", type=int, default=max(1, cpu_count() - 2),
                        help="Number of parallel workers")
    args = parser.parse_args()

    puzzles = []
    if args.resume:
        try:
            with open(OUTPUT_PATH) as f:
                puzzles = json.load(f)
            print(f"Resumed {len(puzzles)} puzzles from {OUTPUT_PATH}")
        except (FileNotFoundError, json.JSONDecodeError):
            print("No valid previous file found, starting fresh.")

    # Build a set of already-known grids (flat tuple) to avoid duplicates across runs.
    def _grid_key(values):
        return tuple(v for row in values for v in row)

    known_grids = {_grid_key(p["values"]) for p in puzzles}

    counts = {}
    for d in TARGETS:
        counts[d] = sum(1 for p in puzzles if p["difficulty"] == d)

    start_time = time.time()
    batch_size = args.workers * 2
    puzzle_id = max((p["id"] for p in puzzles), default=0) + 1
    last_save = start_time

    print(f"Workers: {args.workers} | Timeout: {args.timeout}s" if args.timeout > 0
          else f"Workers: {args.workers} | Timeout: unlimited", flush=True)
    print_status(puzzles, 0, counts, "Initial")

    try:
        with Pool(processes=args.workers) as pool:
            while True:
                elapsed = time.time() - start_time
                if args.timeout > 0 and elapsed >= args.timeout:
                    print(f"\n>>> Timeout reached ({args.timeout}s)", flush=True)
                    break

                # Check what's still needed
                needed = {d: TARGETS[d] - counts.get(d, 0) for d in TARGETS}
                remaining = sum(max(0, v) for v in needed.values())
                if remaining == 0:
                    break

                # Build batch: split between normal and hard_plus workers
                normal_tasks = []
                hard_plus_count = 0
                need_hard_plus = (needed.get('expert', 0) > 0 or needed.get('extreme', 0) > 0
                                  or needed.get('diabolic', 0) > 0)
                need_normal = any(needed.get(d, 0) > 0 for d in ('easy', 'medium', 'hard'))

                for _ in range(batch_size):
                    if need_hard_plus and need_normal:
                        # Split: 2/3 for hard+, 1/3 for normal
                        if random.random() < 0.67:
                            hard_plus_count += 1
                        else:
                            weights = [max(0, needed.get(d, 0)) for d in ('easy', 'medium', 'hard')]
                            tw = sum(weights)
                            if tw > 0:
                                pick = random.choices(['easy', 'medium', 'hard'], weights=weights, k=1)[0]
                                normal_tasks.append((pick, random.randint(0, 2**31)))
                    elif need_hard_plus:
                        hard_plus_count += 1
                    elif need_normal:
                        weights = [max(0, needed.get(d, 0)) for d in ('easy', 'medium', 'hard')]
                        tw = sum(weights)
                        if tw > 0:
                            pick = random.choices(['easy', 'medium', 'hard'], weights=weights, k=1)[0]
                            normal_tasks.append((pick, random.randint(0, 2**31)))

                if not normal_tasks and hard_plus_count == 0:
                    break

                # Run both worker types in parallel
                hp_tasks = [random.randint(0, 2**31) for _ in range(hard_plus_count)]
                results_normal = pool.map(worker_generate, normal_tasks, chunksize=1) if normal_tasks else []
                results_hp = pool.map(worker_generate_hard_plus, hp_tasks, chunksize=1) if hp_tasks else []
                results = list(results_normal) + list(results_hp)

                for result in results:
                    if result is None:
                        continue
                    d = result["difficulty"]
                    if counts.get(d, 0) >= TARGETS[d]:
                        continue  # already have enough
                    key = _grid_key(result["values"])
                    if key in known_grids:
                        continue  # duplicate — skip
                    known_grids.add(key)
                    entry = {
                        "id": puzzle_id,
                        "difficulty": d,
                        "values": result["values"],
                        "techniques": result["techniques"],
                    }
                    puzzles.append(entry)
                    puzzle_id += 1
                    counts[d] = counts.get(d, 0) + 1
                    elapsed = time.time() - start_time
                    print(f"  + {d:8s} #{counts[d]:4d}/{TARGETS[d]}  "
                          f"({result['clues']} clues) [{elapsed:.0f}s]", flush=True)

                # Periodic save
                now = time.time()
                if now - last_save >= 30:
                    save_puzzles(puzzles)
                    print_status(puzzles, now - start_time, counts)
                    print(f"  (saved to {OUTPUT_PATH})", flush=True)
                    last_save = now

    except KeyboardInterrupt:
        print("\n>>> Interrupted, saving...", flush=True)

    elapsed = time.time() - start_time
    save_puzzles(puzzles)
    print_status(puzzles, elapsed, "Final" if isinstance(elapsed, str) else counts)
    print(f"Saved to {OUTPUT_PATH}", flush=True)

if __name__ == "__main__":
    main()
