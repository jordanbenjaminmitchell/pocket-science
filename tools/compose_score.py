#!/usr/bin/env python3
"""Pocket Science board score: one chill-trap loop for every table.

Each board gets its own 64-bar song (about 3 to 4 minutes) built from synthesis only:
lo-fi keys and pads up top, and a trap engine underneath (half-time kit, hat rolls,
808 slides, snare-roll builds and wobble-bass drops: "womp, a womp womp").

Every melody is read from a real mathematical sequence (digits of pi, Fibonacci,
Recaman, Thue-Morse...), so each table also has its own maths behind it.

Song form, in bars:
    1-8 intro | 9-16 groove | 17-20 build | 21-28 DROP | 29-36 break
    37-44 groove 2 | 45-48 build 2 | 49-56 DROP 2 | 57-64 outro (fades into bar 1)

The render runs a few seconds past bar 64 and folds that tail onto the start, so
reverb and released notes carry over the loop point and the seam is inaudible.

Usage (needs Python with NumPy + SciPy, and ffmpeg with libvorbis on PATH):
    py -3.12 tools/compose_score.py                  # every board into assets/music/boards
    py -3.12 tools/compose_score.py local final      # just these boards
    py -3.12 tools/compose_score.py --inspect DIR    # also write WAVs, spectrograms and a level report
"""
import argparse
import json
import math
import os
import struct
import subprocess
import sys
import zlib
from concurrent.futures import ProcessPoolExecutor

import numpy as np
from scipy import signal

SR = 44100
TAIL = 6 * SR
TAU = 2 * np.pi
BARS = 64
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


# ----------------------------------------------------------------------------
# Maths: the sequences every melody is read from.
# ----------------------------------------------------------------------------

def _digits(n_int, count):
    return [int(c) for c in str(n_int)[:count]]


def seq_pi(n):
    prec = n + 12
    scale = 10 ** prec

    def atan_inv(x):
        total, term, x2, k, sign = 0, scale // x, x * x, 1, 1
        while term:
            total += sign * (term // k)
            term //= x2
            k += 2
            sign = -sign
        return total
    return _digits(16 * atan_inv(5) - 4 * atan_inv(239), n)


def seq_e(n):
    scale, total, term, k = 10 ** (n + 12), 0, 10 ** (n + 12), 0
    while term:
        total += term
        k += 1
        term //= k
    return _digits(total, n)


def seq_sqrt(r, n):
    return _digits(math.isqrt(r * 10 ** (2 * (n + 6))), n)


def seq_phi(n):
    p = n + 6
    return _digits((10 ** p + math.isqrt(5 * 10 ** (2 * p))) // 2, n)


def seq_ln2(n):
    scale = 10 ** (n + 12)
    total, k = 0, 1
    while True:
        term = scale // (k << k)
        if term == 0:
            break
        total += term
        k += 1
    return _digits(total, n)


def seq_fib(n):
    a, b, out = 1, 1, []
    for _ in range(n):
        out.append(a)
        a, b = b, a + b
    return out


def seq_collatz(n):
    x, out = 27, []
    while len(out) < n:
        out.append(x)
        x = x // 2 if x % 2 == 0 else 3 * x + 1
        if x == 1:
            x = 27
    return out


def _primes(count):
    out, c = [], 2
    while len(out) < count:
        if all(c % p for p in out if p * p <= c):
            out.append(c)
        c += 1
    return out


def seq_prime_gaps(n):
    p = _primes(n + 1)
    return [p[i + 1] - p[i] for i in range(n)]


def seq_twin_primes(n):
    p = _primes(400)
    out = []
    for a, b in zip(p, p[1:]):
        if b - a == 2:
            out += [a, b]
    return out[:n]


def seq_catalan(n):
    out, c = [], 1
    for i in range(n):
        out.append(c)
        c = c * 2 * (2 * i + 1) // (i + 2)
    return out


def seq_thue_morse(n):
    # Read in pairs so the binary sequence gives four melodic values.
    bits = [bin(i).count("1") % 2 for i in range(2 * n)]
    return [bits[2 * i] * 2 + bits[2 * i + 1] + (i % 3) for i in range(n)]


def seq_recaman(n):
    out, seen, a = [0], {0}, 0
    for i in range(1, n):
        a = a - i if a - i > 0 and a - i not in seen else a + i
        out.append(a)
        seen.add(a)
    return out


def seq_triangular(n):
    return [i * (i + 1) // 2 for i in range(1, n + 1)]


def seq_squares(n):
    return [i * i for i in range(1, n + 1)]


def seq_cubes(n):
    return [i ** 3 for i in range(1, n + 1)]


def seq_look_and_say(n):
    s, out = "1", []
    while len(out) < n:
        out += [int(c) for c in s]
        nxt, i = "", 0
        while i < len(s):
            j = i
            while j < len(s) and s[j] == s[i]:
                j += 1
            nxt += str(j - i) + s[i]
            i = j
        s = nxt
    return out[:n]


def seq_totient(n):
    return [sum(1 for k in range(1, m + 1) if math.gcd(k, m) == 1) for m in range(1, n + 1)]


def seq_pascal_mod7(n):
    out, row = [], [1]
    while len(out) < n:
        out += [v % 7 for v in row]
        row = [1] + [row[i] + row[i + 1] for i in range(len(row) - 1)] + [1]
    return out[:n]


def seq_cyclic7(n):
    return [int(c) for c in ("142857" * (n // 6 + 1))[:n]]


def seq_one_81(n):
    # 1/81 = 0.012345679012..., every digit but the 8. The 8 goes last.
    return [int(c) for c in ("012345679" * (n // 9 + 1))[:n]]


SEQUENCES = {
    "pi": lambda n: seq_pi(n), "e": lambda n: seq_e(n), "sqrt2": lambda n: seq_sqrt(2, n),
    "sqrt3": lambda n: seq_sqrt(3, n), "sqrt5": lambda n: seq_sqrt(5, n), "phi": seq_phi,
    "ln2": seq_ln2, "fib": seq_fib, "collatz": seq_collatz, "prime_gaps": seq_prime_gaps,
    "twin_primes": seq_twin_primes, "catalan": seq_catalan, "thue_morse": seq_thue_morse,
    "recaman": seq_recaman, "triangular": seq_triangular, "squares": seq_squares, "cubes": seq_cubes,
    "look_and_say": seq_look_and_say, "totient": seq_totient, "pascal7": seq_pascal_mod7,
    "cyclic7": seq_cyclic7, "one_81": seq_one_81,
}


# ----------------------------------------------------------------------------
# Harmony
# ----------------------------------------------------------------------------

SCALES = {
    "major": [0, 2, 4, 5, 7, 9, 11], "minor": [0, 2, 3, 5, 7, 8, 10], "dorian": [0, 2, 3, 5, 7, 9, 10],
    "phrygian": [0, 1, 3, 5, 7, 8, 10], "lydian": [0, 2, 4, 6, 7, 9, 11], "mixolydian": [0, 2, 4, 5, 7, 9, 10],
    "harmonic": [0, 2, 3, 5, 7, 8, 11], "phrygdom": [0, 1, 4, 5, 7, 8, 10],
}

CHORDS = {
    "maj7": [0, 4, 7, 11], "maj9": [0, 4, 7, 11, 14], "maj7s11": [0, 4, 7, 11, 18], "m7": [0, 3, 7, 10],
    "m9": [0, 3, 7, 10, 14], "m11": [0, 3, 7, 10, 14, 17], "7": [0, 4, 7, 10], "9": [0, 4, 7, 10, 14],
    "7b9": [0, 4, 7, 10, 13], "7sus4": [0, 5, 7, 10], "m7b5": [0, 3, 6, 10], "dim7": [0, 3, 6, 9],
    "add9": [0, 4, 7, 14], "sus2": [0, 2, 7, 14], "mM7": [0, 3, 7, 11], "m": [0, 3, 7, 14], "aug": [0, 4, 8, 11],
    "6": [0, 4, 7, 9], "m6": [0, 3, 7, 9],
}

# Two-bar melody rhythms as (start step, length) in 16ths across 32 steps.
RHYTHMS = [
    [(0, 6), (6, 2), (8, 4), (14, 2), (16, 6), (24, 8)],
    [(0, 3), (3, 3), (6, 2), (8, 8), (18, 2), (20, 4), (24, 4), (28, 4)],
    [(2, 2), (4, 4), (10, 2), (12, 4), (16, 2), (18, 2), (20, 6), (28, 4)],
    [(0, 8), (8, 4), (12, 4), (16, 12), (28, 4)],
    [(0, 2), (2, 2), (4, 4), (8, 2), (10, 6), (16, 3), (19, 3), (22, 2), (24, 8)],
    [(4, 4), (8, 4), (12, 2), (14, 2), (16, 8), (26, 2), (28, 4)],
]

# Wobble phrases, one bar each: (start, length, filter shape, octave, droop in semitones).
# "womp" is the namesake: WOMP (long), a (pickup), womp, womp (the last one sags).
WOBBLES = {
    "womp": [(0, 6, "womp", 0, 0), (6, 2, "blip", 0, 0), (8, 4, "womp", 0, 0), (12, 4, "womp", 0, -2)],
    "womp_hi": [(0, 6, "womp", 0, 0), (6, 2, "blip", 1, 0), (8, 4, "womp", 0, 0), (12, 4, "womp", 1, -3)],
    "wub": [(0, 4, "wub2", 0, 0), (4, 4, "wub2", 0, 0), (8, 2, "womp", 0, 0), (10, 2, "womp", 0, 0), (12, 4, "wub3", 0, -2)],
    "trip": [(0, 8, "wub3", 0, 0), (8, 8, "wub6", 0, -2)],
    "halt": [(0, 3, "womp", 0, 0), (3, 3, "womp", 0, 0), (6, 2, "blip", 1, 0), (10, 6, "wub2", 0, -2)],
    "lazy": [(0, 8, "womp", 0, 0), (10, 2, "blip", 0, 0), (12, 4, "womp", 0, -2)],
    "stutter": [(0, 2, "blip", 0, 0), (2, 2, "blip", 0, 0), (4, 4, "womp", 0, 0), (8, 6, "wub3", 0, 0), (14, 2, "blip", 1, 0)],
}
FILL = [(0, 4, "wub2", 0, 0), (4, 4, "wub4", 0, 0), (8, 4, "wub8", 0, 0), (12, 4, "accel", 0, -5)]

SECTIONS = [("intro", 0, 8), ("groove", 8, 16), ("build", 16, 20), ("drop", 20, 28), ("break", 28, 36),
            ("groove2", 36, 44), ("build2", 44, 48), ("drop2", 48, 56), ("outro", 56, 64)]


def section(bar):
    for name, a, b in SECTIONS:
        if a <= bar < b:
            return name, bar - a
    return "outro", 7


# ----------------------------------------------------------------------------
# The boards. tension: 0 = home-table chill ... 4 = the Grand Final.
# ----------------------------------------------------------------------------

BOARDS = {
    "local": dict(title="The Local", seq="pi", key=0, mode="major", bpm=72, tension=0,
                  prog=[(5, "maj7"), (4, "m7"), (2, "m9"), (0, "maj9")], cb=2, lead="ep", rhythm=(0, 3),
                  arp=6, swing=0.18, wob=dict(wave="saw", fmin=110, fmax=1400, q=3.0, drive=1.6),
                  drops=("lazy", "womp"), fx=["vinyl"]),
    "frozen": dict(title="Frozen Lake", seq="e", key=2, mode="lydian", bpm=68, tension=0,
                   prog=[(0, "maj9"), (2, "add9"), (11, "m9"), (7, "maj7s11")], cb=2, lead="glass", rhythm=(3, 0),
                   arp=5, swing=0.1, wob=dict(wave="square", fmin=120, fmax=1600, q=3.5, drive=1.5),
                   drops=("womp", "lazy"), fx=["ice", "sonar"]),
    "spring_st": dict(title="Spring Street", seq="fib", key=5, mode="mixolydian", bpm=78, tension=0.5,
                      prog=[(0, "9"), (10, "maj9"), (5, "maj7"), (7, "m7")], cb=2, lead="pluck", rhythm=(4, 1),
                      arp=7, swing=0.3, wob=dict(wave="saw", fmin=130, fmax=2200, q=4.5, drive=1.8),
                      drops=("womp", "halt"), fx=["boing"]),
    "drift": dict(title="The Drift", seq="collatz", key=9, mode="dorian", bpm=74, tension=0.5,
                  prog=[(0, "m9"), (5, "9"), (3, "maj7"), (10, "add9")], cb=2, lead="glide", rhythm=(3, 5),
                  arp=6, swing=0.2, wob=dict(wave="saw", fmin=100, fmax=1800, q=3.5, drive=1.7),
                  drops=("lazy", "wub"), fx=["water"]),
    "slate": dict(title="Old Slate", seq="prime_gaps", key=3, mode="minor", bpm=66, tension=1,
                  prog=[(0, "m9"), (8, "maj7"), (5, "m9"), (7, "7sus4")], cb=2, lead="ep", rhythm=(3, 0),
                  arp=5, swing=0.15, wob=dict(wave="saw", fmin=90, fmax=1500, q=3.0, drive=2.2),
                  drops=("lazy", "halt"), fx=["vinyl", "rumble"]),
    "cramped": dict(title="The Back Room", seq="look_and_say", key=8, mode="minor", bpm=76, tension=1.5,
                    prog=[(0, "m7"), (1, "maj7"), (0, "m7"), (11, "dim7")], cb=2, lead="chip", rhythm=(1, 4),
                    arp=7, swing=0.22, wob=dict(wave="square", fmin=110, fmax=2000, q=5.0, drive=2.0),
                    drops=("halt", "stutter"), fx=["hum", "tick"]),
    "parlor": dict(title="Pinball Parlor", seq="catalan", key=10, mode="major", bpm=82, tension=0.5,
                   prog=[(0, "maj9"), (9, "m7"), (2, "m7"), (7, "9")], cb=1, lead="chip", rhythm=(4, 2),
                   arp=5, swing=0.12, wob=dict(wave="square", fmin=140, fmax=2600, q=5.0, drive=1.8),
                   drops=("womp_hi", "stutter"), fx=["ding", "bleeps"]),
    "posts": dict(title="Twin Posts", seq="thue_morse", key=4, mode="dorian", bpm=76, tension=1,
                  prog=[(0, "m9"), (5, "9"), (0, "m9"), (7, "m7")], cb=2, lead="bell", rhythm=(1, 2),
                  arp=8, swing=0.2, canon=True, wob=dict(wave="saw", fmin=120, fmax=2000, q=4.0, drive=1.8),
                  drops=("womp", "womp_hi"), fx=["bleeps"]),
    "sinkhole": dict(title="The Sinkhole", seq="recaman", key=1, mode="phrygian", bpm=70, tension=2,
                     prog=[(0, "m9"), (1, "maj7"), (10, "m7"), (1, "maj7")], cb=2, lead="glide", rhythm=(3, 5),
                     arp=7, swing=0.12, wob=dict(wave="saw", fmin=80, fmax=2400, q=5.0, drive=2.4),
                     drops=("womp", "trip"), fx=["shepard", "drone"], sink808=True),
    "hump": dict(title="The Hump", seq="sqrt2", key=11, mode="dorian", bpm=74, tension=1.5,
                 prog=[(0, "m11"), (5, "9"), (8, "maj7"), (7, "m7")], cb=2, lead="flute", rhythm=(5, 1),
                 arp=5, swing=0.18, wob=dict(wave="saw", fmin=110, fmax=2200, q=4.0, drive=2.0),
                 drops=("halt", "womp_hi"), fx=["rise"]),
    "nineball": dict(title="Rotation Night", seq="triangular", key=2, mode="minor", bpm=75, tension=2,
                     prog=[(0, "m9"), (10, "maj7"), (8, "maj7"), (7, "7")], cb=2, lead="pluck", rhythm=(4, 0),
                     arp=9, swing=0.15, wob=dict(wave="square", fmin=100, fmax=2400, q=4.5, drive=2.2),
                     drops=("wub", "womp"), fx=["rotor", "bleeps"]),
    "magnet": dict(title="The Magnet Room", seq="phi", key=5, mode="harmonic", bpm=72, tension=2,
                   prog=[(0, "mM7"), (8, "maj7"), (1, "maj7"), (7, "7b9")], cb=2, lead="glide", rhythm=(0, 3),
                   arp=8, swing=0.12, wob=dict(wave="saw", fmin=90, fmax=2600, q=5.5, drive=2.3),
                   drops=("womp", "wub"), fx=["pull", "drone"]),
    "smoke": dict(title="The Smoke Room", seq="squares", key=10, mode="dorian", bpm=70, tension=1.5,
                  prog=[(0, "m9"), (5, "m9"), (8, "9"), (7, "7b9")], cb=2, lead="flute", rhythm=(1, 3),
                  arp=6, swing=0.34, vibrato=0.0, wob=dict(wave="saw", fmin=100, fmax=1700, q=3.5, drive=2.0),
                  drops=("lazy", "womp"), fx=["vinyl", "smoke"]),
    "blackice": dict(title="Black Ice", seq="sqrt3", key=6, mode="harmonic", bpm=68, tension=3,
                     prog=[(0, "m"), (1, "maj7"), (6, "m7b5"), (7, "7b9")], cb=2, lead="glass", rhythm=(3, 5),
                     arp=7, swing=0.08, wob=dict(wave="square", fmin=90, fmax=3000, q=6.0, drive=2.6),
                     drops=("trip", "womp"), fx=["ice", "drone", "geiger"]),
    "tilted": dict(title="The Tilted Table", seq="ln2", key=7, mode="lydian", bpm=74, tension=2.5,
                   prog=[(0, "maj9"), (2, "9"), (4, "m7"), (1, "maj7")], cb=2, lead="glide", rhythm=(2, 4),
                   arp=7, swing=0.14, tilt=True, wob=dict(wave="saw", fmin=100, fmax=2600, q=5.0, drive=2.3),
                   drops=("halt", "trip"), fx=["warble", "drone"]),
    "two": dict(title="Two Pockets", seq="twin_primes", key=0, mode="minor", bpm=76, tension=3,
                prog=[(0, "m9"), (6, "dim7"), (0, "m9"), (6, "7")], cb=2, lead="bell", rhythm=(1, 4),
                arp=6, swing=0.1, canon=True, wob=dict(wave="square", fmin=90, fmax=3000, q=6.0, drive=2.6),
                drops=("stutter", "womp_hi"), fx=["bleeps", "geiger"]),
    "closing": dict(title="Closing Time", seq="cyclic7", key=9, mode="minor", bpm=80, tension=3,
                    prog=[(0, "m9"), (11, "aug"), (10, "maj7"), (9, "m7b5")], cb=2, lead="ep", rhythm=(2, 0),
                    arp=7, swing=0.1, wob=dict(wave="saw", fmin=90, fmax=2800, q=5.5, drive=2.5),
                    drops=("womp", "stutter"), fx=["tick", "drone"]),
    "iron": dict(title="The Iron Rack", seq="cubes", key=4, mode="phrygian", bpm=66, tension=3,
                 prog=[(0, "m"), (1, "maj7"), (0, "m"), (10, "m7")], cb=2, lead="metal", rhythm=(3, 1),
                 arp=5, swing=0.06, wob=dict(wave="square", fmin=80, fmax=2800, q=6.5, drive=3.0),
                 drops=("halt", "trip"), fx=["anvil", "rumble", "drone"]),
    "lights": dict(title="Lights Out", seq="sqrt5", key=3, mode="minor", bpm=72, tension=3,
                   prog=[(0, "m9"), (8, "maj7"), (3, "maj7"), (10, "7sus4")], cb=2, lead="glass", rhythm=(5, 3),
                   arp=6, swing=0.1, dark=True, wob=dict(wave="saw", fmin=80, fmax=2400, q=5.5, drive=2.6),
                   drops=("lazy", "trip"), fx=["sonar", "geiger", "drone"]),
    "hustler": dict(title="The Hustler", seq="totient", key=7, mode="dorian", bpm=76, tension=2.5,
                    prog=[(0, "m7"), (5, "9"), (8, "7"), (7, "7b9")], cb=2, lead="chip", rhythm=(4, 1),
                    arp=6, swing=0.36, wob=dict(wave="saw", fmin=100, fmax=2400, q=4.5, drive=2.3),
                    drops=("womp", "halt"), fx=["coin", "vinyl"]),
    "elements": dict(title="The Element Table", seq="pascal7", key=2, mode="harmonic", bpm=78, tension=3.5,
                     prog=[(0, "m9"), (10, "maj7"), (7, "7b9"), (0, "mM7")], cb=2, lead="bell", rhythm=(0, 4),
                     arp=7, swing=0.1, wob=dict(wave="saw", fmin=90, fmax=3200, q=6.0, drive=2.8),
                     drops=("womp_hi", "trip"), fx=["elements", "drone"]),
    "hypotenuse": dict(title="The Hypotenuse", seq="sqrt2", key=9, mode="lydian", bpm=80, tension=0.5,
                   prog=[(0, "maj9"), (9, "m7"), (2, "m7"), (7, "9")], cb=1, lead="chip", rhythm=(4, 2),
                   arp=5, swing=0.12, wob=dict(wave="square", fmin=140, fmax=2600, q=5.0, drive=1.8),
                   drops=("womp_hi", "stutter"), fx=["ding", "bleeps"]),
    "benzene": dict(title="Benzene Ring", seq="catalan", key=4, mode="dorian", bpm=72, tension=0,
                   prog=[(0, "maj9"), (2, "add9"), (11, "m9"), (7, "maj7s11")], cb=2, lead="glass", rhythm=(3, 0),
                   arp=5, swing=0.1, wob=dict(wave="square", fmin=120, fmax=1600, q=3.5, drive=1.5),
                   drops=("womp", "lazy"), fx=["ice", "sonar"]),
    "pentagon": dict(title="Golden Pentagon", seq="phi", key=1, mode="lydian", bpm=70, tension=2,
                   prog=[(0, "mM7"), (8, "maj7"), (1, "maj7"), (7, "7b9")], cb=2, lead="glide", rhythm=(0, 3),
                   arp=8, swing=0.12, wob=dict(wave="saw", fmin=90, fmax=2600, q=5.5, drive=2.3),
                   drops=("womp", "wub"), fx=["pull", "drone"]),
    "lshell": dict(title="The L-Shell", seq="triangular", key=6, mode="mixolydian", bpm=78, tension=1,
                  prog=[(0, "m9"), (5, "9"), (0, "m9"), (7, "m7")], cb=2, lead="bell", rhythm=(1, 2),
                  arp=8, swing=0.2, canon=True, wob=dict(wave="saw", fmin=120, fmax=2000, q=4.0, drive=1.8),
                  drops=("womp", "womp_hi"), fx=["bleeps"]),
    "final": dict(title="The Grand Final", seq="one_81", key=4, mode="phrygdom", bpm=80, tension=4,
                  prog=[(0, "m9"), (1, "maj7"), (8, "maj7"), (7, "7b9")], cb=2, lead="bell", rhythm=(1, 4),
                  arp=8, swing=0.08, wob=dict(wave="saw", fmin=80, fmax=3600, q=6.5, drive=3.0),
                  drops=("womp", "stutter"), fx=["geiger", "drone", "sonar"]),
}


def slug(bid):
    return BOARDS[bid]["title"].lower().replace("'", "").replace(" ", "-")


# ----------------------------------------------------------------------------
# Synthesis helpers
# ----------------------------------------------------------------------------

def tvec(n):
    return np.arange(n) / SR


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def phase_of(freq):
    return TAU * np.cumsum(freq) / SR


def release(t, dur, rel):
    return np.where(t < dur, 1.0, np.exp(-(t - dur) * 5.0 / rel))


def sos(kind, f, order=2):
    return signal.butter(order, f, kind, fs=SR, output="sos")


SOS_SNARE = sos("bandpass", [700, 4800])
SOS_HAT = sos("highpass", 7000, 4)
SOS_CRASH = sos("highpass", 3500, 2)
SOS_NARROW = sos("lowpass", 350, 2)
SOS_HISS = sos("bandpass", [1500, 9000])
SOS_POP = sos("highpass", 1800)
SOS_LOW = sos("lowpass", 160)
SOS_BREATH = sos("bandpass", [1200, 5000])
SOS_HP_MASTER = sos("highpass", 28, 2)
SOS_WIND = sos("bandpass", [300, 1800])


def pan2(sig, pan):
    a = (pan + 1) * np.pi / 4
    return np.vstack([sig * np.cos(a), sig * np.sin(a)]) * math.sqrt(2)


# --- tuned instruments (mono) ---

def inst_ep(f, dur, vel, rng, **_):
    rel = 0.5
    n = int((dur + rel) * SR)
    t = tvec(n)
    ph = phase_of(f * (1 + 0.0013 * np.sin(TAU * 0.7 * t + rng.uniform(0, 6))))
    idx = (1.0 + 1.6 * vel) * np.exp(-t * 3.5) + 0.2
    y = np.sin(ph + idx * np.sin(ph)) + 0.1 * np.sin(14 * ph) * np.exp(-t * 28)
    return y * np.minimum(t / 0.003, 1) * np.exp(-t * 0.9) * release(t, dur, rel) * vel


def inst_bell(f, dur, vel, rng, **_):
    rel = 1.2
    n = int((dur + rel) * SR)
    t = tvec(n)
    ph = phase_of(np.full(n, f))
    y = np.sin(ph + 2.2 * np.exp(-t * 2.5) * np.sin(3.5 * ph)) + 0.25 * np.sin(2 * ph) * np.exp(-t * 3)
    return y * np.minimum(t / 0.002, 1) * np.exp(-t * 1.4) * release(t, dur, rel) * vel


def inst_glass(f, dur, vel, rng, **_):
    rel = 1.5
    n = int((dur + rel) * SR)
    t = tvec(n)
    y = np.zeros(n)
    for ratio, amp, dec in ((1, 1, 1.0), (2.756, 0.45, 2.2), (5.404, 0.22, 3.8), (8.933, 0.1, 6.0)):
        if f * ratio < 16000:
            y += amp * np.sin(TAU * f * ratio * t + rng.uniform(0, 6)) * np.exp(-t * dec)
    return y * np.minimum(t / 0.002, 1) * release(t, dur, rel) * vel


def inst_pluck(f, dur, vel, rng, **_):
    rel = 0.3
    n = int((dur + rel) * SR)
    t = tvec(n)
    y = np.zeros(n)
    for k in range(1, 13):
        if k * f > 12000:
            break
        y += (1 / k) * np.sin(TAU * k * f * t) * np.exp(-t * (2.5 + 1.6 * k))
    return y * np.minimum(t / 0.002, 1) * release(t, dur, rel) * vel


def inst_chip(f, dur, vel, rng, **_):
    rel = 0.2
    n = int((dur + rel) * SR)
    t = tvec(n)
    ph = phase_of(f * (1 + 0.004 * np.sin(TAU * 5.5 * t) * np.minimum(t / 0.3, 1)))
    y = sum((1 / k) * np.sin(k * ph) / (1 + (k * f / 2500) ** 2) for k in (1, 3, 5, 7, 9))
    return y * np.minimum(t / 0.003, 1) * (0.45 + 0.55 * np.exp(-t * 5)) * release(t, dur, rel) * vel


def inst_metal(f, dur, vel, rng, **_):
    rel = 0.8
    n = int((dur + rel) * SR)
    t = tvec(n)
    ph = phase_of(np.full(n, f))
    y = np.sin(ph + 3.0 * np.exp(-t * 6) * np.sin(1.41 * ph)) + 0.3 * np.sin(2.01 * ph) * np.exp(-t * 2)
    return y * np.minimum(t / 0.002, 1) * np.exp(-t * 1.6) * release(t, dur, rel) * vel


def inst_glide(f, dur, vel, rng, prev=None, vibrato=1.0, **_):
    """Theremin-ish line that slides in from the previous note: fields and pull."""
    rel = 0.3
    n = int((dur + rel) * SR)
    t = tvec(n)
    f0 = prev or f
    fv = f * (f0 / f) ** np.exp(-t / 0.035)
    vib = 1 + vibrato * 0.012 * np.sin(TAU * 5.3 * t) * np.clip((t - 0.15) / 0.3, 0, 1)
    ph = phase_of(fv * vib)
    y = np.sin(ph) + 0.22 * np.sin(2 * ph) + 0.08 * np.sin(3 * ph)
    return y * np.minimum(t / 0.04, 1) * release(t, dur, rel) * vel


def inst_flute(f, dur, vel, rng, vibrato=1.0, **_):
    rel = 0.25
    n = int((dur + rel) * SR)
    t = tvec(n)
    ph = phase_of(f * (1 + vibrato * 0.008 * np.sin(TAU * 4.8 * t) * np.clip((t - 0.2) / 0.4, 0, 1)))
    breath = signal.sosfilt(SOS_BREATH, rng.standard_normal(n)) * 0.12
    y = np.sin(ph) + 0.18 * np.sin(2 * ph) + 0.05 * np.sin(3 * ph) + breath * (0.5 + np.exp(-t * 6))
    return y * np.minimum(t / 0.06, 1) * release(t, dur, rel) * vel


LEADS = {"ep": inst_ep, "bell": inst_bell, "glass": inst_glass, "pluck": inst_pluck, "chip": inst_chip,
         "metal": inst_metal, "glide": inst_glide, "flute": inst_flute}


def inst_pad(f, dur, vel, cutoff, rng):
    rel = 1.4
    n = int((dur + rel) * SR)
    t = tvec(n)
    out = np.zeros((2, n))
    for ch, det in enumerate((-0.0045, 0.0045)):
        ph = phase_of(f * (1 + det) * (1 + 0.001 * np.sin(TAU * 0.27 * t + rng.uniform(0, 6)))) + rng.uniform(0, 6)
        for k in range(1, 18):
            if k * f > cutoff * 4:
                break
            out[ch] += (1 / k) / math.sqrt(1 + (k * f / cutoff) ** 4) * np.sin(k * ph)
    env = np.minimum(t / 0.9, 1) * release(t, dur, rel)
    return out * env * vel


def inst_808(f0, f1, dur, glide_at, punch=True):
    rel = 0.06
    n = int((dur + rel) * SR)
    t = tvec(n)
    g = np.clip((t - glide_at) / 0.09, 0, 1)
    fv = f0 * (f1 / f0) ** (g * g * (3 - 2 * g))
    if punch:
        fv = fv * (1 + 1.2 * np.exp(-t * 45))
    y = np.tanh(2.4 * np.sin(phase_of(fv)))
    amp = np.minimum(t / 0.002, 1) * np.exp(-t * 0.9) * np.where(t < dur, 1, np.clip(1 - (t - dur) / rel, 0, 1))
    return y * amp


def shape_curve(shape, p):
    if shape == "womp":
        pk = 0.28
        return np.where(p < pk, (p / pk) ** 0.6, ((1 - p) / (1 - pk)) ** 1.4)
    if shape == "blip":
        return np.sin(np.pi * p) ** 0.8
    if shape == "accel":
        return 0.5 - 0.5 * np.cos(TAU * 7 * p * p)
    if shape.startswith("wub"):
        return 0.5 - 0.5 * np.cos(TAU * int(shape[3:]) * p)
    return p


def inst_wobble(f0, dur, shape, droop, wp):
    """Additive resonant-filter bass: every harmonic is weighted by a moving
    resonant low-pass, so the filter can sweep per sample without a slow loop."""
    rel = 0.03
    n = int((dur + rel) * SR)
    t = tvec(n)
    p = np.clip(t / dur, 0, 1)
    fv = np.full(n, f0)
    if droop:
        fv = f0 * 2 ** (droop * np.clip((p - 0.45) / 0.55, 0, 1) ** 1.5 / 12)
    fv = fv * (1 + 0.04 * np.exp(-t * 60))
    ph = phase_of(fv)
    fc = wp["fmin"] * (wp["fmax"] / wp["fmin"]) ** shape_curve(shape, p)
    q = wp["q"]
    y = np.zeros(n)
    odd = wp["wave"] == "square"
    for k in range(1, int(min(9000 / f0, 150)) + 1):
        if odd and k % 2 == 0:
            continue
        r = k * fv / fc
        # Two resonant 2-pole stages (24 dB/oct) so the closed filter really closes: that's the "wow".
        y += (1 / k) / ((1 - r * r) ** 2 + (r / q) ** 2) * np.sin(k * ph)
    y /= np.max(np.abs(y)) + 1e-9
    drive = 1 + (wp["drive"] - 1) * 0.6
    y = np.tanh(y * drive) / math.tanh(drive)
    amp = np.minimum(t / 0.004, 1) * np.where(t < dur * 0.95, 1, np.clip(1 - (t - dur * 0.95) / (rel + dur * 0.05), 0, 1))
    return (0.75 * y + 0.55 * np.sin(ph)) * amp


# --- drums (mono) ---

def drum_kick(rng, hard):
    n = int(0.55 * SR)
    t = tvec(n)
    f = 46 + (120 if hard else 75) * np.exp(-t * 32)
    y = np.sin(phase_of(f)) * np.exp(-t * (6.0 if hard else 8.5))
    y += 0.25 * rng.standard_normal(n) * np.exp(-t * 350)
    return np.tanh(y * (1.8 if hard else 1.2))


def drum_snare(rng):
    n = int(0.4 * SR)
    t = tvec(n)
    body = signal.sosfilt(SOS_SNARE, rng.standard_normal(n)) * np.exp(-t * 24)
    return body * 1.6 + np.sin(TAU * 190 * t) * np.exp(-t * 28) * 0.5


def drum_clap(rng):
    n = int(0.45 * SR)
    t = tvec(n)
    nz = signal.sosfilt(SOS_SNARE, rng.standard_normal(n))
    env = np.zeros(n)
    for off in (0.0, 0.011, 0.022):
        env += np.where(t >= off, np.exp(-(t - off) * 140), 0)
    env += np.where(t >= 0.03, 0.6 * np.exp(-(t - 0.03) * 11), 0)
    return nz * env * 1.5


def drum_rim(rng):
    n = int(0.12 * SR)
    t = tvec(n)
    return (np.sin(TAU * 820 * t) * 0.6 + rng.standard_normal(n) * 0.3) * np.exp(-t * 60)


def drum_hat(rng, open_=False):
    n = int((0.45 if open_ else 0.09) * SR)
    t = tvec(n)
    y = signal.sosfilt(SOS_HAT, rng.standard_normal(n))
    return y * np.exp(-t * (7 if open_ else 65)) * 1.6


def fx_crash(rng, seconds=3.5):
    n = int(seconds * SR)
    t = tvec(n)
    return signal.sosfilt(SOS_CRASH, rng.standard_normal((2, n)), axis=1) * np.exp(-t * 1.6)


def fx_impact(rng):
    n = int(3.0 * SR)
    t = tvec(n)
    boom = np.sin(phase_of(30 + 60 * np.exp(-t * 3))) * np.exp(-t * 1.5)
    return np.tanh(boom * 1.5)


def fx_riser(rng, seconds, top=7000):
    n = int(seconds * SR)
    t = tvec(n)
    x = t / seconds
    out = np.zeros((2, n))
    fc = 250 * (top / 250) ** (x ** 1.6)
    for ch in range(2):
        nz = signal.sosfilt(SOS_NARROW, rng.standard_normal(n)) * 4
        out[ch] = nz * np.sin(phase_of(fc * (1 + 0.01 * ch)))
    tone = np.sin(phase_of(110 * 2 ** (x * 3))) * 0.25
    return (out + tone) * x ** 2.2


# --- the science sounds ---

def fx_sine_blip(f, dur, rng, decay=40.0, square=False):
    n = int((dur + 0.02) * SR)
    t = tvec(n)
    y = np.sin(TAU * f * t)
    if square:
        y = np.tanh(y * 3)
    return y * np.minimum(t / 0.002, 1) * np.exp(-t * decay)


def fx_sonar(rng):
    n = int(2.5 * SR)
    t = tvec(n)
    return np.sin(TAU * 1180 * t) * np.minimum(t / 0.004, 1) * np.exp(-t * 2.2)


def fx_boing(rng):
    n = int(0.9 * SR)
    t = tvec(n)
    f = 220 * (1 + 0.35 * np.sin(TAU * 13 * t) * np.exp(-t * 3)) * (1 + 0.6 * np.exp(-t * 8))
    return np.sin(phase_of(f)) * np.exp(-t * 4)


def fx_ice(rng):
    n = int(0.6 * SR)
    t = tvec(n)
    snap = signal.sosfilt(SOS_POP, rng.standard_normal(n)) * np.exp(-t * 90)
    ping = np.sin(phase_of(3200 * np.exp(-t * 6) + 900)) * np.exp(-t * 9) * 0.4
    return snap + ping


def fx_bubble(rng):
    n = int(0.08 * SR)
    t = tvec(n)
    f0 = rng.uniform(300, 700)
    return np.sin(phase_of(f0 * (1 + 3 * t / 0.08))) * np.sin(np.pi * t / 0.08)


def fx_ding(rng, f):
    n = int(0.8 * SR)
    t = tvec(n)
    return (np.sin(TAU * f * t) + 0.5 * np.sin(TAU * f * 2.0 * t) * np.exp(-t * 6)) * np.exp(-t * 5)


def fx_coin(rng):
    n = int(0.5 * SR)
    t = tvec(n)
    return np.where(t < 0.06, np.sin(TAU * 1975 * t), np.sin(TAU * 2637 * t)) * np.exp(-t * 7)


def fx_tick(rng, tock):
    n = int(0.05 * SR)
    t = tvec(n)
    return np.sin(TAU * (2100 if tock else 2900) * t) * np.exp(-t * 180) + rng.standard_normal(n) * np.exp(-t * 400) * 0.3


def fx_anvil(rng):
    n = int(1.2 * SR)
    t = tvec(n)
    y = sum(a * np.sin(TAU * f * t) * np.exp(-t * d) for f, a, d in ((523, 1, 3), (1410, 0.6, 5), (2213, 0.4, 7), (3389, 0.25, 9)))
    return y + rng.standard_normal(n) * np.exp(-t * 200) * 0.5


def fx_pull(rng, f):
    n = int(1.6 * SR)
    t = tvec(n)
    fv = f * 2 ** (-7 / 12 * np.exp(-t * 3.5))
    return (np.sin(phase_of(fv)) + 0.3 * np.sin(2 * phase_of(fv))) * np.sin(np.pi * np.clip(t / 1.6, 0, 1)) ** 2


def fx_shepard(seconds, rng, up=False):
    """Endless glissando: octave-spaced partials glide inside a fixed bell curve."""
    n = int(seconds * SR)
    t = tvec(n)
    y = np.zeros(n)
    rate = 1 / 6.0
    for k in range(7):
        pos = (k / 7 + (rate * t if up else -rate * t)) % 1.0
        f = 40 * 2 ** (pos * 7)
        amp = np.exp(-((pos - 0.5) ** 2) / 0.04)
        y += amp * np.sin(phase_of(f))
    return y / 3


# ----------------------------------------------------------------------------
# The composer
# ----------------------------------------------------------------------------

LEVELS = {
    #          intro groove build drop break groove2 build2 drop2 outro
    "pad":    (0.85, 0.7, 0.8, 0.45, 0.9, 0.7, 0.85, 0.45, 0.8),
    "keys":   (0.75, 0.85, 0.55, 0.3, 0.9, 0.85, 0.55, 0.3, 0.75),
    "lead":   (0.0, 0.85, 0.4, 0.5, 0.6, 0.95, 0.4, 0.6, 0.45),
    "arp":    (0.0, 0.3, 0.7, 0.55, 0.0, 0.65, 0.8, 0.6, 0.0),
    "crackle": (1.0, 0.55, 0.4, 0.3, 1.0, 0.55, 0.4, 0.3, 1.0),
}
SECTION_NAMES = [s[0] for s in SECTIONS]


class Board:
    def __init__(self, bid):
        self.id = bid
        self.s = BOARDS[bid]
        self.rng = np.random.default_rng(zlib.crc32(bid.encode()))
        self.bpm = self.s["bpm"]
        self.step_s = 60.0 / self.bpm / 4
        self.L = int(round(BARS * 16 * self.step_s * SR))
        self.N = self.L + TAIL
        self.tension = self.s["tension"]
        self.key = self.s["key"]
        self.scale = SCALES[self.s["mode"]]
        self.seq = SEQUENCES[self.s["seq"]](256)
        names = ["kick", "snare", "hats", "sub", "wob", "pad", "keys", "lead", "arp", "fx", "riser", "impact", "crackle"]
        self.bus = {k: np.zeros((2, self.N), np.float32) for k in names}
        self.kicks = []
        self.kit = {
            "kick_soft": [drum_kick(self.rng, False) for _ in range(3)],
            "kick_hard": [drum_kick(self.rng, True) for _ in range(3)],
            "snare": [drum_snare(self.rng) for _ in range(3)], "clap": [drum_clap(self.rng) for _ in range(2)],
            "rim": [drum_rim(self.rng) for _ in range(2)],
            "hat": [drum_hat(self.rng) for _ in range(6)], "ohat": [drum_hat(self.rng, True) for _ in range(2)],
        }

    # --- time and placement ---
    def pos(self, step, swing=True):
        if swing and abs(step - round(step)) < 1e-6 and int(round(step)) % 2 == 1:
            step += self.s["swing"] * 0.5
        return int(round(step * self.step_s * SR))

    def place(self, bus, sig, pos, pan=0.0, gain=1.0):
        buf = self.bus[bus]
        if pos >= self.N or pos < 0:
            return
        if sig.ndim == 1:
            sig = pan2(sig, pan)
        n = min(sig.shape[1], self.N - pos)
        buf[:, pos:pos + n] += (sig[:, :n] * gain).astype(np.float32)

    def hit(self, bus, name, step, vel, pan=0.0, swing=True, rate=1.0):
        smp = self.kit[name][self.rng.integers(len(self.kit[name]))]
        if rate != 1.0:
            smp = np.interp(np.arange(0, len(smp) - 1, rate), np.arange(len(smp)), smp)
        p = self.pos(step, swing)
        self.place(bus, smp, p, pan, vel)
        if name.startswith("kick"):
            self.kicks.append((p, vel))

    # --- harmony ---
    def chord(self, bar):
        root, q = self.s["prog"][(bar // self.s["cb"]) % len(self.s["prog"])]
        pc = (self.key + root) % 12
        return pc, CHORDS[q]

    def chord_pcs(self, bar):
        pc, ivs = self.chord(bar)
        return {(pc + i) % 12 for i in ivs}

    def voicing(self, bar, low=52, high=76):
        pc, ivs = self.chord(bar)
        notes = []
        for iv in ivs:
            m = 48 + pc + iv
            while m < low:
                m += 12
            while m >= high:
                m -= 12
            notes.append(m)
        return sorted(set(notes))

    def bass_midi(self, bar):
        pc, _ = self.chord(bar)
        return 31 + (pc - 7) % 12

    def lvl(self, layer, bar):
        name, _ = section(bar)
        return LEVELS[layer][SECTION_NAMES.index(name)]

    # --- melody from the board's sequence ---
    def motif(self, bar0, rhythm, off, prev, cadence=False):
        ev = []
        for i, (st, ln) in enumerate(rhythm):
            bar = bar0 + st // 16
            d = self.seq[(off + i) % len(self.seq)]
            pc = (self.key + self.scale[d % 7]) % 12
            if st % 8 == 0 or (cadence and i == len(rhythm) - 1):
                pcs = self.chord_pcs(bar)
                if cadence and i == len(rhythm) - 1:
                    pcs = {self.chord(bar)[0]}
                if pc not in pcs:
                    pc = min(pcs, key=lambda c: min((c - pc) % 12, (pc - c) % 12))
            cands = [m for m in range(60, 92) if m % 12 == pc]
            m = min(cands, key=lambda c: abs(c - prev) + (6 if c > 86 or c < 64 else 0))
            vel = 0.8 + (0.12 if st % 8 == 0 else 0) + self.rng.uniform(-0.06, 0.06)
            ev.append((bar0 * 16 + st, ln, m, vel))
            prev = m
        return ev, prev

    def phrase(self, bar0, var):
        ra, rb = RHYTHMS[self.s["rhythm"][0]], RHYTHMS[self.s["rhythm"][1]]
        off = var * 23
        ev, prev = [], 72 + (3 if var else 0)
        for k, (r, o, cad) in enumerate(((ra, off, False), (ra, off + 4, False), (ra, off, False), (rb, off + 9, True))):
            e, prev = self.motif(bar0 + 2 * k, r, o, prev, cad)
            ev += e
        return ev

    def play_lead(self, events, gain, pan=0.0, octave=0, inst=None, delay_pan=None):
        fn = LEADS[inst or self.s["lead"]]
        prev = None
        vib = self.s.get("vibrato", 1.0)
        for st, ln, m, vel in events:
            m += 12 * octave
            f = hz(m)
            if self.s.get("tilt"):
                f *= 2 ** (self.rng.uniform(-0.25, 0.25) / 12)
            sig = fn(f, ln * self.step_s * 0.95, vel, self.rng, prev=prev, vibrato=vib)
            self.place("lead", sig, self.pos(st), pan, gain)
            prev = f

    # --- arranging ---
    def compose(self):
        s = self.s
        tension = self.tension
        rng = self.rng
        # Pads and keys follow the chords everywhere.
        cutoff = 900 + 500 * (1 - min(tension, 3) / 3) if not s.get("dark") else 650
        cb = s["cb"]
        for bar in range(0, BARS, cb):
            dur = cb * 16 * self.step_s
            notes = self.voicing(bar, 50, 74)
            g = self.lvl("pad", bar)
            for m in notes:
                self.place("pad", inst_pad(hz(m), dur, 0.25, cutoff, rng), self.pos(bar * 16, False), gain=g)
            if tension >= 2.5:   # a semitone rub high above the chord keeps the tense boards uneasy
                pc, _ = self.chord(bar)
                self.place("pad", inst_pad(hz(72 + pc + 1), dur, 0.05, cutoff, rng), self.pos(bar * 16, False), gain=g)
        for bar in range(BARS):
            name, rel = section(bar)
            g = self.lvl("keys", bar)
            notes = self.voicing(bar)
            if name in ("drop", "drop2"):
                hits = [(0, 2), (6, 2), (10, 2)] if rel % 2 == 0 else [(0, 3), (8, 2)]
            elif name in ("build", "build2"):
                hits = [(0, 4), (8, 4)] if rel < 3 else [(0, 2), (4, 2), (8, 2)]
            elif bar % 2 == 0:
                hits = [(0, 10), (10, 6)]
            else:
                hits = [(2, 6), (12, 4)]
            if name == "intro" and rel == 0:
                hits = [(0, 16)]
            for st, ln in hits:
                for j, m in enumerate(notes):
                    strum = j * 0.012 * SR
                    self.place("keys", inst_ep(hz(m), ln * self.step_s * 0.9, 0.55, rng),
                               self.pos(bar * 16 + st) + int(strum), pan=(j / max(1, len(notes) - 1) - 0.5) * 0.6, gain=g)
        # Lead melody.
        for bar0, var in ((8, 0), (36, 1)):
            ev = self.phrase(bar0, var)
            self.play_lead(ev, self.lvl("lead", bar0), pan=-0.15 if s.get("canon") else 0.05)
            if s.get("canon"):   # twin voice: the same line a beat late, an octave up, across the stereo field
                self.play_lead([(st + 4, ln, m, v * 0.7) for st, ln, m, v in ev], 0.55, pan=0.6, octave=1,
                               inst="glass" if s["lead"] != "glass" else "bell")
            if var == 1:          # groove 2 adds a diatonic third underneath
                harm = []
                for st, ln, m, v in ev:
                    deg = min(range(7), key=lambda i: abs((self.key + self.scale[i] - m) % 12))
                    below = (self.key + self.scale[(deg - 2) % 7]) % 12
                    mm = m - ((m - below) % 12 or 12)
                    harm.append((st, ln, mm, v * 0.6))
                self.play_lead(harm, 0.5, pan=-0.3)
        # Break: the hook comes back slow and bare.
        ev = self.phrase(28, 2)
        self.play_lead([(st, ln + 2, m, v * 0.8) for st, ln, m, v in ev if (st // 16) >= 30], self.lvl("lead", 30), pan=0.1)
        # Drops: the lead answers the wobble between phrases.
        for b0 in (20, 48):
            ev = self.phrase(b0, 3)
            ev = [e for e in ev if (e[0] // 16 - b0) % 4 == 3 or (e[0] % 16) >= 12]
            self.play_lead(ev, self.lvl("lead", b0), pan=0.2, octave=1 if tension < 3 else 0)
        # Outro: the first motif one last time, fading into the intro.
        ev = self.phrase(56, 0)
        self.play_lead([e for e in ev if e[0] < 61 * 16], 0.45)
        self.arps()
        self.drums()
        self.bass()
        self.science()

    def arps(self):
        n = self.s["arp"]
        pattern = [self.seq[i] for i in range(n)]
        for bar in range(BARS):
            g = self.lvl("arp", bar)
            if g <= 0:
                continue
            name, rel = section(bar)
            ext = self.voicing(bar, 62, 86)
            ext = ext + [m + 12 for m in ext if m + 12 < 96]
            for st in range(16):
                if name in ("groove",) and st % 2 == 1:
                    continue
                gstep = bar * 16 + st
                idx = pattern[gstep % n] % len(ext)
                vel = 0.55 if gstep % n == 0 else 0.35
                if name in ("build", "build2"):
                    vel *= 0.4 + 0.6 * (rel * 16 + st) / 64
                sig = inst_pluck(hz(ext[idx]), self.step_s * 0.8, vel, self.rng)
                pan = math.sin(gstep * TAU / n) * 0.55
                self.place("arp", sig, self.pos(gstep), pan, g)

    def hat_bar(self, bar, grid, roll_p, vel=1.0, opens=True):
        rng = self.rng
        roll_beats = [b for b in range(4) if rng.random() < roll_p]
        if bar % 4 == 3 and roll_p > 0:
            roll_beats = sorted(set(roll_beats + [3]))
        for st in range(0, 16, grid):
            if st // 4 in roll_beats:
                continue
            v = 0.75 if st % 4 == 0 else (0.55 if st % 2 == 0 else 0.4)
            self.hit("hats", "hat", bar * 16 + st, v * vel, pan=0.18)
        for b in roll_beats:
            kind = rng.choice(["32", "trip16", "trip8", "half"], p=[0.35, 0.3, 0.15, 0.2])
            base = bar * 16 + b * 4
            if kind == "32":
                ts = [base + i * 0.5 for i in range(8)]
            elif kind == "trip16":
                ts = [base + i * 4 / 6 for i in range(6)]
            elif kind == "trip8":
                ts = [base + i * 4 / 3 for i in range(3)]
            else:
                ts = [base, base + 1] + [base + 2 + i * 0.5 for i in range(4)]
            for i, ts_ in enumerate(ts):
                self.hit("hats", "hat", ts_, (0.3 + 0.5 * i / len(ts)) * vel, pan=0.18 - 0.4 * i / len(ts), swing=False)
        if opens and bar % 2 == 1:
            self.hit("hats", "ohat", bar * 16 + 14, 0.45 * vel, pan=-0.2)

    def drums(self):
        t = self.tension
        chill_kicks = [[0, 7, 10], [0, 10], [0, 3, 10], [0, 7, 10, 13]]
        trap_kicks = [[0, 3, 10], [0, 6, 11], [0, 7, 10, 14], [0, 3, 6, 11]]
        for bar in range(BARS):
            name, rel = section(bar)
            if name == "intro":
                if rel >= 4:
                    self.hat_bar(bar, 4 if rel < 6 else 2, 0, vel=0.35 + 0.08 * (rel - 4), opens=False)
            elif name in ("groove", "groove2", "outro"):
                if name == "outro" and rel >= 4:
                    if rel < 6:
                        self.hat_bar(bar, 2 if rel == 4 else 4, 0, vel=0.4 - 0.1 * (rel - 4), opens=False)
                    continue
                v = 0.7 if name == "outro" else 0.85
                for st in chill_kicks[bar % 4]:
                    self.hit("kick", "kick_soft", bar * 16 + st, v)
                self.hit("snare", "snare", bar * 16 + 8, v)
                if bar % 2 == 1:
                    self.hit("snare", "rim", bar * 16 + 15, 0.35 * v, pan=-0.2)
                roll = 0.08 + 0.06 * t + (0.12 if name == "groove2" else 0)
                self.hat_bar(bar, 2, roll, vel=v)
            elif name in ("build", "build2"):
                for st in range(0, 16, 4):
                    if rel < 3:
                        self.hit("kick", "kick_soft", bar * 16 + st, 0.6 + 0.1 * rel)
                div = [4, 2, 1, 0.5][rel]
                st = 0.0
                while st < 16:
                    if rel == 3 and st >= 12:
                        break
                    prog = (rel * 16 + st) / 60
                    self.hit("snare", "snare", bar * 16 + st, 0.3 + 0.6 * prog, swing=False, rate=1 + 0.6 * prog)
                    st += div
                hgrid = [2, 2, 1, 1][rel]
                for hs in range(0, 16 if rel < 3 else 12, hgrid):
                    self.hit("hats", "hat", bar * 16 + hs, 0.35 + 0.1 * rel)
                if rel == 0:
                    secs = 4 * 16 * self.step_s - 4 * self.step_s
                    self.place("riser", fx_riser(self.rng, secs, 5000 + 1000 * t), self.pos(bar * 16, False))
                if rel == 3:
                    crash = fx_crash(self.rng, 1.2)[:, ::-1] * np.linspace(0, 1, int(1.2 * SR)) ** 2
                    self.place("riser", crash, self.pos(bar * 16 + 16, False) - crash.shape[1], gain=0.6)
            elif name in ("drop", "drop2"):
                if rel == 0:
                    self.place("impact", fx_impact(self.rng), self.pos(bar * 16, False))
                    self.place("impact", fx_crash(self.rng), self.pos(bar * 16, False), gain=0.5)
                pat = trap_kicks[(bar + (2 if name == "drop2" else 0)) % 4]
                for st in pat:
                    self.hit("kick", "kick_hard", bar * 16 + st, 1.0)
                self.hit("snare", "clap", bar * 16 + 8, 0.9, pan=0.05)
                self.hit("snare", "snare", bar * 16 + 8, 0.6)
                if rel % 4 == 3:
                    self.hit("snare", "snare", bar * 16 + 14, 0.35)
                    self.hit("snare", "snare", bar * 16 + 15, 0.5)
                roll = 0.3 + 0.08 * t + (0.1 if name == "drop2" else 0)
                self.hat_bar(bar, 1 if t >= 2 or name == "drop2" else 2, roll)
            elif name == "break":
                if rel >= 4:
                    self.hit("kick", "kick_soft", bar * 16, 0.55)
                    self.hit("snare", "rim", bar * 16 + 8, 0.45, pan=-0.15)
                    if rel >= 6:
                        self.hat_bar(bar, 4, 0, vel=0.3, opens=False)

    def bass(self):
        wp = self.s["wob"]
        sink = self.s.get("sink808")
        for bar in range(BARS):
            name, rel = section(bar)
            root = self.bass_midi(bar)
            nxt = self.bass_midi(bar + 1)
            if name in ("groove", "groove2") or (name == "outro" and rel < 3):
                kicks = [[0, 7, 10], [0, 10], [0, 3, 10], [0, 7, 10, 13]][bar % 4]
                for i, st in enumerate(kicks):
                    end = kicks[i + 1] if i + 1 < len(kicks) else 16
                    dur = (end - st) * self.step_s * 0.95
                    last = i == len(kicks) - 1
                    f1 = hz(nxt) if last and bar % 2 == 1 else hz(root)
                    if sink and last:
                        f1 = hz(root - 5)
                    sig = inst_808(hz(root), f1, dur, dur * 0.6)
                    self.place("sub", sig, self.pos(bar * 16 + st), gain=0.65 if name != "outro" else 0.45)
                if bar % 4 == 2:
                    self.place("sub", inst_808(hz(root + 12), hz(root), 2 * self.step_s, self.step_s, False),
                               self.pos(bar * 16 + 14), gain=0.5)
            elif name in ("drop", "drop2"):
                if rel in (3, 7):
                    if rel == 7:
                        phrase = FILL
                    else:   # trap 808 fill: slides and an octave pop
                        fill = [(0, 3, root, root), (3, 3, root, root), (6, 2, root + 12, root),
                                (8, 4, root + 7, root + 7), (12, 4, root, root - 12 if not sink else root - 7)]
                        for st, ln, a, b in fill:
                            dur = ln * self.step_s * 0.95
                            self.place("sub", inst_808(hz(a), hz(b), dur, dur * 0.5), self.pos(bar * 16 + st), gain=1.0)
                        continue
                else:
                    which = self.s["drops"][0 if rel < 3 else 1]
                    if name == "drop2":
                        which = self.s["drops"][1 if rel < 3 else 0]
                    phrase = WOBBLES[which]
                for st, ln, shape, octv, droop in phrase:
                    m = root + 12 * octv
                    sig = inst_wobble(hz(m), ln * self.step_s, shape, droop, wp)
                    self.place("wob", sig, self.pos(bar * 16 + st, False))

    def science(self):
        fx = self.s["fx"]
        rng = self.rng
        sp = self.step_s
        bed = np.zeros(self.L)   # continuous beds stay exactly one loop long so the seam doesn't double them
        t = tvec(self.L)
        bar_of = (t / (16 * sp)).astype(int)
        sec_idx = np.array([SECTION_NAMES.index(section(b)[0]) for b in range(BARS + 1)])[np.minimum(bar_of, BARS)]

        def by_section(values):
            return np.array(values)[sec_idx]
        if "geiger" in fx:
            rate = by_section([2.5, 1.5, 12, 6, 3, 2, 14, 7, 2.5]) * (0.6 + 0.15 * self.tension)
            clicks = rng.random(self.L) < rate / SR
            imp = np.where(clicks, rng.uniform(0.3, 1.0, self.L), 0)
            click = np.exp(-tvec(60) * 4000) * np.sign(rng.standard_normal(60))
            bed += signal.oaconvolve(imp, click)[:self.L] * 0.7
        if "hum" in fx:
            lv = by_section([1, 0.4, 0.3, 0.2, 1, 0.4, 0.3, 0.2, 1])
            bed += (np.sin(TAU * 60 * t) + 0.4 * np.sin(TAU * 120 * t) + 0.25 * np.sign(np.sin(TAU * 120 * t)) * 0.3) * 0.05 * lv
        if "drone" in fx:
            pc = self.key % 12
            f = hz(36 + pc)
            lv = by_section([0.9, 0.5, 0.8, 0.3, 1, 0.5, 0.9, 0.3, 0.9])
            dr = np.sin(TAU * f * t) + 0.5 * np.sin(TAU * f * 1.5 * t + np.sin(TAU * 0.07 * t)) + 0.3 * np.sin(TAU * f * 2.03 * t)
            bed += dr * 0.08 * lv * (0.7 + 0.3 * np.sin(TAU * t / (8 * 16 * sp)))
        if "warble" in fx:
            lv = by_section([1, 0.4, 0.6, 0.2, 1, 0.4, 0.6, 0.2, 1])
            f = hz(60 + self.key) * 2 ** (0.4 * np.sin(TAU * t / (4 * 16 * sp)) / 12)
            bed += np.sin(phase_of(f)) * np.sin(phase_of(f * 1.007)) * 0.06 * lv
        if "rumble" in fx or "elements" in fx:
            lv = by_section([0.5, 0.3, 0.6, 0.8, 0.5, 0.3, 0.6, 0.8, 0.5])
            if "elements" in fx:   # earth rumbles under the drops
                lv = by_section([0, 0, 0.4, 1, 0, 0, 0.4, 1, 0])
            bed += signal.sosfilt(SOS_LOW, rng.standard_normal(self.L)) * 0.5 * lv
        if "smoke" in fx or "elements" in fx:   # slow smoke (or air) breathing in the background
            lv = by_section([1, 0.4, 0.3, 0.1, 1, 0.4, 0.3, 0.1, 1])
            if "elements" in fx:
                lv = by_section([1, 0, 0, 0, 0, 0, 0, 0, 1])
            swell = 0.5 + 0.5 * np.sin(TAU * t / (2 * 16 * sp))
            bed += signal.sosfilt(SOS_WIND, rng.standard_normal(self.L)) * 0.12 * swell * lv
        if "shepard" in fx:
            lv = by_section([1, 0.35, 0.8, 0.2, 1, 0.35, 0.8, 0.2, 1])
            bed += fx_shepard(self.L / SR, rng) * 0.12 * lv
        if "vinyl" in fx:
            lv = by_section([1, 0.5, 0.4, 0.3, 1, 0.5, 0.4, 0.3, 1])
            pops = np.where(rng.random(self.L) < 6 / SR, rng.uniform(0.2, 1, self.L), 0)
            bed += signal.sosfilt(SOS_POP, pops) * 0.25 * lv
        self.place("fx", bed, 0, 0.0)

        for bar in range(BARS):
            name, rel = section(bar)
            quiet = name in ("intro", "break", "outro")
            pb = bar * 16
            if "sonar" in fx and quiet and rel % 4 == 0:
                self.place("fx", fx_sonar(rng), self.pos(pb + 2, False), pan=rng.uniform(-0.6, 0.6), gain=0.5)
            if "ice" in fx and (quiet or name.startswith("groove")) and rng.random() < 0.7:
                self.place("fx", fx_ice(rng), self.pos(pb + rng.integers(16), False), pan=rng.uniform(-0.8, 0.8), gain=0.5)
            if "boing" in fx and rel % 4 == 3 and name in ("groove", "groove2", "break"):
                self.place("fx", fx_boing(rng), self.pos(pb + 14, False), pan=rng.uniform(-0.5, 0.5), gain=0.45)
            if "water" in fx or "elements" in fx:
                if ("water" in fx and (quiet or name.startswith("groove"))) or ("elements" in fx and name == "break"):
                    for _ in range(rng.integers(2, 6)):
                        self.place("fx", fx_bubble(rng), self.pos(pb + rng.uniform(0, 16), False), pan=rng.uniform(-0.8, 0.8), gain=0.35)
            if "elements" in fx and name in ("groove", "groove2"):   # fire: crackling embers
                for _ in range(rng.integers(6, 14)):
                    self.place("fx", fx_ice(rng)[:int(0.05 * SR)], self.pos(pb + rng.uniform(0, 16), False), pan=rng.uniform(-0.8, 0.8), gain=0.3)
            if "ding" in fx and not quiet and rng.random() < 0.6:
                f = hz(84 + (self.key + self.scale[self.seq[bar] % 7]) % 12)
                self.place("fx", fx_ding(rng, f), self.pos(pb + rng.choice([6, 10, 14])), pan=rng.uniform(-0.7, 0.7), gain=0.35)
            if "coin" in fx and rel % 4 == 3 and name in ("groove", "groove2", "break"):
                self.place("fx", fx_coin(rng), self.pos(pb + 12), pan=0.4, gain=0.4)
            if "bleeps" in fx and bar % 2 == 1 and name in ("groove", "groove2", "break", "build"):
                for i in range(int(rng.integers(4, 9))):
                    m = 84 + (self.key + self.scale[self.seq[(bar + i) % len(self.seq)] % 7]) % 12
                    self.place("fx", fx_sine_blip(hz(m), 0.045, rng, 60, True), self.pos(pb + 12 + i * 0.5, False), pan=0.5 - i * 0.12, gain=0.25)
            if "rotor" in fx and not name.startswith("drop"):
                for i in range(0, 16, 2):
                    g = pb + i
                    pan = math.sin(TAU * (g % 9) / 9)
                    if g % 9 in (0, 4):
                        self.place("fx", fx_sine_blip(hz(96 + self.key % 12), 0.03, rng, 80), self.pos(g), pan=pan, gain=0.25)
            if "tick" in fx:
                lv = 0.5 if quiet else 0.3
                step = 4 if name not in ("build", "build2") else [4, 2, 2, 1][rel]
                for i in np.arange(0, 16, step):
                    self.place("fx", fx_tick(rng, int(i // step) % 2 == 1), self.pos(pb + i, False), pan=0.3, gain=lv)
            if "anvil" in fx and name in ("groove", "groove2", "drop", "drop2") and bar % 2 == 1:
                self.place("fx", fx_anvil(rng), self.pos(pb + 12), pan=-0.3, gain=0.35)
            if "pull" in fx and quiet and rel % 2 == 0:
                f = hz(72 + (self.key + self.scale[self.seq[bar] % 7]) % 12)
                self.place("fx", fx_pull(rng, f), self.pos(pb + 4, False), pan=rng.uniform(-0.6, 0.6), gain=0.35)
            if "rise" in fx and quiet and rel % 2 == 1:
                n = int(0.5 * SR)
                tt = tvec(n)
                sweep = np.sin(phase_of(hz(72 + self.key) * 2 ** (tt / 0.5 * 12 / 12))) * np.sin(np.pi * tt / 0.5)
                self.place("fx", sweep, self.pos(pb + 10, False), pan=rng.uniform(-0.6, 0.6), gain=0.25)

    # --- mixing ---
    def automation(self, keys):
        bars = np.array([k[0] for k in keys], float)
        vals = np.array([k[1] for k in keys], float)
        x = np.arange(self.N) / SR / (16 * self.step_s)
        return np.interp(x, bars, vals).astype(np.float32)

    def sidechain(self):
        imp = np.zeros(self.N, np.float32)
        for p, v in self.kicks:
            if p < self.N:
                imp[p] += v
        kern = np.exp(-tvec(int(0.4 * SR)) / 0.11).astype(np.float32)
        env = np.minimum(signal.oaconvolve(imp, kern)[:self.N], 1.0)
        depth = self.automation([(0, 0.3), (20, 0.3), (20, 0.55), (28, 0.55), (28, 0.3), (48, 0.3), (48, 0.6), (56, 0.6), (56, 0.3), (64, 0.3)])
        return 1 - depth * env

    def mix(self):
        tense = min(self.tension, 4) / 4
        targets = {"kick": -15, "snare": -19, "hats": -27 + 2 * tense, "sub": -17, "wob": -16 + 2.5 * tense,
                   "pad": -25, "keys": -21, "lead": -20, "arp": -27, "fx": -28, "riser": -24, "impact": -19, "crackle": -44}
        b = self.bus
        # Lo-fi hiss and crackle bed (one loop long).
        lv = self.automation([(i, v) for i, v in zip([0, 8, 16, 20, 28, 36, 44, 48, 56, 64],
                                                      [1, 0.55, 0.4, 0.3, 1, 0.55, 0.4, 0.3, 1, 1])])[:self.L]
        hiss = signal.sosfilt(SOS_HISS, self.rng.standard_normal((2, self.L)), axis=1) * 0.3
        pops = np.where(self.rng.random(self.L) < 3 / SR, self.rng.uniform(0.3, 1, self.L), 0)
        crack = signal.sosfilt(SOS_POP, pops)
        b["crackle"][:, :self.L] += ((hiss + crack) * lv).astype(np.float32)
        for k, tgt in targets.items():
            x = b[k]
            m = x.mean(0)
            blk = int(0.05 * SR)
            nb = len(m) // blk
            r = np.sqrt((m[:nb * blk].reshape(nb, blk) ** 2).mean(1))
            if r.max() <= 0:
                continue
            active = r[r > r.max() * 0.08]
            cur = 20 * np.log10(np.sqrt((active ** 2).mean()) + 1e-12)
            b[k] = x * np.float32(10 ** ((tgt - cur) / 20))
        # Lead ping-pong delay (dotted 8th).
        d = int(3 * self.step_s * SR)
        lead = b["lead"]
        dly = np.zeros_like(lead)
        mono = lead.mean(0)
        for i in range(1, 5):
            ch = i % 2
            dly[ch, i * d:] += mono[:self.N - i * d] * (0.38 ** i)
        dly = signal.sosfilt(sos("lowpass", 3500), dly, axis=1).astype(np.float32)
        sc = self.sidechain()
        music = (b["pad"] + b["keys"] + b["lead"] + 0.6 * dly + b["arp"]) * sc
        bright = self.automation([(0, 0.25), (6, 0.5), (8, 1), (16, 1), (16, 0.3), (19.75, 1), (28, 1), (28, 0.45),
                                  (35, 0.7), (36, 1), (44, 1), (44, 0.3), (47.75, 1), (56, 1), (60, 0.55), (64, 0.25), (70, 0.25)])
        if self.s.get("dark"):
            bright *= 0.75
        lp = signal.sosfiltfilt(sos("lowpass", 650), music, axis=1).astype(np.float32)
        music = lp * (1 - bright) + music * bright
        gap = self.automation([(0, 1), (19.75, 1), (19.76, 0.12), (19.99, 0.12), (20, 1), (47.75, 1), (47.76, 0.12), (47.99, 0.12), (48, 1)])
        music *= gap
        # Reverb.
        ir_len = 2.8 if self.tension < 2 else 3.4
        n = int(ir_len * SR)
        t = tvec(n)
        ir = self.rng.standard_normal((2, n)) * np.exp(-t * 6.9 / ir_len)
        ir = signal.sosfilt(sos("lowpass", 5000), ir, axis=1)
        ir = np.concatenate([np.zeros((2, int(0.025 * SR))), ir], axis=1)
        ir /= np.sqrt((ir ** 2).sum(1, keepdims=True))
        send = music * 0.45 + b["snare"] * 0.12 +b["fx"] * 0.55 + b["riser"] * 0.3 + b["lead"] * 0.25 * gap
        wet = np.vstack([signal.oaconvolve(send[c], ir[c])[:self.N] for c in range(2)]).astype(np.float32)
        out = (music + wet * 0.5 + b["kick"] + b["snare"] + b["hats"] + b["sub"] * sc ** 0.5 + b["wob"]
               + b["fx"] + b["riser"] * gap + b["impact"] + b["crackle"])
        # Fold the tail onto the start: a seamless loop.
        mixed = out[:, :self.L].astype(np.float64)
        mixed[:, :TAIL] += out[:, self.L:]
        mixed = signal.sosfilt(SOS_HP_MASTER, mixed, axis=1)
        # Master: level, then a gentle tape-style limiter.
        rms = np.sqrt((mixed ** 2).mean())
        mixed *= 10 ** (-15.5 / 20) / rms
        ceiling = 0.89
        return ceiling * np.tanh(mixed / ceiling)

    def render(self):
        self.compose()
        return self.mix()


# ----------------------------------------------------------------------------
# Output
# ----------------------------------------------------------------------------

def write_wav(path, x):
    pcm = (np.clip(x, -1, 1) * 32767).astype("<i2").T.copy()
    with open(path, "wb") as f:
        data = pcm.tobytes()
        f.write(b"RIFF" + struct.pack("<I", 36 + len(data)) + b"WAVEfmt " +
                struct.pack("<IHHIIHH", 16, 1, 2, SR, SR * 4, 4, 16) + b"data" + struct.pack("<I", len(data)) + data)


def write_png(path, img):
    h, w = img.shape
    raw = b"".join(b"\x00" + img[y].astype(np.uint8).tobytes() for y in range(h))

    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 0, 0, 0, 0)) +
                chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def inspect(bid, x, out_dir, bpm):
    mono = x.mean(0)
    bar_len = 16 * (60 / bpm / 4) * SR
    rms = [20 * np.log10(np.sqrt((mono[int(b * bar_len):int((b + 1) * bar_len)] ** 2).mean()) + 1e-9) for b in range(BARS)]
    f, t, z = signal.stft(mono[::2], fs=SR // 2, nperseg=1024, noverlap=512)
    mag = 20 * np.log10(np.abs(z) + 1e-7)
    keep = f < 8000
    mag = mag[keep][::-1]
    cols = 1200
    idx = np.linspace(0, mag.shape[1] - 1, cols).astype(int)
    img = np.clip((mag[:, idx] + 100) / 80 * 255, 0, 255)
    write_png(os.path.join(out_dir, f"{bid}.png"), img)
    seam = float(np.abs(x[:, 0] - x[:, -1]).max())
    return {"bar_rms_db": [round(r, 1) for r in rms], "peak": float(np.abs(x).max()), "seam_jump": seam}


def render_one(args):
    bid, out_dir, inspect_dir, quality = args
    board = Board(bid)
    x = board.render()
    os.makedirs(out_dir, exist_ok=True)
    wav_dir = inspect_dir or out_dir
    wav = os.path.join(wav_dir, f"{slug(bid)}.wav")
    write_wav(wav, x)
    ogg = os.path.join(out_dir, f"{slug(bid)}.ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", str(quality), ogg], check=True)
    info = {"id": bid, "title": BOARDS[bid]["title"], "file": os.path.basename(ogg), "bpm": board.bpm,
            "seconds": round(x.shape[1] / SR, 2), "sequence": BOARDS[bid]["seq"], "tension": board.tension}
    if inspect_dir:
        info.update(inspect(bid, x, inspect_dir, board.bpm))
    else:
        os.remove(wav)
    return info


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("boards", nargs="*", help="board ids (default: all)")
    ap.add_argument("--out", default=os.path.join(ROOT, "assets", "music", "boards"))
    ap.add_argument("--inspect", help="keep WAVs here and write spectrograms and a level report")
    ap.add_argument("--quality", type=float, default=2.5, help="Vorbis quality (-q:a)")
    ap.add_argument("--jobs", type=int, default=4)
    a = ap.parse_args()
    ids = a.boards or list(BOARDS)
    for bid in ids:
        if bid not in BOARDS:
            sys.exit(f"unknown board: {bid}")
    if a.inspect:
        os.makedirs(a.inspect, exist_ok=True)
    jobs = [(bid, a.out, a.inspect, a.quality) for bid in ids]
    with ProcessPoolExecutor(max_workers=min(a.jobs, len(jobs))) as ex:
        results = list(ex.map(render_one, jobs))
    for r in results:
        print(f"{r['id']:10s} {r['title']:24s} {r['bpm']:3d} bpm  {int(r['seconds']) // 60}:{int(r['seconds']) % 60:02d}  {r['sequence']}")
        if a.inspect:
            print("    bars dB:", " ".join(f"{v:.0f}" for v in r["bar_rms_db"]), f"| peak {r['peak']:.2f} seam {r['seam_jump']:.3f}")
    if a.inspect:
        with open(os.path.join(a.inspect, "report.json"), "w") as f:
            json.dump(results, f, indent=1)


if __name__ == "__main__":
    main()
