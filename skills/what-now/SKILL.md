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
- change exists, specs/ADRs being written, not yet reviewed → **Stage 1: Plan & Specify** (`/my-goal`)
- specs + ADRs final/approved, tasks unchecked or partial → **Stage 2: Build** (`/implement-specs`)
- tasks all checked, not archived → **Stage 3: Archive**
- archived → **Done**

## 2. Print the pipeline map with "you are here"
Render this, marking the current stage with `👉`:

```
🗺️  CHỌN ĐƯỜNG THEO LOẠI VIỆC
  • Bug / lỗi nhỏ      → /fix          (diagnose → chọn expert → minimal fix → verify)
  • Feature / thay đổi → /my-goal …    (đường SDD 2 phase bên dưới)
  • Typo / 1 dòng      → làm thẳng, không cần skill

🗺️  SPEC-DRIVEN PIPELINE  (cho feature — 2 phase, review ở giữa)
  ① Plan & Specify → /my-goal "<goal>"     (clarify → specs + ADR → STOP for review)
        ⤷ uses grill-me / /opsx:explore / /opsx:propose
  — 👁  human reviews & approves specs + ADRs —
  ② Build          → /implement-specs       (spec-loop: code→review→fix tới khi match)
        ⤷ implements via the recommended experts, then quality gate
  ③ Archive        → /opsx:archive          (gộp specs, đóng change)
  ④ Context        → auto-ghi memory         (logic + why cho session sau)
```

## 3. Tell them the single next action
One line: the exact command to run next given the detected stage.
- Stage 0 → `/my-goal "<điều bạn muốn>"` (lên specs + ADR cho review)
- Stage 1 (specs đã có, chờ duyệt) → review rồi `/implement-specs`
- Stage 2 (đang/đã code) → `/implement-specs` để tiếp tục, hoặc `/opsx:archive` nếu tasks đã xong

## 4. Skill / agent inventory
List the toolkit, one line each, so they remember what's available:
- `/fix <bug>` — **đường nhẹ cho bug**: diagnose → chọn expert → minimal fix → verify; tự leo thang sang /my-goal nếu hoá ra to
- `/my-goal <mô tả>` — **Phase 1**: clarify → specs + ADR → recommend expert → DỪNG cho review (không code)
- `/implement-specs` — **Phase 2**: sau khi chốt specs/ADR → spec-loop code qua experts → quality gate → archive → ghi memory
- `grill-me` — phỏng vấn bạn để chốt plan
- `/opsx:explore` — nghĩ thông vấn đề mơ hồ/lớn
- `/opsx:propose` — sinh specs + design + tasks từ 1 mô tả
- `spec-loop` — tự implement→review độc lập→fix tới khi khớp specs
- `dev-workflows:task-analyzer` — phân tích task → gợi ý expert skill phù hợp
- `dev-workflows:technical-designer` — viết ADR / design doc
- `/opsx:archive` · `/opsx:sync` — đóng change / đẩy delta specs vào specs chính
- (hỗ trợ) `dev-workflows:code-verifier` — đối chiếu code vs specs; `dev-workflows:quality-fixer` — sửa lint/build/test

Keep the whole output compact — it's a glanceable cheat-sheet, not a tutorial. Then stop.
