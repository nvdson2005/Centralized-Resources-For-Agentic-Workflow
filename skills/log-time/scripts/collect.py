#!/usr/bin/env python3
"""Collect agent-session activity (Claude Code + Copilot CLI) as normalized JSON.

Usage: collect.py [--date YYYY-MM-DD] [--idle-min 10]
Only today and yesterday are allowed (Clockify retroactive rule).
Read-only. Prints a JSON list, one record per (session, day).
"""
import argparse, glob, json, os, re, sqlite3, sys
from collections import Counter
from datetime import datetime, timedelta, timezone

HOME = os.path.expanduser("~")
def _markers():
    base = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
    for name in ("config.json", "config.example.json"):
        try:
            return tuple(json.load(open(os.path.join(base, name)))["billing_client"]["repo_markers"])
        except (OSError, KeyError, ValueError):
            continue
    return ()


REPO_MARKERS = _markers()
PARENT_ID_RE = re.compile(r"#?(\d{9,})")
GH_RE = re.compile(r"(?:GH)?#(\d{1,6})\b")


def parse_ts(s):
    return datetime.fromisoformat(s.replace("Z", "+00:00")).astimezone()


def active_minutes(stamps, idle_min):
    """Sum gaps <= idle threshold; 1 min credit per work burst."""
    stamps = sorted(stamps)
    total, prev = 0.0, None
    for t in stamps:
        if prev is None or (t - prev) > timedelta(minutes=idle_min):
            total += 1
        else:
            total += (t - prev).total_seconds() / 60
        prev = t
    return round(total)


def hints(*texts):
    blob = " ".join(t for t in texts if t)
    return {
        "parent_ids": sorted(set(PARENT_ID_RE.findall(blob))),
        "gh_issues": sorted(set(GH_RE.findall(blob))),
    }


def claude_sessions(day, idle):
    out = []
    for path in glob.glob(f"{HOME}/.claude/projects/*/*.jsonl"):
        if datetime.fromtimestamp(os.path.getmtime(path)).astimezone().date() < day:
            continue
        stamps, cwds, branches, prompts, title, touched = [], Counter(), Counter(), [], None, False
        sid = os.path.basename(path)[:-6]
        for line in open(path, errors="ignore"):
            try:
                o = json.loads(line)
            except ValueError:
                continue
            t = o.get("type")
            if t == "ai-title":
                title = o.get("aiTitle") or o.get("title") or title
            if t not in ("user", "assistant") or "timestamp" not in o:
                continue
            ts = parse_ts(o["timestamp"])
            if ts.date() != day:
                continue
            stamps.append(ts)
            if o.get("cwd"):
                cwds[o["cwd"]] += 1
            if o.get("gitBranch"):
                branches[o["gitBranch"]] += 1
            msg = o.get("message") or {}
            content = msg.get("content")
            if t == "user" and (o.get("origin") or {}).get("kind") == "human" and isinstance(content, str):
                prompts.append(content[:300])
            if t == "assistant" and isinstance(content, list):
                for b in content:
                    if isinstance(b, dict) and b.get("type") == "tool_use":
                        inp = b.get("input", {})
                        s = " ".join(str(inp.get(k, "")) for k in
                                     ("file_path", "path", "notebook_path", "projectPath"))
                        if any(m in s for m in REPO_MARKERS):
                            touched = True
        if not stamps:
            continue
        cwd = cwds.most_common(1)[0][0] if cwds else ""
        branch = branches.most_common(1)[0][0] if branches else ""
        out.append({
            "tool": "claude-code", "session": sid, "date": str(day), "cwd": cwd,
            "branch": branch, "title": title, "first_prompt": prompts[0] if prompts else "",
            "start": min(stamps).strftime("%H:%M"), "end": max(stamps).strftime("%H:%M"),
            "active_min": active_minutes(stamps, idle),
            "repo_touched": touched or any(m in cwd for m in REPO_MARKERS),
            "hints": hints(cwd, branch, " ".join(prompts)),
        })
    return out


def copilot_sessions(day, idle):
    db = f"{HOME}/.copilot/session-store.db"
    if not os.path.exists(db):
        return []
    con = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
    sess = {r[0]: r for r in con.execute("select id,cwd,repository,branch,summary from sessions")}
    by = {}
    for sid, ts, um in con.execute("select session_id,timestamp,user_message from turns"):
        t = parse_ts(ts)
        if t.date() == day:
            by.setdefault(sid, []).append((t, um or ""))
    out = []
    for sid, rows in by.items():
        _, cwd, repo, branch, summary = sess.get(sid, (sid, "", "", "", ""))
        cwd = cwd or ""
        stamps = [r[0] for r in rows]
        prompts = [r[1] for r in rows if r[1]]
        out.append({
            "tool": "copilot-cli", "session": sid, "date": str(day), "cwd": cwd,
            "branch": branch or "", "title": summary, "first_prompt": (prompts[0] if prompts else "")[:300],
            "start": min(stamps).strftime("%H:%M"), "end": max(stamps).strftime("%H:%M"),
            "active_min": active_minutes(stamps, idle),
            "repo_touched": any(m in cwd for m in REPO_MARKERS),
            "hints": hints(cwd, branch, " ".join(prompts)),
        })
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--date", default=None)
    ap.add_argument("--idle-min", type=int, default=10)
    a = ap.parse_args()
    today = datetime.now().astimezone().date()
    day = datetime.strptime(a.date, "%Y-%m-%d").date() if a.date else today
    if day < today - timedelta(days=1) or day > today:
        sys.exit("REFUSED: only today or yesterday may be logged retroactively. "
                 "Ask your time-tracking admin and use the missing-entries form.")
    res = claude_sessions(day, a.idle_min) + copilot_sessions(day, a.idle_min)
    res.sort(key=lambda r: r["start"])
    print(json.dumps(res, indent=2))


if __name__ == "__main__":
    main()
