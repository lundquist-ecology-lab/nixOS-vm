# Local Code Models on RTX 5060 Ti 16GB

This VM already has two local serving paths:

- `vLLM` for OpenAI-compatible serving and higher-throughput GPU inference.
- `Ollama` for simpler local model management and GGUF-based experiments.

For this GPU, the most practical default is a code-specific 14B-class model with 4-bit weight quantization. That keeps enough VRAM for the runtime, KV cache, and real editor or agent workflows.

## Recommended Order

1. `Qwen/Qwen2.5-Coder-14B-Instruct-AWQ` in `vLLM`
2. `Devstral Small 2 24B` in `Ollama` or GGUF tooling for quality comparison
3. `Qwen3-Coder-Next-FP8` only as a later experiment if you move to a larger GPU

### Why this order

- `Qwen2.5-Coder-14B-Instruct-AWQ` is code-specific, widely used, Apache-2.0, and much more realistic for a 16GB card than 24B+ dense or FP8-heavy checkpoints.
- `Devstral Small 2 24B` is attractive for agentic coding, but on this class of GPU it is better treated as a comparison target than the default service model.
- `Qwen3-Coder-Next-FP8` looks strong for coding agents, but its FP8 checkpoint and total model size make it a poor first target for this card. That is an inference from the published model scale, not a measured result on this machine.

## Why not TurboQuant first

TurboQuant is most interesting for KV-cache compression on long-context workloads. It can matter for long repo prompts and multi-step coding sessions, but it is not yet the cleanest production path in the runtimes already used on this VM.

For this machine, the first-order wins are:

- Use a code-tuned model.
- Use 4-bit or other supported weight quantization.
- Enable mainstream KV-cache compression in the serving stack.

That is why the `vLLM` service is set up around AWQ weights plus FP8 KV-cache rather than a custom TurboQuant integration.

## Default vLLM target

Use:

- Model: `Qwen/Qwen2.5-Coder-14B-Instruct-AWQ`
- Quantization: `awq_marlin`
- Context: `16384`
- KV cache: `fp8` with automatic scale calculation

This is a conservative starting point for a `16GB` card. If it is stable under load, the next knob to turn is `--max-model-len`.

## Benchmark plan

The goal is to compare three things:

1. Editing quality on real code tasks
2. Tool or agent reliability
3. Latency and VRAM behavior under longer contexts

### Models to compare

- `qwen2.5-coder-14b-awq` in `vLLM`
- Your current `Qwen3-14B-AWQ` setup if you want an apples-to-apples baseline
- `devstral` via `Ollama` or a GGUF runner if you want an agentic comparison

### Workloads

- Short completion: one function implementation from a docstring
- Bug fix: one failing function with a small test case
- Refactor: one multi-file change over 3-6 files
- Long-context repo task: prompt with several files or a long architecture description
- Tool-use task: ask the model to call a simple tool or produce structured tool intent

### Metrics

- Time to first token
- Tokens per second after first token
- Peak VRAM from `nvidia-smi`
- Correctness on the first response
- Number of turns needed to reach a usable patch
- Tool call correctness
- Behavior degradation as context gets longer

### Suggested evaluation procedure

1. Start one model and keep every non-model setting fixed.
2. Run the same prompt set with `temperature=0` for deterministic comparisons.
3. Save raw responses, latency, and GPU memory data.
4. Score each answer for correctness and edit usefulness.
5. Repeat the long-context task at increasing prompt sizes.

### Sample prompt set

#### Prompt 1: Function implementation

```text
Write a Python function `merge_intervals(intervals: list[tuple[int, int]]) -> list[tuple[int, int]]`.
Requirements:
- sort by start
- merge overlaps
- preserve closed intervals
- return minimal merged output
Also provide 4 pytest tests.
```

#### Prompt 2: Bug fix

```text
You are given this Python function:

def is_balanced(s: str) -> bool:
    stack = []
    pairs = {')': '(', ']': '[', '}': '{'}
    for ch in s:
        if ch in "([{":
            stack.append(ch)
        elif ch in pairs:
            if not stack or stack[-1] == pairs[ch]:
                return False
            stack.pop()
    return True

Find the bug, explain it briefly, and return the corrected function plus 3 edge-case tests.
```

#### Prompt 3: Refactor

```text
Refactor this module to separate parsing from validation.
Constraints:
- keep public API stable
- add type hints
- avoid introducing classes
- include a minimal test plan
```

#### Prompt 4: Long-context code review

```text
Given the following files, identify the most likely source of a race condition, propose a fix, and show the exact patch.
```

Use a small real repo slice here, not a synthetic example.

## Command examples

### Service health

```bash
use-vllm
llm-status
```

### OpenAI-compatible request

```bash
curl -s http://127.0.0.1:8000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "qwen2.5-coder-14b-awq",
    "temperature": 0,
    "messages": [
      {"role": "system", "content": "You are a precise coding assistant."},
      {"role": "user", "content": "Write a Python function that returns the nth Fibonacci number iteratively and add two pytest tests."}
    ]
  }'
```

### GPU memory snapshot during benchmarking

```bash
watch -n 1 nvidia-smi
```

### Repeatable benchmark runs

```bash
python /home/mlundquist/git/nixOS-vm/scripts/bench_local_llm.py \
  --base-url http://127.0.0.1:8000/v1 \
  --model qwen2.5-coder-14b-awq \
  --label qwen25coder-vllm
```

```bash
python /home/mlundquist/git/nixOS-vm/scripts/bench_local_llm.py \
  --base-url http://127.0.0.1:11434/v1 \
  --model devstral:24b-16k \
  --label devstral-ollama
```

## Next tuning steps

- If VRAM headroom remains high, raise `--max-model-len`.
- If long-context quality matters more than raw speed, benchmark a larger context window before switching models.
- If tool use is weaker than expected, compare against `Devstral` on the same prompt set rather than changing multiple variables at once.
