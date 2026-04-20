#!/usr/bin/env python3
"""Slice a Mechvibes single-file pack into KeyMochi's multi-file format.

Input pack layout:
  <pack_dir>/sound.ogg  (or sound.wav already)
  <pack_dir>/config.json with key_define_type="single"
    and defines[linux_scancode] = [start_ms, dur_ms]

Output (rewrites <pack_dir> in place):
  <pack_dir>/<cgKeyCode>.wav        one per press-defined key
  <pack_dir>/<cgKeyCode>-up.wav     one per release-defined key (if any)
  <pack_dir>/config.json            rewritten as multi-file

The Mechvibes source uses Linux evdev scancodes; we translate to macOS
CGKeyCode (US ANSI layout). Keys we don't map are skipped.

Usage:
  preprocess_mechvibes_single.py <pack_dir> <pack_id> <name> <character> <author>
"""
import json
import os
import shutil
import subprocess
import sys
import wave


LINUX_TO_MAC = {
    1: 53,                                       # Escape
    2: 18, 3: 19, 4: 20, 5: 21, 6: 23,           # 1 2 3 4 5
    7: 22, 8: 26, 9: 28, 10: 25, 11: 29,         # 6 7 8 9 0
    12: 27, 13: 24,                              # - =
    14: 51, 15: 48,                              # Backspace, Tab
    16: 12, 17: 13, 18: 14, 19: 15, 20: 17,      # Q W E R T
    21: 16, 22: 32, 23: 34, 24: 31, 25: 35,      # Y U I O P
    26: 33, 27: 30,                              # [ ]
    28: 36,                                      # Return
    29: 59,                                      # LCtrl
    30: 0, 31: 1, 32: 2, 33: 3, 34: 5,           # A S D F G
    35: 4, 36: 38, 37: 40, 38: 37, 39: 41,       # H J K L ;
    40: 39, 41: 50,                              # ' `
    42: 56, 43: 42,                              # LShift, \
    44: 6, 45: 7, 46: 8, 47: 9, 48: 11,          # Z X C V B
    49: 45, 50: 46, 51: 43, 52: 47, 53: 44,      # N M , . /
    54: 60,                                      # RShift
    56: 58, 57: 49, 58: 57,                      # LAlt, Space, CapsLock
    59: 122, 60: 120, 61: 99, 62: 118, 63: 96,   # F1..F5
    64: 97, 65: 98, 66: 100, 67: 101, 68: 109,   # F6..F10
    87: 103, 88: 111,                            # F11, F12
    97: 62, 100: 61,                             # RCtrl, RAlt
    102: 115, 103: 126, 104: 116, 105: 123,      # Home, Up, PageUp, Left
    106: 124, 107: 119, 108: 125, 109: 121,      # Right, End, Down, PageDown
    110: 114, 111: 117, 125: 55,                 # Insert, FwdDelete, LCmd
}


def ensure_wav(pack_dir: str, source_filename: str) -> str:
    """Return path to sound.wav, converting from the source audio via ffmpeg if needed."""
    wav_path = os.path.join(pack_dir, "sound.wav")
    if os.path.exists(wav_path):
        return wav_path
    src = os.path.join(pack_dir, source_filename)
    if not os.path.exists(src):
        raise SystemExit(f"no {source_filename} in {pack_dir}")
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error",
         "-i", src,
         "-ar", "48000", "-ac", "1", "-sample_fmt", "s16",
         wav_path],
        check=True)
    return wav_path


def slice_wav(src_path, start_ms, duration_ms, dst_path):
    with wave.open(src_path, "rb") as r:
        rate = r.getframerate()
        channels = r.getnchannels()
        width = r.getsampwidth()
        r.setpos(int(start_ms * rate / 1000))
        frames = r.readframes(int(duration_ms * rate / 1000))
    with wave.open(dst_path, "wb") as w:
        w.setnchannels(channels)
        w.setsampwidth(width)
        w.setframerate(rate)
        w.writeframes(frames)


def main():
    if len(sys.argv) != 6:
        raise SystemExit(__doc__)
    pack_dir, pack_id, pack_name, character, author = sys.argv[1:6]
    with open(os.path.join(pack_dir, "config.json")) as f:
        src = json.load(f)
    wav_path = ensure_wav(pack_dir, src.get("sound", "sound.ogg"))

    press, release, skipped = {}, {}, []
    for k, v in src["defines"].items():
        if v is None:
            continue
        start_ms, dur_ms = v
        is_release = k.endswith("-up")
        linux_code = int(k[:-3] if is_release else k)
        mac_code = LINUX_TO_MAC.get(linux_code)
        if mac_code is None:
            skipped.append(linux_code)
            continue
        suffix = "-up" if is_release else ""
        fname = f"{mac_code}{suffix}.wav"
        slice_wav(wav_path, start_ms, dur_ms, os.path.join(pack_dir, fname))
        (release if is_release else press)[str(mac_code)] = [fname]

    with open(os.path.join(pack_dir, "config.json"), "w") as f:
        json.dump({
            "id": pack_id,
            "name": pack_name,
            "author": author,
            "character": character,
            "version": "1",
            "sound_format": "wav",
            "key_define_type": "multi",
            "defines": press,
            "release_defines": release,
            "spatial_layout": "qwerty_us",
        }, f, indent=2)

    os.remove(wav_path)
    # Remove whatever source audio we ended up using so the output dir
    # only contains the multi-file WAVs + rewritten config.json.
    source_filename = src.get("sound", "sound.ogg")
    source_path = os.path.join(pack_dir, source_filename)
    if os.path.exists(source_path):
        os.remove(source_path)

    print(f"{pack_id}: {len(press)} press + {len(release)} release slices"
          + (f" (skipped {len(set(skipped))} unmapped)" if skipped else ""))


if __name__ == "__main__":
    main()
