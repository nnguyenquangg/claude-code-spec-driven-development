---
name: diagnose
description: Disciplined debugging loop for hard bugs, flaky tests, wrong outputs and performance regressions - reproduce, minimise, hypothesise, instrument, fix, guard. Use when a bug resists a first fix, the same failure repeats, the cause is unclear, or the user says "debug", "why does", "it still fails".
---

# Diagnose

Guessing at fixes is the slow path. Each phase has an exit condition; do not skip ahead.

1. **Reproduce.** A command or test that shows the bug every time (or a measured failure
   rate for flaky ones). Exit: you can make it fail on demand.
2. **Minimise.** Remove everything not needed to make it fail: smaller input, fewer
   steps, one module. Exit: a minimal failing case.
3. **Hypothesise.** List 2–3 possible causes, each with what you would observe if it were
   true. Pick the cheapest to test.
4. **Instrument.** Add logging, assertions or a debugger breakpoint that distinguishes the
   hypotheses. Read actual values; do not assume. Exit: one hypothesis confirmed by data.
5. **Fix** the confirmed cause, the smallest change. Remove the instrumentation.
6. **Guard.** The reproduction becomes a regression test. Run the project's checks.

If two hypotheses in a row are wrong, write down what you have ruled out before continuing.
If the bug class could happen elsewhere, note it for the project (a lint rule, a check, or a
line in its `CLAUDE.md`) instead of only fixing this instance.
