[![Türkçe sürüm](https://img.shields.io/badge/Language-T%C3%BCrk%C3%A7e-E30A17?style=for-the-badge)](METHODOLOGY.tr.md)

# Security Review & Proof-of-Concept Methodology

My evidence standard for auditing a codebase, proving a defect, and packaging it to a level a triager
can act on without asking follow-up questions. It is protocol-agnostic; the worked example that
produced it was an ERC-4337 EntryPoint review.

This document is deliberately narrower than my general delivery process: it covers adversarial
review, defect proof and triager-ready packaging. For how a change reaches production — the gate
ladder, ratcheted debt baselines, tests that detect rather than execute, release verification and
rollback — see the [Delivery & Quality-Gate Methodology](DELIVERY-METHODOLOGY.md).

**North star: evidence before assertions.** A finding is worth reporting only when a running proof ties
an attacker-controlled input to a violated invariant with measured impact on an honest party, and the
root cause is in scope and not a duplicate.

---

## 0. Prime directives

1. **Never claim a command succeeded without reading its actual output.** A wrapper exit code of 0 does
   not mean the underlying tool passed. Read stdout/stderr and the real exit code. (Real trap: a test
   command returned exit 0 while the test runner never started.)
2. **Never manufacture findings.** On a heavily-audited codebase, an empty result is the correct and
   expected outcome. Zero real findings beats twenty plausible-but-wrong ones.
3. **Correct your own overclaims out loud.** If later analysis weakens an earlier claim, say so and
   tighten it — before submission, not after a triager finds it.
4. **Do not disclose before submitting.** No public issues, no pushes to public remotes, no published
   artifacts. Findings stay local until submitted through the proper channel.
5. **Reproducibility is a claim you must back.** Pin the exact commit, toolchain, and any external
   client by immutable identity (image digest, not a mutable tag). If you can't reproduce it, don't
   claim it.

## 1. Environment & baseline (before any hunting)

Lock the scope commit and verify `git rev-parse HEAD` matches it. Match the project's CI toolchain —
read the CI config for the pinned runtime and reproduce it locally; verify what actually resolves
(`node --version`, `which node`, compiler version and EVM target from config). Install, compile, and
**read the output**: confirm "compiled N files successfully" and that artifacts exist.

Establish the baseline test result verbatim: exact command, total/passed/failed/skipped, exit code.
**Triage every failure into (a) real defect, (b) host/OS environment, or (c) missing dependency**, and
prove the classification. A green-enough baseline is required before a new test's pass means anything.

Know your execution ceiling: local simulators often cap at an older hardfork and cannot execute newer
semantics. Note that limit up front rather than discovering it mid-proof.

## 2. Duplicate baseline — build the "already known" wall first

"Not in the repo's audit PDFs" is not evidence of novelty. Build the known-issues list from all of:
every audit report, in-code comments documenting intentional design, the existing test suite (a test
asserting a behaviour means that behaviour is intended), upstream issues *and* pull requests, release
notes, the protocol spec, and public disclosures.

Maintain two lists: **known-and-still-present** (highest duplicate risk — these look novel but aren't)
and **design-decisions-that-look-like-bugs** (false-positive generators). Feed both into every later
analysis.

Final novelty wording is always: *"No public duplicate or prior-art match was found. Private reports
are not observable."* Never assert categorically that something is not a duplicate.

## 3. Invariant specification = the oracle

Read every in-scope file in full, then write the security invariants — the predicates an attacker must
break to steal or grief. Typical classes: solvency and asset conservation, payment conservation,
replay/uniqueness, resource accounting, isolation between operations, memory safety of hand-rolled
assembly, validation/execution separation, reentrancy coverage.

For each invariant record: an ID, the formal predicate, the exact enforcing code at `file:line`, its
assumptions, and the single most plausible way it breaks under the threat model. Those break-hypotheses
become the hunting targets — hunting without this step is undirected reading.

## 4. Adversarial method

Work one attack surface at a time, each pass given the threat model, the invariant spec, and the
known-issues wall. Read real source rather than excerpts, simulate assembly word-by-word, compute
concrete gas/value/offset numbers, and find the reachable input that wraps any unchecked arithmetic.
An empty result from a pass is a valid answer.

Then subject every surviving candidate to **independent skeptical review from at least three angles**,
keeping only what survives a majority:
- **Refute** — re-derive control flow from source; find the guard, type bound, or earlier revert that blocks it.
- **Duplicate / intent** — check against the known-issues wall, comments, tests, and spec.
- **Impact** — who actually loses money or liveness, quantified; is it self-griefing; does it require an already-broken victim?

Default to "refuted" when uncertain. A vote count proves nothing on its own — only a running proof with
an in-scope root cause and measured impact does. Finish with a coverage critic: which surface,
invariant, or attacker role was under-covered? That seeds the next round.

Persist intermediate results to disk continuously so a long review can be resumed rather than repeated.

## 5. The five-link chain (mandatory)

Report a candidate only if all five hold; if any is missing, drop it.

1. **Attacker-controlled input** — exactly which bytes, fields, or values the attacker sets.
2. **Reachable path** — the concrete call sequence with `file:line` per hop, and why no earlier require/revert blocks it.
3. **Violated invariant** — a precise predicate, referencing the spec ID.
4. **Measured impact** — quantified: value stolen, gas lost, unauthorized executions, or verifiable DoS cost. Not "could be bad."
5. **Reproducible proof** — a runnable test against the real contracts at the scope commit.

Explicitly rejected: gas/style optimization, centralization and admin risk, "missing zero-check" with
no exploit, unreachable theoretical overflow, and anything requiring the victim to be already malicious
or already broken.

## 6. Scope gate for untrusted entities

In many protocols some entities sit outside the trust boundary. **An attacker deploying their own
malicious such contract is a valid adversarial primitive** — that alone does not put a finding out of
scope. The defect must be the in-scope core code *mishandling* that untrusted behaviour.

Reject only if: the root cause is exclusively in that entity's own implementation; the attack requires
an *honest* counterparty to be non-compliant; a standards-compliant simulation would already reject the
operation; the result is attacker self-griefing; or no honest operation, deposit, invariant, or
availability property is affected.

**Phase distinction:** validation-time rules do not apply to execution or callback phases. Don't
auto-reject an execution-phase attack for violating validation rules.

## 7. Proof-of-concept rules

- **Root cause in scope.** Confirm exactly which directories are in scope. Interface and doc files may be *referenced* but are labelled "reference only, not in scope."
- **No mock that eases the real flow.** The attacker's contract may be custom, but the test must exercise the real entry point, real accounting, and real revert/callback behaviour. State-injection helpers are acceptable *only* to place attacker-controlled state or reach the in-scope branch — never to shortcut the core's own logic — and must be disclosed in the test header.
- **A negative control is mandatory.** Assert that the effect disappears without the attacker input, so it is proven to come from the claimed root cause and not the harness.
- **Assert the invariant concretely** — balances before/after, execution counts, the exact wrong field value — so the test fails on fixed code and passes on vulnerable code.
- **Reuse the project's own test helpers.** Study the existing tests first; don't reinvent them.
- Run the proof **in isolation first**, then alongside the existing suite, so it cannot hide behind pre-existing failures.

## 8. Execution-semantics rigor

A local-simulator pass does not by itself prove real client behaviour. Anything depending on a specific
hardfork's execution or on client-specific behaviour must be reproduced on a real client at the correct
hardfork. If the local network cannot execute the feature, an *approximation* proving the control-flow
defect is acceptable — but label it honestly and build a second proof on a real client.

Pin external clients by **digest, not tag**: record image name, digest, client version and commit, chain
config, and the exact run command. If a test self-skips when the client is unreachable, a
skipped result is **not** evidence — a successful reproduction must report the expected pass count.

## 9. Report package

In order: Title; Summary; Severity; Affected commit and in-scope files (supporting files clearly marked
out-of-scope); Root cause with the exact vulnerable code and the correct sibling path if one exists;
Expected vs Actual; Observable defect; Protocol-level impact (primary = the in-scope correctness or
asset defect; secondary effects framed with "may", never asserted); Reachability and honest limitations;
Environment freeze; Production-code-diff evidence; How to reproduce with exact file placement; Exact
commands and full verbatim output; Negative control; Sources; Duplicate-search summary; Suggested
remediation.

**Production-code-diff evidence:** the proof adds only test files. Show that `git diff` over the
in-scope directories is empty and record each file's SHA-256. **Recompute all hashes after any edit** —
stale hashes are a red flag.

**Severity is evaluated separately from pass/fail.** A passing test proves the behaviour exists, nothing
more. For high severity additionally establish: an honest victim, real economic loss or unauthorized
execution, attacker cost, scalability, existing mitigations, and whether the impact is single-transaction
or repeatable. **A defensible Low beats a disputed Medium.**

## 10. Packaging hygiene

Submit the solid finding rather than holding it for a bigger one; add later work as supplements to the
existing thread rather than duplicate reports. Preserve the exact repo-relative tree in any archive —
flattening breaks relative imports and the reviewer sees phantom compile errors. Never include the whole
repo, dependency directories, version-control metadata, keys, tokens, or seeds. Keep the report readable
on its own; the archive is complete evidence, not a substitute for a clear write-up.
