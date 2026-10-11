[![Türkçe sürüm](https://img.shields.io/badge/Language-T%C3%BCrk%C3%A7e-E30A17?style=for-the-badge)](METHODOLOGY.tr.md)

# Security review and proof-of-concept methodology

This is the evidence standard I use when I audit a codebase, prove a defect and package it so that a
triager can act on it without coming back with questions. It came out of an ERC-4337 EntryPoint
review, but nothing in it is specific to that protocol.

The scope is narrower than my general delivery process. It covers adversarial review,
proving a defect and packaging it for a triager. How a change reaches production (the gate ladder,
ratcheted debt baselines, tests judged by what they catch, release verification and rollback) is in
the [delivery and quality-gate methodology](DELIVERY-METHODOLOGY.md).

The rule under all of it is evidence before assertions. I report a finding only when a running proof
ties an attacker-controlled input to a violated invariant with measured impact on an honest party, and
the root cause is in scope and not a duplicate.

## 0. Ground rules

1. A command has succeeded only when its output says so. An exit code of 0 from a wrapper says
   nothing about the tool underneath, so stdout, stderr and the real exit code all get read. This
   has happened: a test command returned 0 while the test runner never started.
2. Findings are never manufactured. On a heavily audited codebase an empty result is the correct and
   expected outcome, and zero real findings beats twenty plausible but wrong ones.
3. Overclaims are corrected openly. If later analysis weakens an earlier claim, the claim is narrowed
   before submission and the change is stated; a triager should never be the one who finds it.
4. Nothing is disclosed before submission. That means no public issues, no pushes to public remotes
   and no published artifacts. Findings stay local until they go in through the proper channel.
5. Reproducibility is a claim too, and it needs backing. The exact commit, the toolchain and any
   external client are pinned by an immutable identity (for a client image, its digest; a tag can
   move). Whatever cannot be reproduced is not claimed.

## 1. Set up the environment and baseline first

Lock the scope commit and check that `git rev-parse HEAD` matches it. Use the same toolchain as the
project's CI: find the pinned runtime in the CI config, reproduce it locally, and check what actually
resolves (`node --version`, `which node`, the compiler version and the EVM target from the config).
Then install, compile and read the output. It should say "compiled N files successfully", and the
artifacts should exist.

Record the baseline test result word for word: the exact command, the total/passed/failed/skipped
counts and the exit code. Put every failure into one of three groups and prove which one it belongs
to: (a) a real defect, (b) the host or OS environment, (c) a missing dependency. A new test passing
means nothing until the baseline is green enough.

Know your execution ceiling. Local simulators often stop at an older hardfork and cannot run newer
semantics. Write that limit down at the start, before it surprises you halfway through a proof.

## 2. Duplicate baseline: build the "already known" wall first

A finding that is missing from the repo's audit PDFs may still be known. Build the known-issues list
from all of these: every audit report, code comments that document intentional design, the existing
test suite (if a test asserts a behaviour, that behaviour is intended), upstream issues *and* pull
requests, release notes, the protocol spec and public disclosures.

Keep two lists. The first is *known and still present*. These carry the highest duplicate risk,
because they look new and aren't. The second is *design decisions that look like bugs*, which is where
false positives come from. Both lists go into every later analysis.

The novelty statement always reads: *"No public duplicate or prior-art match was found. Private
reports are not observable."* Never state flatly that something is not a duplicate.

## 3. The invariant specification is the oracle

Read every in-scope file in full, then write down the security invariants: the predicates an attacker
has to break to steal or grief. The usual classes are solvency and asset conservation, payment
conservation, replay/uniqueness, resource accounting, isolation between operations, memory safety of
hand-rolled assembly, validation/execution separation and reentrancy coverage.

Each invariant gets an ID, the formal predicate, the exact code that enforces it at `file:line`, its
assumptions, and the single most plausible way it breaks under the threat model. Those break
hypotheses are what you hunt for. Without them, hunting is just undirected reading.

## 4. Adversarial method

The review takes one attack surface at a time, with the threat model, the invariant spec and the
known-issues list at hand. It works from the real source files, not excerpts. Assembly is simulated
word by word, gas, value and offset figures are worked out as concrete numbers, and any unchecked
arithmetic is traced to the reachable input that would wrap it. A surface that yields nothing is
still a valid result.

Each candidate that comes out of this is then checked from three sceptical angles:

- Can it be refuted? The control flow is re-derived from source to look for the guard, type bound or
  earlier revert that blocks it.
- Is it already known, or intended? It is compared with the known-issues list, the code comments,
  the tests and the spec.
- What is the impact? Who actually loses money or liveness, and how much? Is it self-griefing? Does
  it need a victim that is already broken?

A candidate still in doubt counts as refuted. Getting through these checks proves nothing on its
own; only a running proof with an in-scope root cause and measured impact does. Each round ends with
a look at coverage: which surface, invariant or attacker role got too little attention? The next
round starts there.

Notes and intermediate results are kept in files as the review goes.

## 5. The five-link chain

A candidate is reported only if all five links hold. If any one is missing, it is dropped.

1. An attacker-controlled input, stated exactly: which bytes, fields or values the attacker sets.
2. A reachable path, meaning the concrete call sequence with `file:line` for each hop and the reason
   no earlier require/revert blocks it.
3. A violated invariant, written as a precise predicate that references its spec ID.
4. Measured impact in numbers: value stolen, gas lost, unauthorized executions or a verifiable DoS
   cost. "Could be bad" does not count.
5. A reproducible proof, which is a runnable test against the real contracts at the scope commit.

These are rejected outright: gas/style optimization, centralization and admin risk, a "missing
zero-check" with no exploit, unreachable theoretical overflow, and anything that needs the victim to
be malicious or broken already.

## 6. Scope gate for untrusted entities

In many protocols some entities sit outside the trust boundary. An attacker who deploys their own
malicious contract of that kind is using a valid adversarial primitive, and that alone does not put a
finding out of scope. The defect has to be in the in-scope core code, in the way it *mishandles* that
untrusted behaviour.

Reject the candidate only if the root cause is entirely in that entity's own implementation; the
attack needs an *honest* counterparty to be non-compliant; a standards-compliant simulation would
already reject the operation; the result is the attacker griefing themselves; or no honest operation,
deposit, invariant or availability property is affected.

Keep the phases apart. Validation-time rules do not apply to the execution or callback phases, so an
execution-phase attack should not be rejected automatically for breaking validation rules.

## 7. Proof-of-concept rules

- The root cause has to be in scope. Confirm exactly which directories are in scope. Interface and doc
  files may be *referenced*, but they are labelled "reference only, not in scope."
- No mock may make the real flow easier. The attacker's contract can be custom, but the test has to go
  through the real entry point, the real accounting and the real revert/callback behaviour. A
  state-injection helper is acceptable *only* to place attacker-controlled state or to reach the
  in-scope branch (never to shortcut the core's own logic), and the test header has to disclose it.
- A negative control is mandatory. Assert that the effect disappears without the attacker input; that
  proves it comes from the claimed root cause and not from the harness.
- Assert the invariant with concrete values (balances before and after, execution counts, the exact
  wrong field value), so the test fails on fixed code and passes on vulnerable code.
- Reuse the project's own test helpers. Study the existing tests first and don't reinvent them.
- Run the proof on its own first, then together with the existing suite, so it cannot hide behind
  failures that were already there.

## 8. Execution-semantics rigour

A pass on a local simulator is not proof of how a real client behaves. Anything that depends on a
specific hardfork's execution, or on behaviour specific to one client, has to be reproduced on a real
client at the correct hardfork. If the local network cannot execute the feature, an *approximation*
that proves the control-flow defect is acceptable. Label it as an approximation, though, and build a
second proof on a real client.

Pin external clients by digest, because a tag can move. Record the image name, the digest, the client
version and commit, the chain config and the exact run command. Some tests skip themselves when the
client is unreachable, and a skipped result is not evidence. A successful reproduction has to report
the expected pass count.

## 9. Report package

The report has these sections, in this order: Title; Summary; Severity; Affected commit and in-scope
files (supporting files clearly marked out-of-scope); Root cause with the exact vulnerable code and the
correct sibling path if one exists; Expected vs Actual; Observable defect; Protocol-level impact
(primary = the in-scope correctness or asset defect; secondary effects framed with "may", never
asserted); Reachability and honest limitations; Environment freeze; Production-code-diff evidence; How
to reproduce with exact file placement; Exact commands and full verbatim output; Negative control;
Sources; Duplicate-search summary; Suggested remediation.

For the production-code-diff evidence, the proof adds only test files. Show that `git diff` over the
in-scope directories is empty, and record each file's SHA-256. Recompute all the hashes after any
edit, since a stale hash is a red flag.

Severity is judged separately from pass/fail. A passing test proves the behaviour exists and nothing
more. A high-severity claim also has to establish an honest victim, real economic loss or unauthorized
execution, the attacker's cost, scalability, existing mitigations, and whether the impact is a single
transaction or repeatable. A Low you can defend is worth more than a Medium that gets disputed.

## 10. Packaging hygiene

Submit a solid finding when you have it; don't hold it back for a bigger one. Later work goes into the
existing thread as a supplement, never as a duplicate report. Any archive keeps the exact repo-relative
tree. Flatten it and the relative imports break, and the reviewer sees compile errors that aren't
real. Never include the whole repo, dependency directories, version-control metadata, keys, tokens or
seeds. The report has to make sense on its own: the archive holds the complete evidence, and a clear
write-up still has to explain it.
