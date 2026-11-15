#!/usr/bin/env python3
"""Pocket Science sound effects: physically modelled, no samples.

Renders the table sounds from simple models of the real materials and writes
small Ogg files to assets/sfx/, a bank script (src/audio/sfx_bank.gd) that tells
the game which files belong to which sound, and a loudness report.

  Ball on ball   modal synthesis of a phenolic-resin sphere: a contact pulse that
                 excites a handful of inharmonic resonant modes, harder hits
                 shorten the pulse and bring out the high modes
  Cushion        a rubber thump with a falling pitch over the wooden rail body
  Pocket         a sequence: rim knock, rattles down the jaw, the gutter roll,
                 and a clack into the balls already there
  Cue strike     a leather tip on phenolic plus the cue's wooden thrum
  Rolling        a seamless loop of cloth noise (pitch and volume follow speed in game)

Usage (Python with NumPy + SciPy, ffmpeg with libvorbis on PATH):
    py -3.12 tools/compose_sfx.py
"""
import json
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np
from scipy.signal import butter, lfilter

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sfx")


# ------------------------------------------------------------------ building blocks
def t_axis(length):
    return np.arange(int(length * SR)) / SR


def lowpass(x, hz, order=2):
    b, a = butter(order, min(hz / (SR / 2), 0.99), "low")
    return lfilter(b, a, x)


def highpass(x, hz, order=2):
    b, a = butter(order, hz / (SR / 2), "high")
    return lfilter(b, a, x)


def bandpass(x, lo, hi, order=2):
    b, a = butter(order, [lo / (SR / 2), min(hi / (SR / 2), 0.99)], "band")
    return lfilter(b, a, x)


def place(buf, sound, at):
    i = int(at * SR)
    j = min(len(buf), i + len(sound))
    buf[i:j] += sound[: j - i]
    return buf


def fade_edges(x, fade_in=0.0004, fade_out=0.008):
    n_in, n_out = int(fade_in * SR), int(fade_out * SR)
    if n_in:
        x[:n_in] *= np.linspace(0, 1, n_in)
    if n_out:
        x[-n_out:] *= np.linspace(1, 0, n_out)
    return x


# ------------------------------------------------------------------ the models
def ball_hit(strength, rng, base=None, length=0.14):
    """A phenolic ball struck by another: inharmonic modes rung by a contact pulse."""
    t = t_axis(length)
    f0 = (base or 3050.0) * rng.uniform(0.95, 1.05)
    ratios = [1.0, 1.58, 2.21, 2.93, 3.67, 4.62]
    # Contact time: a hard hit is a shorter pulse, which reaches the higher modes.
    tau = 0.00012 + 0.00035 * (1.0 - strength)
    attack = 1.0 - np.exp(-t / tau)
    out = np.zeros_like(t)
    for k, r in enumerate(ratios):
        f = f0 * r * rng.uniform(0.985, 1.015)
        # How strongly the pulse excites this mode: roll-off above 1 / (2 tau).
        excite = 1.0 / (1.0 + (f * tau * 2.2) ** 2)
        amp = excite / (1.0 + 0.55 * k) * rng.uniform(0.7, 1.0)
        decay = rng.uniform(55, 85) * (r ** 0.6)
        out += amp * np.sin(2 * np.pi * f * t + rng.uniform(0, 6.28)) * np.exp(-decay * t)
    # The dull knock of the two bodies meeting, under the ring.
    body_f = rng.uniform(820, 1080)
    out += 0.35 * np.sin(2 * np.pi * body_f * t) * np.exp(-180 * t)
    # A tiny burst of contact noise, brighter when harder.
    noise = rng.standard_normal(len(t)) * np.exp(-t / (0.0012 + 0.002 * strength))
    out += 0.25 * strength * highpass(noise, 2500 + 3000 * strength)
    # Softer hits sound duller: the cloth and air take the top off.
    out = lowpass(out * attack, 3200 + 7500 * strength)
    return fade_edges(out)


def cushion_hit(strength, rng, length=0.26):
    """Rubber nose and wooden rail: a low thump with a falling pitch, little ring."""
    t = t_axis(length)
    f = rng.uniform(115, 150) * (1.0 + 0.6 * np.exp(-t * 40))
    phase = 2 * np.pi * np.cumsum(f) / SR
    thump = np.sin(phase) * np.exp(-t * rng.uniform(22, 30))
    rubber = np.sin(2 * np.pi * rng.uniform(340, 460) * t) * np.exp(-t * 55) * 0.45
    wood = bandpass(rng.standard_normal(len(t)), 180, 420) * np.exp(-t * 35) * 0.5
    contact = ball_hit(0.25 + 0.4 * strength, rng, base=2400, length=length) * (0.12 + 0.18 * strength)
    out = thump + rubber + wood + contact
    out = lowpass(out, 1800 + 2600 * strength)
    return fade_edges(out)


def pocket_drop(side, rng, length=0.95):
    """A ball going down: rim knock, rattles in the jaw, the gutter roll, a clack."""
    buf = np.zeros(int(length * SR))
    place(buf, ball_hit(0.55, rng, base=1900) * 0.75 + cushion_hit(0.6, rng)[: int(0.14 * SR)] * 0.5, 0.0)
    at = 0.0
    for k in range(1 if side else rng.integers(2, 4)):
        at += rng.uniform(0.035, 0.07)
        place(buf, cushion_hit(0.4, rng) * (0.45 - 0.12 * k), at)
    # The roll down the return gutter: filtered noise with a rolling flutter.
    start = at + 0.06
    roll_len = (0.32 if side else 0.45) + rng.uniform(0.0, 0.1)
    tr = t_axis(roll_len)
    env = np.sin(np.pi * np.clip(tr / roll_len, 0, 1)) ** 1.5
    flutter = 0.7 + 0.3 * np.sin(2 * np.pi * rng.uniform(16, 24) * tr)
    gutter = bandpass(rng.standard_normal(len(tr)), 160, 900) * env * flutter * 0.32
    place(buf, gutter, start)
    # Clack into the balls already waiting at the end of the gutter.
    place(buf, ball_hit(0.35, rng) * 0.28, min(start + roll_len - 0.02, length - 0.15))
    return fade_edges(buf, fade_out=0.04)


def cue_strike(strength, rng, length=0.2, brk=False):
    """A leather tip on a phenolic ball, and the cue's wooden thrum."""
    t = t_axis(length)
    tip = lowpass(rng.standard_normal(len(t)), 1500 + 2500 * strength) * np.exp(-t / 0.004)
    knock = np.sin(2 * np.pi * rng.uniform(620, 760) * t) * np.exp(-t * 90) * 0.6
    thrum = np.sin(2 * np.pi * rng.uniform(190, 250) * t) * np.exp(-t * 28) * (0.25 + 0.25 * strength)
    out = tip * 0.9 + knock + thrum
    out += ball_hit(0.3 + 0.5 * strength, rng, length=length) * (0.15 + 0.25 * strength)
    if brk:
        # A break: a sharper crack and the low thud of the whole rack moving.
        out += ball_hit(1.0, rng, length=length) * 0.6
        out += np.sin(2 * np.pi * 90 * t) * np.exp(-t * 18) * 0.5
    return fade_edges(out)


def roll_loop(rng, length=2.0):
    """Cloth noise for rolling balls, crossfaded so it loops without a seam."""
    n = int(length * SR)
    xf = int(0.2 * SR)
    raw = rng.standard_normal(n + xf)
    brown = np.cumsum(raw)
    brown -= lowpass(brown, 8, 1)
    x = bandpass(brown, 90, 700) + 0.15 * bandpass(raw, 700, 2200)
    t = np.arange(n + xf) / SR
    x *= 0.8 + 0.12 * np.sin(2 * np.pi * 7 * t) + 0.08 * np.sin(2 * np.pi * 13 * t)
    head, tail = x[:xf], x[n:n + xf]
    ramp = np.linspace(0, 1, xf)
    out = x[:n].copy()
    out[:xf] = head * ramp + tail * (1 - ramp)
    return out


# ------------------------------------------------------------------ levels and files
# Target loudness (RMS dBFS over the loud part) by sound, then peaks capped at -1 dBFS.
TARGET_RMS = {"click_soft": -30, "click": -24, "click_hard": -19, "rail_soft": -30, "rail": -25, "rail_hard": -20,
              "pocket": -24, "pocket_side": -24, "cue_soft": -28, "cue": -23, "cue_hard": -19, "break": -16, "roll": -26}


def rms_db(x):
    loud = x[np.abs(x) > np.max(np.abs(x)) * 0.05] if np.max(np.abs(x)) > 0 else x
    return 20 * np.log10(np.sqrt(np.mean(loud ** 2)) + 1e-12)


def level(x, target):
    x = x * 10 ** ((target - rms_db(x)) / 20)
    peak = np.max(np.abs(x))
    cap = 10 ** (-1 / 20)
    return x * (cap / peak) if peak > cap else x


def write_ogg(x, path):
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "s.wav")
        with wave.open(wav, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes((np.clip(x, -1, 1) * 32767).astype(np.int16).tobytes())
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "5", path], check=True)


def centroid(x):
    spec = np.abs(np.fft.rfft(x))
    freqs = np.fft.rfftfreq(len(x), 1 / SR)
    return float(np.sum(freqs * spec) / (np.sum(spec) + 1e-12))


def main():
    os.makedirs(OUT, exist_ok=True)
    rng = np.random.default_rng(2026)
    bank = {}
    report = []
    jobs = []
    for name, s in [("click_soft", 0.2), ("click", 0.55), ("click_hard", 1.0)]:
        jobs += [(name, k, (lambda s=s: ball_hit(s, rng))) for k in range(6)]
    for name, s in [("rail_soft", 0.2), ("rail", 0.55), ("rail_hard", 1.0)]:
        jobs += [(name, k, (lambda s=s: cushion_hit(s, rng))) for k in range(4)]
    jobs += [("pocket", k, (lambda: pocket_drop(False, rng))) for k in range(5)]
    jobs += [("pocket_side", k, (lambda: pocket_drop(True, rng))) for k in range(4)]
    for name, s in [("cue_soft", 0.25), ("cue", 0.6), ("cue_hard", 1.0)]:
        jobs += [(name, k, (lambda s=s: cue_strike(s, rng))) for k in range(3)]
    jobs += [("break", k, (lambda: cue_strike(1.0, rng, length=0.4, brk=True))) for k in range(3)]
    jobs += [("roll", 0, (lambda: roll_loop(rng)))]
    for name, k, make in jobs:
        x = level(make(), TARGET_RMS[name])
        fname = "%s_%d.ogg" % (name, k)
        write_ogg(x, os.path.join(OUT, fname))
        bank.setdefault(name, []).append("res://assets/sfx/" + fname)
        report.append((name, k, 20 * np.log10(np.max(np.abs(x)) + 1e-12), rms_db(x), centroid(x), len(x) / SR))
    # The bank: which files make up each sound.
    lines = ["class_name SfxBank", "## Written by tools/compose_sfx.py: the rendered variants of each sound.", "", "const FILES := {"]
    for name, files in bank.items():
        lines.append('\t"%s": [%s],' % (name, ", ".join('"%s"' % f for f in files)))
    lines.append("}")
    with open(os.path.join(ROOT, "src", "audio", "sfx_bank.gd"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    # The report: every file's peak, loudness, brightness and length.
    rep = ["# Sound effects report", "", "Written by `tools/compose_sfx.py`. Peaks must stay at or below -1 dBFS.", "",
           "| Sound | Variant | Peak dBFS | Loudness (RMS dBFS) | Brightness (centroid Hz) | Length s |", "|---|---|---|---|---|---|"]
    bad = 0
    for name, k, pk, r, c, ln in report:
        rep.append("| %s | %d | %.1f | %.1f | %.0f | %.2f |" % (name, k, pk, r, c, ln))
        if pk > -0.9:
            bad += 1
    with open(os.path.join(ROOT, "docs", "SFX_REPORT.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(rep) + "\n")
    total = sum(os.path.getsize(os.path.join(OUT, f)) for f in os.listdir(OUT) if f.endswith(".ogg"))
    print("rendered %d files, %.0f KB, %d over peak" % (len(report), total / 1024, bad))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
