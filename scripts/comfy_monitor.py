#!/usr/bin/env python3
"""
ComfyUI Live Monitor — Rich terminal dashboard via WebSocket + REST API.

Usage:
    comfy-monitor           # default port 8000
    comfy-monitor 8188      # custom port
"""
import asyncio, json, time, sys, os, signal, urllib.request, math, subprocess
from datetime import datetime, timedelta
from collections import deque
from pathlib import Path

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
POLL_INTERVAL = 2        # seconds between system stats polls
HISTORY_MAX = 20         # max recent jobs in history
OUTPUT_DIR = Path(os.path.expanduser("~/Comfy/output"))
LOG_LINES = 5            # server log lines to show

# ── ANSI ─────────────────────────────────────────────────────────────────────
RESET   = "\033[0m"
BOLD    = "\033[1m"
DIM     = "\033[2m"
ITALIC  = "\033[3m"
RED     = "\033[31m"
GREEN   = "\033[32m"
YELLOW  = "\033[33m"
BLUE    = "\033[34m"
MAGENTA = "\033[35m"
CYAN    = "\033[36m"
WHITE   = "\033[37m"
GRAY    = "\033[90m"
BG_RED    = "\033[41m"
BG_GREEN  = "\033[42m"
BG_BLUE   = "\033[44m"
BG_CYAN   = "\033[46m"
BG_MAGENTA = "\033[45m"

SPARK = "▁▂▃▄▅▆▇█"

# ── Terminal helpers ─────────────────────────────────────────────────────────
def tw():
    try: return os.get_terminal_size().columns
    except: return 100

def th():
    try: return os.get_terminal_size().lines
    except: return 40

def clear():
    print("\033[2J\033[H", end="", flush=True)

def hide_cursor():
    print("\033[?25l", end="", flush=True)

def show_cursor():
    print("\033[?25h", end="", flush=True)

def strip_ansi(t):
    import re
    return re.sub(r'\033\[[0-9;]*m', '', t)

def vlen(t):
    return len(strip_ansi(t))

def pad(t, w):
    d = w - vlen(t)
    return t + (" " * d if d > 0 else "")

def fb(b):
    """Format bytes."""
    if b >= 1024**3: return f"{b/1024**3:.1f} GB"
    if b >= 1024**2: return f"{b/1024**2:.0f} MB"
    return f"{b/1024:.0f} KB"

def fd(s):
    """Format duration from seconds."""
    if s < 0: return "--:--"
    h, rem = divmod(int(s), 3600)
    m, sec = divmod(rem, 60)
    if h > 0: return f"{h}h {m:02d}m {sec:02d}s"
    if m > 0: return f"{m}m {sec:02d}s"
    return f"{sec}s"

def sparkline(vals):
    if not vals or len(vals) < 2: return ""
    mn, mx = min(vals), max(vals)
    rng = mx - mn if mx != mn else 1
    return "".join(SPARK[min(len(SPARK)-1, int((v-mn)/rng*(len(SPARK)-1)))] for v in vals)

def bar_gauge(pct, width=20, color=None):
    if color is None:
        color = GREEN if pct < 60 else (YELLOW if pct < 85 else RED)
    filled = int(width * pct / 100)
    return f"{color}{'█' * filled}{DIM}{'░' * (width - filled)}{RESET}"

def progress_bar(pct, width=30):
    filled = int(width * pct / 100)
    return f"[{GREEN}{'█' * filled}{DIM}{'░' * (width - filled)}{RESET}]"


# ── REST API ─────────────────────────────────────────────────────────────────
def api_get(endpoint):
    try:
        t0 = time.time()
        with urllib.request.urlopen(f"http://127.0.0.1:{PORT}{endpoint}", timeout=3) as r:
            data = json.loads(r.read())
        latency = (time.time() - t0) * 1000
        return data, latency
    except Exception:
        return None, -1

def api_get_data(endpoint):
    d, _ = api_get(endpoint)
    return d


# ── System metrics (psutil-free) ─────────────────────────────────────────────
def get_cpu_usage():
    """Get CPU usage via top (macOS)."""
    try:
        r = subprocess.run(
            ["ps", "-A", "-o", "%cpu"], capture_output=True, text=True, timeout=2
        )
        total = sum(float(line.strip()) for line in r.stdout.strip().split("\n")[1:] if line.strip())
        cores = os.cpu_count() or 1
        return min(total / cores, 100.0)
    except Exception:
        return -1

def get_comfy_process_info():
    """Get ComfyUI process memory + CPU via ps."""
    try:
        r = subprocess.run(
            ["pgrep", "-f", "comfyui|ComfyUI"], capture_output=True, text=True, timeout=2
        )
        pids = r.stdout.strip().split("\n")
        if not pids or not pids[0]:
            return None
        # get details for first PID
        pid = pids[0].strip()
        r2 = subprocess.run(
            ["ps", "-p", pid, "-o", "pid,%cpu,rss,etime"],
            capture_output=True, text=True, timeout=2
        )
        lines = r2.stdout.strip().split("\n")
        if len(lines) < 2:
            return None
        parts = lines[1].split()
        if len(parts) < 4:
            return None
        return {
            "pid": int(parts[0]),
            "cpu": float(parts[1]),
            "rss_kb": int(parts[2]),
            "uptime": parts[3],
        }
    except Exception:
        return None

def get_disk_usage(path):
    """Get disk free/total for path."""
    try:
        st = os.statvfs(str(path))
        total = st.f_blocks * st.f_frsize
        free = st.f_bavail * st.f_frsize
        return total, free
    except Exception:
        return 0, 0

def get_output_files(limit=5):
    """Get most recent output files."""
    try:
        files = []
        for f in OUTPUT_DIR.iterdir():
            if f.is_file() and not f.name.startswith("."):
                files.append((f.stat().st_mtime, f.name, f.stat().st_size))
        files.sort(reverse=True)
        return files[:limit]
    except Exception:
        return []

def get_output_dir_stats():
    """Get output directory stats."""
    try:
        total_size = 0
        count = 0
        for f in OUTPUT_DIR.iterdir():
            if f.is_file() and not f.name.startswith("."):
                total_size += f.stat().st_size
                count += 1
        return count, total_size
    except Exception:
        return 0, 0


# ── Extract workflow metadata ────────────────────────────────────────────────
def extract_workflow_info(prompt_data):
    info = {
        "models": [], "loras": [], "resolution": "", "frames": "",
        "steps": "", "cfg": "", "sampler": "", "scheduler": "",
        "positive_prompt": "", "negative_prompt": "", "denoise": "",
        "clip_model": "", "vae_model": "", "workflow_type": "",
        "seed": "",
    }
    if not prompt_data or not isinstance(prompt_data, dict):
        return info

    for nid, node in prompt_data.items():
        if not isinstance(node, dict): continue
        cls = node.get("class_type", "")
        inp = node.get("inputs", {})
        title = node.get("_meta", {}).get("title", "").lower()

        # Models
        if cls in ("UnetLoaderGGUF", "UNETLoader", "CheckpointLoaderSimple"):
            name = inp.get("unet_name") or inp.get("ckpt_name", "")
            if name:
                short = os.path.splitext(os.path.basename(name))[0]
                if short not in info["models"]:
                    info["models"].append(short)

        # LoRAs
        if cls in ("LoraLoaderModelOnly", "LoraLoader"):
            name = inp.get("lora_name", "")
            strength = inp.get("strength_model", "")
            if name:
                short = os.path.splitext(os.path.basename(name))[0]
                entry = short
                if strength and strength != 1.0:
                    entry += f" ({strength})"
                if entry not in info["loras"]:
                    info["loras"].append(entry)

        # CLIP
        if cls in ("CLIPLoader", "CLIPLoaderGGUF", "DualCLIPLoader"):
            name = inp.get("clip_name") or inp.get("clip_name1", "")
            if name and not info["clip_model"]:
                info["clip_model"] = os.path.splitext(os.path.basename(name))[0]

        # VAE
        if cls in ("VAELoader",):
            name = inp.get("vae_name", "")
            if name and not info["vae_model"]:
                info["vae_model"] = os.path.splitext(os.path.basename(name))[0]

        # Resolution / frames
        if "width" in inp and "height" in inp:
            w_val, h_val = inp["width"], inp["height"]
            if isinstance(w_val, (int, float)) and isinstance(h_val, (int, float)):
                res = f"{int(w_val)}x{int(h_val)}"
                if not info["resolution"] or cls in ("EmptyLatentImage", "WanImageToVideo"):
                    info["resolution"] = res
        for fkey in ("length", "num_frames", "video_frames"):
            if fkey in inp:
                v = inp[fkey]
                if isinstance(v, (int, float)):
                    info["frames"] = f"{int(v)}f"

        # Sampler settings
        if cls in ("KSampler", "KSamplerAdvanced"):
            for k, ik in [("steps","steps"),("cfg","cfg"),("sampler","sampler_name"),
                          ("scheduler","scheduler"),("denoise","denoise"),("seed","seed")]:
                if ik in inp and not info[k]:
                    info[k] = str(inp[ik])
        if cls == "KSamplerSelect" and "sampler_name" in inp and not info["sampler"]:
            info["sampler"] = str(inp["sampler_name"])
        if cls == "BasicScheduler":
            if "scheduler" in inp and not info["scheduler"]:
                info["scheduler"] = str(inp["scheduler"])
            if "steps" in inp and isinstance(inp["steps"], (int, float)) and not info["steps"]:
                info["steps"] = str(int(inp["steps"]))
        if cls == "RandomNoise" and "noise_seed" in inp and not info["seed"]:
            info["seed"] = str(inp["noise_seed"])

        # Prompts
        if cls in ("CLIPTextEncode", "CLIPTextEncodeFlux"):
            text = inp.get("text", "")
            if isinstance(text, str) and text.strip():
                if "negative" in title or "neg" in title:
                    if not info["negative_prompt"]:
                        info["negative_prompt"] = text.strip()
                elif not info["positive_prompt"]:
                    info["positive_prompt"] = text.strip()

        # Workflow type detection
        if cls in ("WanImageToVideo",) and not info["workflow_type"]:
            info["workflow_type"] = "I2V"
        if cls in ("WanSampler",) and not info["workflow_type"]:
            info["workflow_type"] = "T2V"
        if cls in ("SaveImage", "PreviewImage") and not info["workflow_type"]:
            info["workflow_type"] = "IMG"
        if cls in ("VHS_VideoCombine",):
            info["workflow_type"] = "VID"

    return info


# ── State ────────────────────────────────────────────────────────────────────
LOADER_CLASSES = frozenset({
    "UnetLoaderGGUF", "UNETLoader", "CheckpointLoaderSimple", "CLIPLoader",
    "VAELoader", "LoraLoaderModelOnly", "LoraLoader", "CLIPVisionLoader",
    "ControlNetLoader", "DualCLIPLoader", "CLIPLoaderGGUF",
})
SAMPLER_CLASSES = frozenset({
    "KSampler", "KSamplerAdvanced", "SamplerCustom", "KSampler (Efficient)",
    "WanSampler", "BasicScheduler", "SplitSigmas", "BasicGuider",
    "RandomNoise", "FlipSigmas", "SamplerCustomAdvanced", "KSamplerSelect",
})
POSTPROCESS_CLASSES = frozenset({
    "VAEDecode", "VAEEncode", "SaveImage", "SaveAnimatedWEBP",
    "VHS_VideoCombine", "PreviewImage", "ImageUpscaleWithModel",
    "ImageScale", "ImageScaleBy",
})


class MonitorState:
    def __init__(self):
        self.reset()
        self.jobs_completed = 0
        self.jobs_total_time = 0
        self.session_start = time.time()
        # system
        self.ram_total = 0; self.ram_free = 0
        self.vram_total = 0; self.vram_free = 0
        self.torch_vram_total = 0; self.torch_vram_free = 0
        self.comfy_version = ""; self.pytorch_version = ""
        self.python_version = ""; self.device_name = ""
        self.device_full_name = ""; self.os_name = ""
        self.queue_size = 0; self.queue_pending_count = 0
        # process
        self.comfy_pid = 0; self.comfy_cpu = 0
        self.comfy_rss = 0; self.comfy_uptime = ""
        self.cpu_usage = 0
        # history & connectivity
        self.job_history = deque(maxlen=HISTORY_MAX)
        self.connected = False; self.api_latency = 0
        self.ws_messages_received = 0; self.last_ws_message = 0
        # workflow
        self.workflow_info = {}
        # memory trend
        self.mem_history = deque(maxlen=120)
        self.cpu_history = deque(maxlen=60)
        self.step_durations = []
        # output tracking
        self.output_file_count = 0; self.output_total_size = 0
        self.recent_outputs = []
        # disk
        self.disk_total = 0; self.disk_free = 0
        # server logs
        self.server_logs = []
        # pending queue items
        self.pending_jobs = []
        # phase timing
        self.phase_times = {}  # "loading" -> total_seconds, "sampling" -> ..., "postprocess" -> ...
        # vram snapshots (before/after model load)
        self.vram_before_load = 0
        self.vram_after_load = 0
        # errors this session
        self.error_count = 0
        # idle tracking
        self.last_job_end = None
        self.total_idle_time = 0
        # node duration history for estimating total job time
        self.loader_durations = deque(maxlen=20)   # historical load times
        self.sampler_durations = deque(maxlen=20)   # historical sample times per step
        self.postprocess_durations = deque(maxlen=20)
        # per-node class timing (for bottleneck analysis)
        self.node_class_times = {}   # class_type -> [durations]

    def reset(self):
        self.prompt_id = None
        self.node_map = {}
        self.exec_start = None; self.node_start = None
        self.current_node = None; self.current_node_title = ""
        self.current_node_class = ""
        self.nodes_done = []; self.cached_count = 0; self.total_nodes = 0
        self.sampling = False; self.step = 0; self.total_steps = 0
        self.step_times = []; self.step_durations = []
        self.step_start_time = None; self.avg_step_time = 0; self.eta = 0
        self.status = "idle"; self.error_msg = ""; self.error_traceback = []
        self.workflow_info = {}
        self.phase_times = {"loading": 0, "sampling": 0, "postprocess": 0}
        self.phase_current_start = None; self.phase_current = None
        self.vram_before_load = 0; self.vram_after_load = 0
        # overall job progress estimation
        self.est_total_time = 0
        self.loading_finished = False
        self.sampling_finished = False

    def track_phase(self, new_phase):
        """Track time spent in each execution phase."""
        now = time.time()
        if self.phase_current and self.phase_current_start:
            elapsed = now - self.phase_current_start
            self.phase_times[self.phase_current] = self.phase_times.get(self.phase_current, 0) + elapsed
        self.phase_current = new_phase
        self.phase_current_start = now

    def update_system(self, stats, latency=0):
        if not stats: return
        si = stats.get("system", {})
        self.ram_total = si.get("ram_total", 0)
        self.ram_free = si.get("ram_free", 0)
        self.comfy_version = si.get("comfyui_version", "?")
        self.pytorch_version = si.get("pytorch_version", "?")
        self.python_version = si.get("python_version", "?").split()[0]
        self.os_name = si.get("os", "?")
        self.api_latency = latency
        devs = stats.get("devices", [])
        if devs:
            d = devs[0]
            self.device_name = d.get("type", "?").upper()
            self.device_full_name = d.get("name", "?")
            self.vram_total = d.get("vram_total", 0)
            self.vram_free = d.get("vram_free", 0)
            self.torch_vram_total = d.get("torch_vram_total", 0)
            self.torch_vram_free = d.get("torch_vram_free", 0)
        if self.ram_total > 0:
            self.mem_history.append((self.ram_total - self.ram_free) / self.ram_total * 100)

    def update_process(self):
        info = get_comfy_process_info()
        if info:
            self.comfy_pid = info["pid"]
            self.comfy_cpu = info["cpu"]
            self.comfy_rss = info["rss_kb"] * 1024
            self.comfy_uptime = info["uptime"]
        cpu = get_cpu_usage()
        if cpu >= 0:
            self.cpu_usage = cpu
            self.cpu_history.append(cpu)

    def update_outputs(self):
        self.output_file_count, self.output_total_size = get_output_dir_stats()
        self.recent_outputs = get_output_files(5)

    def update_disk(self):
        self.disk_total, self.disk_free = get_disk_usage(OUTPUT_DIR)

    def update_logs(self):
        data = api_get_data("/internal/logs/raw")
        if data and "entries" in data:
            entries = data["entries"]
            # keep last N non-empty entries
            self.server_logs = [e for e in entries if e.get("m", "").strip()][-LOG_LINES:]

    def load_history(self):
        hist = api_get_data(f"/history?max_items={HISTORY_MAX}")
        if not hist: return
        jobs = []
        for pid, data in hist.items():
            sd = data.get("status", {})
            msgs = sd.get("messages", [])
            start_ts = end_ts = None
            for mt, md in msgs:
                ts = md.get("timestamp")
                if mt == "execution_start" and ts: start_ts = ts
                elif mt in ("execution_success","execution_error","execution_interrupted") and ts: end_ts = ts
            dur = (end_ts - start_ts) / 1000 if start_ts and end_ts else 0
            prompt_data = data.get("prompt", [])
            pg = prompt_data[2] if len(prompt_data) > 2 else {}
            wf = extract_workflow_info(pg)
            outs = data.get("outputs", {})
            oc = sum(len(v.get("images",[])+v.get("video",[])+v.get("audio",[])) for v in outs.values()) if outs else 0
            jobs.append({
                "id": pid[:8], "status": sd.get("status_str","?"),
                "duration": dur, "start_ts": start_ts,
                "models": wf.get("models",[]), "resolution": wf.get("resolution",""),
                "frames": wf.get("frames",""), "output_count": oc,
                "type": wf.get("workflow_type",""), "steps": wf.get("steps",""),
            })
        jobs.sort(key=lambda j: j.get("start_ts") or 0, reverse=True)
        self.job_history = deque(jobs[:HISTORY_MAX], maxlen=HISTORY_MAX)

    def load_pending(self):
        q = api_get_data("/queue")
        if not q: return
        self.queue_pending_count = len(q.get("queue_pending", []))
        self.pending_jobs = []
        for item in q.get("queue_pending", [])[:5]:
            pg = item[2] if len(item) > 2 else {}
            wf = extract_workflow_info(pg)
            self.pending_jobs.append({
                "id": (item[1] if len(item) > 1 else "?")[:8],
                "type": wf.get("workflow_type","?"),
                "models": wf.get("models",[]),
                "resolution": wf.get("resolution",""),
            })

    def build_node_map(self, prompt_data):
        self.node_map = {}
        if not prompt_data or not isinstance(prompt_data, dict): return
        for nid, ni in prompt_data.items():
            if isinstance(ni, dict):
                title = ni.get("_meta",{}).get("title","")
                ct = ni.get("class_type","")
                self.node_map[str(nid)] = {"title": title or ct, "class": ct}
        self.total_nodes = len(self.node_map)
        self.workflow_info = extract_workflow_info(prompt_data)
        # snapshot VRAM before loading
        self.vram_before_load = self.torch_vram_total - self.torch_vram_free if self.torch_vram_total else 0


def classify_status(cls, sampling):
    if cls in LOADER_CLASSES: return "loading"
    if cls in SAMPLER_CLASSES or sampling: return "sampling"
    return "postprocess"


# ── Renderer ─────────────────────────────────────────────────────────────────
def render(state):
    w = tw()
    clear()
    hide_cursor()
    now_str = datetime.now().strftime("%H:%M:%S")
    uptime = fd(time.time() - state.session_start)
    lines = []  # we build lines list then print all at once

    def ln(s=""): lines.append(s)
    def sep(): ln(f"{DIM}{'━' * w}{RESET}")
    def sep_title(title):
        t = f" {title} "
        r = w - len(t) - 4
        ln(f"{DIM}━━{RESET}{BOLD}{t}{RESET}{DIM}{'━' * max(r,0)}{RESET}")

    # ── HEADER ───────────────────────────────────────────────────────────
    conn = f"{GREEN}● connected{RESET}" if state.connected else f"{RED}● disconnected{RESET}"
    latency = f"{DIM}{state.api_latency:.0f}ms{RESET}" if state.api_latency > 0 else ""
    ws_rate = ""
    if state.ws_messages_received > 0 and state.last_ws_message > 0:
        age = time.time() - state.last_ws_message
        if age < 5:
            ws_rate = f"{GREEN}▪{RESET}"
        elif age < 30:
            ws_rate = f"{YELLOW}▪{RESET}"
        else:
            ws_rate = f"{RED}▪{RESET}"

    left = f"  {BOLD}COMFY MONITOR{RESET}  {DIM}v{state.comfy_version}  {state.device_name}{RESET}"
    right = f"{ws_rate} {conn} {latency}  {DIM}{now_str}  up {uptime}{RESET}"
    ln(f"{pad(left, w - vlen(right))}{right}")
    sep()

    # ── STATUS BANNER ────────────────────────────────────────────────────
    sc = {
        "idle":        (DIM,     "◯", "IDLE",            "Waiting for jobs"),
        "loading":     (YELLOW,  "⟳", "LOADING",         "Loading models into memory"),
        "sampling":    (CYAN,    "▶", "SAMPLING",         "Denoising in progress"),
        "postprocess": (MAGENTA, "⚙", "POST-PROCESS",    "Decoding / saving"),
        "done":        (GREEN,   "✓", "COMPLETE",         "Generation finished"),
        "error":       (RED,     "✗", "ERROR",            "Execution failed"),
    }
    color, icon, label, desc = sc.get(state.status, (DIM, "?", state.status, ""))
    sl = f"  {color}{BOLD}{icon} {label}{RESET}  {DIM}{desc}{RESET}"
    if state.exec_start and state.status not in ("idle",):
        elapsed = time.time() - state.exec_start
        sl += f"  {DIM}│{RESET}  {BOLD}{fd(elapsed)}{RESET} elapsed"
    ln(sl)

    # Idle time tracking
    if state.status == "idle" and state.last_job_end:
        idle_secs = time.time() - state.last_job_end
        total_idle = state.total_idle_time + idle_secs
        ln(f"  {DIM}Idle for {fd(idle_secs)}"
           f"  │  Total idle this session: {fd(total_idle)}{RESET}")
    elif state.status == "idle":
        ln(f"  {DIM}No jobs run yet this session{RESET}")

    # ── PHASE TIMELINE (visual progress through the job) ─────────────────
    if state.status not in ("idle",) and state.exec_start:
        now_t = time.time()
        elapsed = now_t - state.exec_start

        # Build phase timeline bar
        pt = dict(state.phase_times)
        # add current phase elapsed
        if state.phase_current and state.phase_current_start:
            ce = now_t - state.phase_current_start
            pt[state.phase_current] = pt.get(state.phase_current, 0) + ce

        total_phase = sum(pt.values())
        if total_phase > 0:
            tl_w = min(50, w - 30)
            tl_parts = []
            phase_colors = {"loading": YELLOW, "sampling": CYAN, "postprocess": MAGENTA}
            phase_labels = {"loading": "Load", "sampling": "Sample", "postprocess": "Post"}
            for pname in ("loading", "sampling", "postprocess"):
                psec = pt.get(pname, 0)
                if psec > 0:
                    pct = psec / total_phase
                    chars = max(1, int(tl_w * pct))
                    pc = phase_colors.get(pname, DIM)
                    tl_parts.append(f"{pc}{'█' * chars}{RESET}")
            timeline = "".join(tl_parts)

            # Phase legend
            legend_parts = []
            for pname in ("loading", "sampling", "postprocess"):
                psec = pt.get(pname, 0)
                if psec > 0.5:
                    pc = phase_colors.get(pname, DIM)
                    ppct = psec / total_phase * 100
                    legend_parts.append(f"{pc}■{RESET} {phase_labels[pname]} {fd(psec)} ({ppct:.0f}%)")
            ln(f"  [{timeline}]  {fd(elapsed)} total")
            if legend_parts:
                ln(f"  {'  '.join(legend_parts)}")

        # Overall job progress estimate
        if state.sampling and state.total_steps > 0 and state.avg_step_time > 0:
            # estimate: loading_done + (sampling_time_so_far + remaining) + post_estimate
            load_time = pt.get("loading", 0)
            sample_done = pt.get("sampling", 0)
            sample_remaining = state.avg_step_time * (state.total_steps - state.step)
            sample_total = sample_done + sample_remaining
            # estimate post time from history or assume ~10% of sample time
            post_est = 0
            if state.postprocess_durations:
                post_est = sum(state.postprocess_durations) / len(state.postprocess_durations)
            else:
                post_est = max(5, sample_total * 0.05)  # rough guess
            total_est = load_time + sample_total + post_est
            overall_pct = elapsed / total_est * 100 if total_est > 0 else 0
            overall_pct = min(99.9, overall_pct)
            overall_bar_w = min(40, w - 45)
            overall_bar = progress_bar(overall_pct, width=overall_bar_w)
            finish_time = datetime.now() + timedelta(seconds=max(0, total_est - elapsed))
            ln(f"  {BOLD}Overall{RESET} {overall_bar} {overall_pct:.0f}%  "
               f"~{fd(total_est)} total  done ~{finish_time.strftime('%H:%M:%S')}")
        elif state.status == "loading":
            # during loading, show what comes next
            wf_steps = state.workflow_info.get("steps", "")
            if wf_steps:
                ln(f"  {DIM}Next: sampling ({wf_steps} steps) → post-processing → done{RESET}")
            else:
                ln(f"  {DIM}Next: sampling → post-processing → done{RESET}")
        elif state.status == "done":
            ln(f"  {GREEN}{BOLD}✓ Job completed in {fd(elapsed)}{RESET}")

    ln()

    # ── SYSTEM METRICS (3-column layout) ─────────────────────────────────
    sep_title("SYSTEM")
    col_w = w // 3

    # Column 1: Memory
    c1 = []
    if state.ram_total > 0:
        ram_used = state.ram_total - state.ram_free
        ram_pct = ram_used / state.ram_total * 100
        bw = min(15, col_w - 25)
        if bw < 5: bw = 5
        c1.append(f"  {BOLD}Memory{RESET}")
        c1.append(f"  Sys [{bar_gauge(ram_pct, bw)}] {ram_pct:.0f}%")
        c1.append(f"      {fb(ram_used)}/{fb(state.ram_total)}")
        if state.torch_vram_total > 0:
            tu = state.torch_vram_total - state.torch_vram_free
            tp = tu / state.torch_vram_total * 100
            c1.append(f"  Torch [{bar_gauge(tp, bw, CYAN if tp < 60 else YELLOW if tp < 85 else RED)}] {tp:.0f}%")
            c1.append(f"        {fb(tu)}/{fb(state.torch_vram_total)}")
        if len(state.mem_history) > 5:
            c1.append(f"  {DIM}Trend{RESET} {CYAN}{sparkline(list(state.mem_history)[-30:])}{RESET}")

    # Column 2: CPU & Process
    c2 = []
    c2.append(f"  {BOLD}CPU & Process{RESET}")
    if state.cpu_usage >= 0:
        cpu_bw = min(15, col_w - 20)
        c2.append(f"  CPU  [{bar_gauge(state.cpu_usage, cpu_bw)}] {state.cpu_usage:.0f}%")
    if len(state.cpu_history) > 5:
        c2.append(f"  {DIM}Trend{RESET} {YELLOW}{sparkline(list(state.cpu_history)[-30:])}{RESET}")
    if state.comfy_pid:
        c2.append(f"  PID  {DIM}{state.comfy_pid}{RESET}  CPU {BOLD}{state.comfy_cpu:.0f}%{RESET}")
        c2.append(f"  RSS  {fb(state.comfy_rss)}  up {DIM}{state.comfy_uptime}{RESET}")

    # Column 3: Disk & Queue
    c3 = []
    c3.append(f"  {BOLD}Storage & Queue{RESET}")
    if state.disk_total > 0:
        disk_used = state.disk_total - state.disk_free
        disk_pct = disk_used / state.disk_total * 100
        c3.append(f"  Disk {fb(state.disk_free)} free ({disk_pct:.0f}% used)")
    c3.append(f"  Output {BOLD}{state.output_file_count}{RESET} files  {fb(state.output_total_size)}")
    qc = GREEN if state.queue_size == 0 else (YELLOW if state.queue_size < 3 else RED)
    c3.append(f"  Queue  {qc}{BOLD}{state.queue_size}{RESET} pending")
    c3.append(f"  Done   {GREEN}{BOLD}{state.jobs_completed}{RESET} this session")
    if state.jobs_completed > 0:
        avg = state.jobs_total_time / state.jobs_completed
        c3.append(f"  Avg    {BOLD}{fd(avg)}{RESET}  Total {DIM}{fd(state.jobs_total_time)}{RESET}")
    if state.error_count > 0:
        c3.append(f"  Errors {RED}{BOLD}{state.error_count}{RESET}")

    # Print columns side by side
    max_rows = max(len(c1), len(c2), len(c3))
    for i in range(max_rows):
        r1 = c1[i] if i < len(c1) else ""
        r2 = c2[i] if i < len(c2) else ""
        r3 = c3[i] if i < len(c3) else ""
        ln(f"{pad(r1, col_w)}{pad(r2, col_w)}{r3}")
    ln()

    # ── ACTIVE JOB ───────────────────────────────────────────────────────
    if state.status != "idle" or state.workflow_info.get("models"):
        sep_title("ACTIVE JOB")
        wf = state.workflow_info

        if wf:
            # Workflow type badge
            wt = wf.get("workflow_type", "")
            badges = {"I2V": f"{BG_BLUE}{WHITE}{BOLD} I2V {RESET}",
                      "T2V": f"{BG_CYAN}{WHITE}{BOLD} T2V {RESET}",
                      "IMG": f"{BG_GREEN}{WHITE}{BOLD} IMG {RESET}",
                      "VID": f"{BG_MAGENTA}{WHITE}{BOLD} VID {RESET}"}
            badge = badges.get(wt, "")

            # Row 1: type badge + models
            r1_parts = []
            if badge: r1_parts.append(badge)
            if wf.get("models"):
                r1_parts.append(f"{BOLD}Model{RESET} {', '.join(wf['models'][:2])}")
            if wf.get("clip_model"):
                r1_parts.append(f"{BOLD}CLIP{RESET} {wf['clip_model']}")
            if wf.get("vae_model"):
                r1_parts.append(f"{BOLD}VAE{RESET} {wf['vae_model']}")
            if r1_parts:
                ln(f"  {'  '.join(r1_parts)}")

            # Row 2: generation params
            r2 = []
            if wf.get("resolution"): r2.append(f"{BOLD}Res{RESET} {wf['resolution']}")
            if wf.get("frames"): r2.append(f"{BOLD}Frames{RESET} {wf['frames']}")
            if wf.get("steps"): r2.append(f"{BOLD}Steps{RESET} {wf['steps']}")
            if wf.get("sampler"): r2.append(f"{BOLD}Sampler{RESET} {wf['sampler']}")
            if wf.get("scheduler"): r2.append(f"{BOLD}Sched{RESET} {wf['scheduler']}")
            if wf.get("cfg"): r2.append(f"{BOLD}CFG{RESET} {wf['cfg']}")
            if wf.get("denoise") and wf["denoise"] != "1.0": r2.append(f"{BOLD}Denoise{RESET} {wf['denoise']}")
            if wf.get("seed"): r2.append(f"{BOLD}Seed{RESET} {DIM}{wf['seed']}{RESET}")
            if r2:
                s = f"  {f'  {DIM}│{RESET}  '.join(r2)}"
                if vlen(s) > w:
                    mid = len(r2) // 2
                    ln(f"  {f'  {DIM}│{RESET}  '.join(r2[:mid])}")
                    ln(f"  {f'  {DIM}│{RESET}  '.join(r2[mid:])}")
                else:
                    ln(s)

            # LoRAs
            if wf.get("loras"):
                ln(f"  {BOLD}LoRA{RESET}  {', '.join(wf['loras'][:4])}")

            # VRAM impact
            if state.vram_after_load > 0 and state.vram_before_load > 0:
                delta = state.vram_after_load - state.vram_before_load
                if delta > 0:
                    ln(f"  {BOLD}VRAM loaded{RESET}  +{fb(delta)}")

            # Prompt
            if wf.get("positive_prompt"):
                pt = wf["positive_prompt"]
                mx = w - 12
                if len(pt) > mx: pt = pt[:mx-3] + "..."
                ln(f"  {BOLD}Prompt{RESET} {DIM}{pt}{RESET}")

            ln()

        # Current node — detailed view
        if state.current_node and state.status not in ("idle", "done"):
            ne = time.time() - state.node_start if state.node_start else 0
            pi = {"loading":"📦","sampling":"🎨","postprocess":"💾"}.get(state.status,"⚙")
            executed = len(state.nodes_done) + 1
            total_exec = state.total_nodes - state.cached_count
            node_pct_str = ""
            if total_exec > 0:
                node_pct = executed / total_exec * 100
                node_bar_w = min(15, w // 4)
                node_pct_str = f"  [{bar_gauge(node_pct, node_bar_w)}] {executed}/{total_exec}"
            ln(f"  {pi} {BOLD}{state.current_node_title}{RESET}"
               f"  {DIM}[{state.current_node_class}]{RESET}"
               f"  {BOLD}{fd(ne)}{RESET}{node_pct_str}")

            # Human-readable description of what's happening
            cls = state.current_node_class
            what = ""
            if cls in ("UnetLoaderGGUF", "UNETLoader"):
                what = "Loading the diffusion model weights into memory"
            elif cls in ("CheckpointLoaderSimple",):
                what = "Loading full checkpoint (model + CLIP + VAE)"
            elif cls in ("CLIPLoader", "CLIPLoaderGGUF", "DualCLIPLoader"):
                what = "Loading text encoder for prompt processing"
            elif cls in ("VAELoader",):
                what = "Loading VAE for image encoding/decoding"
            elif cls in ("LoraLoaderModelOnly", "LoraLoader"):
                what = "Applying LoRA weights to the model"
            elif cls in ("CLIPVisionLoader",):
                what = "Loading CLIP vision model for image conditioning"
            elif cls in ("CLIPTextEncode", "CLIPTextEncodeFlux"):
                what = "Encoding your text prompt into embeddings"
            elif cls in ("KSampler", "KSamplerAdvanced", "SamplerCustomAdvanced"):
                what = "Running the denoising diffusion process"
            elif cls in ("WanSampler",):
                what = "Running Wan video diffusion sampler"
            elif cls in ("VAEDecode",):
                what = "Decoding latent space back to pixels"
            elif cls in ("VAEEncode",):
                what = "Encoding input image to latent space"
            elif cls in ("SaveImage", "PreviewImage"):
                what = "Saving output image to disk"
            elif cls in ("VHS_VideoCombine",):
                what = "Combining frames into video file"
            elif cls in ("ImageUpscaleWithModel",):
                what = "Upscaling output with AI model"
            elif cls in ("BasicScheduler",):
                what = "Computing noise schedule for sampling"
            elif cls in ("BasicGuider",):
                what = "Setting up classifier-free guidance"
            elif cls in ("RandomNoise",):
                what = "Generating initial noise"
            if what:
                ln(f"  {DIM}  → {what}{RESET}")

            # Time warning for long-running nodes
            if ne > 120:
                ln(f"  {YELLOW}  ⚠ This node has been running for {fd(ne)} — this is expected for large models/samplers{RESET}")
            elif ne > 30 and cls in LOADER_CLASSES:
                ln(f"  {DIM}  ⏳ Model loading can take 30s-2min depending on size{RESET}")

        # ── SAMPLING PROGRESS ────────────────────────────────────────────
        if state.sampling and state.total_steps > 0:
            pct = state.step / state.total_steps * 100
            bw = min(35, w - 50)
            if bw < 10: bw = 10
            bar = progress_bar(pct, width=bw)
            eta_str = fd(state.eta) if state.eta > 0 else "calc..."
            speed = f"{state.avg_step_time:.1f}s/step" if state.avg_step_time > 0 else ""

            ln()
            ln(f"  {bar}  {BOLD}{pct:5.1f}%{RESET}  "
               f"Step {BOLD}{state.step}{RESET}/{state.total_steps}  "
               f"{CYAN}{speed}{RESET}")

            # ETA + finish time + total estimate
            ep = [f"  ETA {BOLD}{eta_str}{RESET}"]
            if state.step > 0 and state.avg_step_time > 0:
                ft = datetime.now() + timedelta(seconds=state.eta)
                ep.append(f"{DIM}done ~{ft.strftime('%H:%M:%S')}{RESET}")
            if state.step > 1 and state.avg_step_time > 0:
                te = state.avg_step_time * state.total_steps
                ep.append(f"{DIM}total ~{fd(te)}{RESET}")
            ln("  ".join(ep))

            # Throughput estimate
            if state.avg_step_time > 0 and state.workflow_info.get("resolution"):
                res = state.workflow_info["resolution"]
                parts = res.split("x")
                if len(parts) == 2:
                    try:
                        px = int(parts[0]) * int(parts[1])
                        mpx_per_step = px / 1e6
                        mpx_per_sec = mpx_per_step / state.avg_step_time
                        tp_str = f"{mpx_per_sec:.2f} Mpx/s"
                        frames_str = ""
                        if state.workflow_info.get("frames"):
                            try:
                                nf = int(state.workflow_info["frames"].replace("f",""))
                                fps = nf / (state.avg_step_time * state.total_steps)
                                frames_str = f"  ~{fps:.3f} frames/s"
                            except: pass
                        ln(f"  {DIM}Throughput{RESET}  {CYAN}{tp_str}{RESET}{frames_str}")
                    except: pass

            # Step timing sparkline
            if len(state.step_durations) > 2:
                spark = sparkline(state.step_durations)
                avg_d = sum(state.step_durations) / len(state.step_durations)
                mn_d = min(state.step_durations)
                mx_d = max(state.step_durations)
                ln(f"  {DIM}Step times{RESET}  {CYAN}{spark}{RESET}  "
                   f"{DIM}avg {avg_d:.1f}s  min {mn_d:.1f}s  max {mx_d:.1f}s{RESET}")
            ln()

        elif state.status == "done" and state.exec_start:
            elapsed = time.time() - state.exec_start
            ln()

            # Completed summary with node count
            nodes_ran = len(state.nodes_done)
            cached = state.cached_count
            ln(f"  {GREEN}{BOLD}✓ Completed in {fd(elapsed)}{RESET}"
               f"  {DIM}({nodes_ran} nodes executed, {cached} cached){RESET}")

            # Phase breakdown with visual bar
            pt = state.phase_times
            total_phase = sum(pt.values())
            if total_phase > 0:
                phase_colors = {"loading": YELLOW, "sampling": CYAN, "postprocess": MAGENTA}
                for pname, plabel in [("loading","Loading"),("sampling","Sampling"),("postprocess","Post-process")]:
                    psec = pt.get(pname, 0)
                    if psec > 0.5:
                        ppct = psec / total_phase * 100
                        pc = phase_colors[pname]
                        bar_chars = max(1, int(20 * ppct / 100))
                        ln(f"  {pc}{'█' * bar_chars}{RESET} {plabel} {fd(psec)} ({ppct:.0f}%)")

            # Bottleneck nodes (top 3 slowest)
            if state.nodes_done:
                sorted_nodes = sorted(state.nodes_done, key=lambda n: n["duration"], reverse=True)[:3]
                if sorted_nodes[0]["duration"] > 2:
                    ln(f"  {DIM}Slowest nodes:{RESET}")
                    for sn in sorted_nodes:
                        if sn["duration"] > 1:
                            ln(f"    {DIM}• {sn['title']} [{sn['class']}] — {fd(sn['duration'])}{RESET}")

            # Step stats if we had sampling
            if state.step_durations:
                avg_s = sum(state.step_durations) / len(state.step_durations)
                ln(f"  {DIM}Sampling: {len(state.step_durations)+1} steps, avg {avg_s:.1f}s/step{RESET}")

            if state.jobs_completed > 1:
                avg = state.jobs_total_time / state.jobs_completed
                ln(f"  {DIM}Session: {state.jobs_completed} jobs, avg {fd(avg)}, total {fd(state.jobs_total_time)}{RESET}")
            ln()

    # ── PIPELINE LOG ─────────────────────────────────────────────────────
    if state.cached_count > 0 or state.nodes_done or (state.status != "idle" and state.status != "done"):
        sep_title("PIPELINE")

        if state.cached_count > 0:
            ln(f"  {DIM}⚡ {state.cached_count} node(s) from cache{RESET}")

        max_log = min(8, max(3, th() - 35))
        recent = state.nodes_done[-max_log:] if state.nodes_done else []
        skipped = len(state.nodes_done) - len(recent)
        if skipped > 0:
            ln(f"  {DIM}  ... {skipped} earlier nodes{RESET}")

        for entry in recent:
            dur = entry["duration"]
            ds = fd(dur) if dur > 0.1 else "<0.1s"
            dc = RED if dur > 60 else (YELLOW if dur > 10 else (WHITE if dur > 1 else DIM))
            ci = ""
            if entry['class'] in LOADER_CLASSES: ci = "📦 "
            elif entry['class'] in SAMPLER_CLASSES: ci = "🎨 "
            elif entry['class'] in POSTPROCESS_CLASSES: ci = "💾 "
            cls_info = f" {DIM}[{entry['class']}]{RESET}" if entry['class'] != entry['title'] else ""
            ln(f"  {GREEN}✓{RESET} {ci}{entry['title']}{cls_info}  {dc}{ds}{RESET}")
        ln()

    # ── ERROR DETAILS ────────────────────────────────────────────────────
    if state.error_msg:
        sep_title("ERROR")
        for line in state.error_msg.split("\n")[:5]:
            if len(line) > w - 6: line = line[:w-9] + "..."
            ln(f"  {RED}{line}{RESET}")
        if state.error_traceback:
            ln(f"  {DIM}Traceback (last 3):{RESET}")
            for frame in state.error_traceback[-3:]:
                if len(frame) > w - 8: frame = frame[:w-11] + "..."
                ln(f"    {DIM}{frame}{RESET}")
        ln()

    # ── PENDING QUEUE ────────────────────────────────────────────────────
    if state.pending_jobs:
        sep_title(f"QUEUE ({state.queue_pending_count} pending)")
        for pj in state.pending_jobs:
            mdl = ", ".join(pj.get("models",[]))[:30] or "?"
            ln(f"  {DIM}•{RESET} {pj['id']}  {BOLD}{pj.get('type','?')}{RESET}  {mdl}  {pj.get('resolution','')}")
        ln()

    # ── JOB HISTORY ──────────────────────────────────────────────────────
    if state.job_history:
        hist_max = min(6, max(2, th() - 40))
        jobs = list(state.job_history)[:hist_max]
        sep_title(f"HISTORY (last {len(jobs)})")
        hdr = f"  {DIM}{'ID':<10}{'Type':<6}{'Status':<10}{'Duration':<10}{'Model':<24}{'Size':<10}{'Out':>4}{RESET}"
        ln(hdr)
        for j in jobs:
            sc2 = GREEN if j["status"] == "success" else (RED if j["status"] == "error" else YELLOW)
            dur = fd(j["duration"]) if j["duration"] > 0 else "--"
            mdl = ", ".join(j.get("models",[]))[:23] or "--"
            res = j.get("resolution","") or "--"
            fr = j.get("frames","")
            sz = f"{res} {fr}".strip() if res != "--" else "--"
            tp = j.get("type","") or "--"
            ln(f"  {DIM}{j['id']:<10}{RESET}{tp:<6}{sc2}{j['status']:<10}{RESET}{dur:<10}{mdl:<24}{sz:<10}{str(j.get('output_count',0)):>4}")
        ln()

    # ── RECENT OUTPUTS ───────────────────────────────────────────────────
    if state.recent_outputs:
        sep_title("RECENT OUTPUT")
        for mtime, name, size in state.recent_outputs[:4]:
            age = time.time() - mtime
            age_str = fd(age) + " ago"
            sz = fb(size)
            # highlight if very recent (< 60s)
            nc = GREEN if age < 60 else (WHITE if age < 300 else DIM)
            ln(f"  {nc}{name}{RESET}  {DIM}{sz}  {age_str}{RESET}")
        ln()

    # ── SERVER LOGS ──────────────────────────────────────────────────────
    if state.server_logs:
        sep_title("SERVER LOG")
        for entry in state.server_logs:
            msg = entry.get("m", "").strip()
            if len(msg) > w - 6: msg = msg[:w-9] + "..."
            ts = entry.get("t", "")
            if ts:
                try:
                    dt = datetime.fromisoformat(ts.replace("Z","+00:00"))
                    ts_str = dt.strftime("%H:%M:%S")
                except: ts_str = ""
            else:
                ts_str = ""
            ln(f"  {DIM}{ts_str}{RESET} {msg}")
        ln()

    # ── FOOTER ───────────────────────────────────────────────────────────
    sep()
    env = []
    if state.pytorch_version != "?": env.append(f"PyTorch {state.pytorch_version}")
    if state.python_version != "?": env.append(f"Python {state.python_version}")
    if state.device_full_name != "?": env.append(state.device_full_name)
    ws_count = f"ws:{state.ws_messages_received}" if state.ws_messages_received > 0 else ""
    left_f = f"  {DIM}{' · '.join(env)}{RESET}"
    right_f = f"{DIM}{ws_count}  port {PORT}  Ctrl+C exit{RESET}  "
    ln(f"{pad(left_f, w - vlen(right_f))}{right_f}")

    # Print everything
    print("\n".join(lines), flush=True)


# ── Main loop ────────────────────────────────────────────────────────────────
async def monitor():
    try:
        import websockets
    except ImportError:
        print(f"{RED}Missing dependency. Run:{RESET}")
        print(f"  /Users/uge/Comfy/.venv/bin/python -m pip install websockets")
        sys.exit(1)

    state = MonitorState()

    # initial data load
    stats, latency = api_get("/system_stats")
    if not stats:
        print(f"{RED}Cannot connect to ComfyUI on port {PORT}.{RESET}")
        print(f"{DIM}Make sure ComfyUI is running.{RESET}")
        sys.exit(1)
    state.update_system(stats, latency)
    state.update_process()
    state.update_outputs()
    state.update_disk()
    state.load_history()
    state.load_pending()
    state.update_logs()

    # check for running job
    queue = api_get_data("/queue")
    if queue:
        running = queue.get("queue_running", [])
        if running:
            pg = running[0][2] if len(running[0]) > 2 else None
            state.build_node_map(pg)
            state.prompt_id = running[0][1] if len(running[0]) > 1 else None
            state.status = "loading"
            state.exec_start = time.time()
        pending = queue.get("queue_pending", [])
        state.queue_size = len(running) + len(pending)

    state.connected = True
    render(state)

    uri = f"ws://127.0.0.1:{PORT}/ws?clientId=cli-monitor-{int(time.time())}"
    reconnect_delay = 1
    slow_poll_counter = 0  # for less frequent polls

    while True:
        try:
            async with __import__('websockets').connect(
                uri, ping_interval=30, ping_timeout=120,
                max_size=50 * 1024 * 1024
            ) as ws:
                state.connected = True
                reconnect_delay = 1
                render(state)

                last_stats_poll = time.time()
                last_render = 0

                while True:
                    try:
                        raw = await asyncio.wait_for(ws.recv(), timeout=POLL_INTERVAL)
                    except asyncio.TimeoutError:
                        now = time.time()
                        if now - last_stats_poll >= POLL_INTERVAL:
                            s, lat = api_get("/system_stats")
                            state.update_system(s, lat)
                            # rotate slow polls (process, disk, outputs, logs, pending)
                            slow_poll_counter = (slow_poll_counter + 1) % 5
                            if slow_poll_counter == 0: state.update_process()
                            elif slow_poll_counter == 1: state.update_outputs()
                            elif slow_poll_counter == 2: state.update_disk()
                            elif slow_poll_counter == 3: state.update_logs()
                            elif slow_poll_counter == 4: state.load_pending()
                            # refresh queue count
                            q = api_get_data("/queue")
                            if q:
                                state.queue_size = len(q.get("queue_running",[])) + len(q.get("queue_pending",[]))
                                state.queue_pending_count = len(q.get("queue_pending",[]))
                            last_stats_poll = now
                            render(state)
                        continue
                    except Exception:
                        state.connected = False
                        render(state)
                        break

                    if isinstance(raw, bytes):
                        state.ws_messages_received += 1
                        state.last_ws_message = time.time()
                        continue

                    msg = json.loads(raw)
                    t = msg.get("type")
                    d = msg.get("data", {})
                    now = time.time()
                    state.ws_messages_received += 1
                    state.last_ws_message = now
                    should_render = False

                    if t == "status":
                        q = d.get("status",{}).get("exec_info",{}).get("queue_remaining",0)
                        state.queue_size = q
                        should_render = True

                    elif t == "execution_start":
                        # track idle time before this job
                        if state.last_job_end:
                            state.total_idle_time += now - state.last_job_end
                        state.reset()
                        state.status = "loading"
                        state.exec_start = now
                        state.prompt_id = d.get("prompt_id")
                        state.track_phase("loading")
                        queue = api_get_data("/queue")
                        if queue:
                            running = queue.get("queue_running", [])
                            for job in running:
                                if len(job) > 2:
                                    state.build_node_map(job[2])
                                    break
                        should_render = True

                    elif t == "execution_cached":
                        nodes = d.get("nodes", [])
                        state.cached_count += len(nodes)
                        should_render = True

                    elif t == "executing":
                        node_id = d.get("node")
                        if node_id is None:
                            state.track_phase(None)
                            elapsed = now - state.exec_start if state.exec_start else 0
                            state.jobs_completed += 1
                            state.jobs_total_time += elapsed
                            state.status = "done"
                            state.sampling = False
                            state.current_node = None
                            state.last_job_end = now
                            # store historical phase durations for future estimates
                            pt = state.phase_times
                            if pt.get("loading", 0) > 0:
                                state.loader_durations.append(pt["loading"])
                            if pt.get("postprocess", 0) > 0:
                                state.postprocess_durations.append(pt["postprocess"])
                            if state.step_durations:
                                avg_s = sum(state.step_durations) / len(state.step_durations)
                                state.sampler_durations.append(avg_s)
                            # store per-node-class timings
                            for nd in state.nodes_done:
                                cls = nd["class"]
                                if cls not in state.node_class_times:
                                    state.node_class_times[cls] = []
                                state.node_class_times[cls].append(nd["duration"])
                            # snapshot VRAM after everything
                            if state.torch_vram_total:
                                state.vram_after_load = state.torch_vram_total - state.torch_vram_free
                            state.load_history()
                            state.update_outputs()
                            state.load_pending()
                            should_render = True
                        else:
                            if state.current_node and state.node_start:
                                dur = now - state.node_start
                                state.nodes_done.append({
                                    "title": state.current_node_title,
                                    "class": state.current_node_class,
                                    "duration": dur,
                                })
                            state.current_node = node_id
                            state.node_start = now
                            info = state.node_map.get(str(node_id), {})
                            state.current_node_title = info.get("title", f"Node {node_id}")
                            state.current_node_class = info.get("class", "?")
                            new_status = classify_status(state.current_node_class, state.sampling)
                            if new_status != state.status:
                                state.track_phase(new_status)
                            state.status = new_status
                            # VRAM snapshot after loading phase ends
                            if new_status != "loading" and not state.vram_after_load:
                                if state.torch_vram_total:
                                    state.vram_after_load = state.torch_vram_total - state.torch_vram_free
                            should_render = True

                    elif t == "progress":
                        step = d["value"]
                        total = d["max"]
                        state.sampling = True
                        state.status = "sampling"
                        state.step = step
                        state.total_steps = total

                        if step == 1:
                            state.step_start_time = now
                            state.step_times = [now]
                            state.step_durations = []
                            state.avg_step_time = 0
                            state.eta = 0
                        else:
                            state.step_times.append(now)
                            if len(state.step_times) >= 2:
                                dur = state.step_times[-1] - state.step_times[-2]
                                state.step_durations.append(dur)
                            window = state.step_times[-6:]
                            if len(window) >= 2:
                                state.avg_step_time = (window[-1] - window[0]) / (len(window) - 1)
                            state.eta = state.avg_step_time * (total - step)

                        if step == total:
                            state.sampling = False
                        should_render = True

                    elif t == "execution_error":
                        state.track_phase(None)
                        state.status = "error"
                        state.error_msg = d.get("exception_message", "Unknown error")
                        nt = d.get("node_type", "")
                        if nt: state.error_msg = f"[{nt}] {state.error_msg}"
                        state.error_traceback = d.get("traceback", [])
                        state.error_count += 1
                        state.load_history()
                        should_render = True

                    elif t == "execution_success":
                        state.track_phase(None)
                        if state.status != "done":
                            elapsed = now - state.exec_start if state.exec_start else 0
                            state.jobs_completed += 1
                            state.jobs_total_time += elapsed
                            state.status = "done"
                        state.load_history()
                        state.update_outputs()
                        should_render = True

                    elif t == "execution_interrupted":
                        state.track_phase(None)
                        state.status = "error"
                        state.error_msg = "Execution interrupted by user"
                        state.sampling = False
                        state.error_count += 1
                        state.load_history()
                        should_render = True

                    elif t == "executed":
                        # per-node output event — could track output metadata
                        should_render = False

                    # throttle renders
                    if should_render and (t == "progress" or now - last_render > 0.25):
                        if now - last_stats_poll >= POLL_INTERVAL:
                            s, lat = api_get("/system_stats")
                            state.update_system(s, lat)
                            last_stats_poll = now
                        render(state)
                        last_render = now

        except Exception:
            state.connected = False
            render(state)
            await asyncio.sleep(reconnect_delay)
            reconnect_delay = min(reconnect_delay * 2, 30)


if __name__ == "__main__":
    signal.signal(signal.SIGWINCH, lambda *_: None)
    try:
        asyncio.run(monitor())
    except KeyboardInterrupt:
        show_cursor()
        print(f"\n{DIM}Monitor stopped.{RESET}", flush=True)
