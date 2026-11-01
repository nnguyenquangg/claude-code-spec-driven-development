# Global standards (judgement; mechanical rules belong in linters)

- Names say what a thing is in the project's vocabulary, not how it is stored.
- A function does one thing at one level of abstraction; a module hides a decision.
- Errors are handled where something useful can be done about them; never swallowed silently.
- No speculative generality: no parameters, hooks or abstractions the task did not need.
- Tests check behaviour through public interfaces; expected values come from an independent
  source (a literal, the spec), never recomputed the way the code computes them.
- No secrets, tokens or customer data in code, tests, fixtures or logs.
- New external input (HTTP body, query, file, message) is validated at the boundary.
- A value that is always the same is not a field: remove it end to end instead of hard-coding it.
