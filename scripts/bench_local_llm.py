#!/usr/bin/env python3

import argparse
import json
import subprocess
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path


DEFAULT_PROMPTS = [
    {
        "id": "function_impl",
        "messages": [
            {"role": "system", "content": "You are a precise coding assistant."},
            {
                "role": "user",
                "content": (
                    "Write a Python function "
                    "`merge_intervals(intervals: list[tuple[int, int]]) -> list[tuple[int, int]]`.\n"
                    "Requirements:\n"
                    "- sort by start\n"
                    "- merge overlaps\n"
                    "- preserve closed intervals\n"
                    "- return minimal merged output\n"
                    "Also provide 4 pytest tests."
                ),
            },
        ],
    },
    {
        "id": "bug_fix",
        "messages": [
            {"role": "system", "content": "You are a precise coding assistant."},
            {
                "role": "user",
                "content": (
                    "You are given this Python function:\n\n"
                    "def is_balanced(s: str) -> bool:\n"
                    "    stack = []\n"
                    "    pairs = {')': '(', ']': '[', '}': '{'}\n"
                    "    for ch in s:\n"
                    "        if ch in '([{':\n"
                    "            stack.append(ch)\n"
                    "        elif ch in pairs:\n"
                    "            if not stack or stack[-1] == pairs[ch]:\n"
                    "                return False\n"
                    "            stack.pop()\n"
                    "    return True\n\n"
                    "Find the bug, explain it briefly, and return the corrected "
                    "function plus 3 edge-case tests."
                ),
            },
        ],
    },
    {
        "id": "refactor_plan",
        "messages": [
            {"role": "system", "content": "You are a precise coding assistant."},
            {
                "role": "user",
                "content": (
                    "Refactor this module to separate parsing from validation.\n"
                    "Constraints:\n"
                    "- keep public API stable\n"
                    "- add type hints\n"
                    "- avoid introducing classes\n"
                    "- include a minimal test plan\n"
                    "Show the patch."
                ),
            },
        ],
    },
]


def parse_args():
    parser = argparse.ArgumentParser(
        description="Benchmark local OpenAI-compatible LLM endpoints for code tasks."
    )
    parser.add_argument("--base-url", default="http://127.0.0.1:8000/v1")
    parser.add_argument("--model", required=True)
    parser.add_argument("--label", default=None)
    parser.add_argument("--output-dir", default="bench-results")
    parser.add_argument("--prompt-file", default=None)
    parser.add_argument("--max-tokens", type=int, default=768)
    parser.add_argument("--temperature", type=float, default=0.0)
    parser.add_argument("--timeout", type=int, default=900)
    parser.add_argument("--startup-timeout", type=int, default=180)
    return parser.parse_args()


def load_prompts(path):
    if not path:
        return DEFAULT_PROMPTS
    prompt_path = Path(path)
    return json.loads(prompt_path.read_text())


def sample_gpu_memory():
    try:
        result = subprocess.run(
            [
                "nvidia-smi",
                "--query-gpu=memory.used,memory.total,name",
                "--format=csv,noheader,nounits",
            ],
            check=True,
            capture_output=True,
            text=True,
        )
    except Exception as exc:
        return {"error": str(exc)}
    first = result.stdout.strip().splitlines()[0]
    used, total, name = [part.strip() for part in first.split(",", 2)]
    return {
        "used_mb": int(used),
        "total_mb": int(total),
        "name": name,
    }


def make_request(base_url, payload, timeout):
    req = urllib.request.Request(
        f"{base_url.rstrip('/')}/chat/completions",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    return urllib.request.urlopen(req, timeout=timeout)


def wait_for_server(base_url, timeout):
    deadline = time.monotonic() + timeout
    req = urllib.request.Request(
        f"{base_url.rstrip('/')}/models",
        method="GET",
    )
    last_error = None
    while time.monotonic() < deadline:
        try:
            with urllib.request.urlopen(req, timeout=5) as response:
                if response.status == 200:
                    return
        except Exception as exc:
            last_error = exc
            time.sleep(1)
    raise RuntimeError(
        f"Timed out waiting for {base_url.rstrip('/')}/models"
        + (f": {last_error}" if last_error else "")
    )


def run_prompt(base_url, model, prompt, max_tokens, temperature, timeout):
    payload = {
        "model": model,
        "messages": prompt["messages"],
        "temperature": temperature,
        "max_tokens": max_tokens,
        "stream": True,
    }

    gpu_before = sample_gpu_memory()
    started = time.perf_counter()
    ttft = None
    chunks = []
    usage = None

    try:
        with make_request(base_url, payload, timeout) as response:
            for raw_line in response:
                line = raw_line.decode("utf-8").strip()
                if not line.startswith("data: "):
                    continue
                data = line[6:]
                if data == "[DONE]":
                    break
                event = json.loads(data)
                if "usage" in event:
                    usage = event["usage"]
                for choice in event.get("choices", []):
                    delta = choice.get("delta", {})
                    content = delta.get("content")
                    if content:
                        if ttft is None:
                            ttft = time.perf_counter() - started
                        chunks.append(content)
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code}: {body}") from exc

    elapsed = time.perf_counter() - started
    text = "".join(chunks)
    gpu_after = sample_gpu_memory()

    return {
        "prompt_id": prompt["id"],
        "elapsed_s": round(elapsed, 3),
        "ttft_s": None if ttft is None else round(ttft, 3),
        "output_chars": len(text),
        "output_preview": text[:400],
        "usage": usage,
        "gpu_before": gpu_before,
        "gpu_after": gpu_after,
    }


def main():
    args = parse_args()
    prompts = load_prompts(args.prompt_file)
    label = args.label or args.model.replace("/", "_")
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{timestamp}_{label}.json"

    report = {
        "label": label,
        "model": args.model,
        "base_url": args.base_url,
        "created_at": timestamp,
        "temperature": args.temperature,
        "max_tokens": args.max_tokens,
        "results": [],
    }

    wait_for_server(args.base_url, args.startup_timeout)

    for prompt in prompts:
        sys.stderr.write(f"Running prompt: {prompt['id']}\n")
        sys.stderr.flush()
        result = run_prompt(
            args.base_url,
            args.model,
            prompt,
            args.max_tokens,
            args.temperature,
            args.timeout,
        )
        report["results"].append(result)

    output_path.write_text(json.dumps(report, indent=2) + "\n")
    print(output_path)


if __name__ == "__main__":
    main()
