---
name: what-now
description: Read-only recall/menu for the spec-driven pipeline. Detects where the current OpenSpec change is and prints "you are here" on the pipeline map, the next command to run, and an inventory of the available skills/agents. Use when the user forgets what to do next or what tooling exists. Triggers on "what now", "/what-now", "tôi cần làm gì", "nhắc tôi", "đang ở bước nào", "có skill gì".
---

# what-now — "where am I & what can I run"

**Read-only.** Do NOT implement, edit, or create anything. Just orient the user and stop.

## 1. Detect current state
```bash
openspec list --json
```
For the active/most-recent change, also peek at `tasks.md` checkbox progress (via `openspec status --change <name> --json`). Map it to a stage:
- no change → **Stage 0: Idea** (nothing started)
- change exists, specs being written / not confirmed → **Stage 1: Specs**
- specs final, tasks unchecked or partial → **Stage 2: Implement**
- tasks all checked, not archived → **Stage 3: Archive**
- archived → **Done**

## 2. Print the pipeline map with "you are here"
Render this, marking the current stage with `👉`:

```
🗺️  SPEC-DRIVEN PIPELINE
  ① Idea      → grill-me / /opsx:explore      (moi yêu cầu, chốt design)
  ② Specs     → /opsx:propose                 (sinh proposal+design+specs+tasks)
  ③ Implement → spec-loop                     (tự code→review→fix tới khi match)
  ④ Archive   → /opsx:archive                 (gộp specs, đóng change)
```

## 3. Tell them the single next action
One line: the exact command to run next given the detected stage. If at Stage 0, suggest `/my-goal "<điều bạn muốn>"` to run the whole thing, or `/opsx:propose` to just write specs.

## 4. Skill / agent inventory
List the toolkit, one line each, so they remember what's available:
- `/my-goal <mô tả>` — nhạc trưởng: tự chạy cả pipeline; mức tự động tùy độ rõ; tự phân tích task → chọn expert skill (nestjs-expert/postgres-pro/react-expert…) để code; cuối cùng tự ghi context (logic + why) vào memory cho session sau
- `dev-workflows:task-analyzer` — phân tích task (essence/type/scale/tags) → gợi ý expert skill phù hợp
- `grill-me` — phỏng vấn bạn để chốt plan trước khi code
- `/opsx:explore` — nghĩ thông một vấn đề mơ hồ/lớn
- `/opsx:propose` — sinh specs + design + tasks từ 1 mô tả
- `spec-loop` — tự implement→review độc lập→fix tới khi khớp hết specs
- `/opsx:archive` — đóng change, gộp delta specs vào specs chính
- `/opsx:sync` — đẩy delta specs vào specs chính (không archive)
- (hỗ trợ) `dev-workflows:code-verifier` — đối chiếu code vs specs; `dev-workflows:quality-fixer` — sửa lỗi lint/build/test

Keep the whole output compact — it's a glanceable cheat-sheet, not a tutorial. Then stop.
