[![Türkçe sürüm](https://img.shields.io/badge/Language-T%C3%BCrk%C3%A7e-E30A17?style=for-the-badge)](METHODOLOGY.tr.md)

# Security review and proof-of-concept methodology

This is the evidence standard I use for adversarial review: when I audit a codebase, prove a defect
and package it so that a triager can act on it without coming back with questions. It came out of
an ERC-4337 EntryPoint review, but nothing in it is specific to that protocol.

It covers less ground than my general delivery process. How a change reaches production (the gate
ladder, ratcheted debt baselines, tests judged by what they catch, release verification and
rollback) is in the [delivery and quality-gate methodology](DELIVERY-METHODOLOGY.md).

One rule sits under all of it: evidence before assertions. I report a finding only when a running
proof ties an attacker-controlled input to a violated invariant, with measured impact on an honest
party. The root cause also has to be in scope, and the finding must not be a duplicate.

## 0. Ground rules

1. A command has succeeded only when its output says so. A wrapper can exit with 0 and still say
   nothing about the tool underneath; stdout, stderr and the real exit code all get read. This has
   happened: a test command returned 0 while the test runner never started.
2. Findings are never manufactured. On a heavily audited codebase an empty result is correct, and
   it is what you should expect. Zero real findings beats twenty plausible but wrong ones.
3. Overclaims are corrected in the open. If later analysis weakens an earlier claim, I narrow the
   claim before submission and say what changed. A triager should never be the one who finds it.
4. Nothing is disclosed before submission. Findings stay local until they go in through the proper
   channel. Public issues and public remotes are off limits until then, and so is publishing any
   artifact.
5. Reproducibility is a claim too, and it needs backing. The exact commit, the toolchain and any
   external client are pinned by an immutable identity. For a client image that is its digest; a
   tag can move. Whatever cannot be reproduced is not claimed.

## 1. Set up the environment and baseline first

Lock the scope commit and check that `git rev-parse HEAD` matches it. Then match the toolchain to
the project's CI: find the pinned runtime in the CI config, reproduce it locally, and check what
actually resolves (`node --version`, `which node`, the compiler version, the EVM target from the
config). Install and compile next. Read the output: it should say "compiled N files
successfully", and the artifacts should exist.

Record the baseline test result word for word: the exact command, the total/passed/failed/skipped
counts and the exit code. Every failure goes into one of three groups, and you prove which one:
(a) a real defect, (b) the host or OS environment, (c) a missing dependency. Until the baseline is
green enough, a new test passing means nothing.

Know your execution ceiling. Local simulators often stop at an older hardfork and cannot run newer
semantics. Write that limit down at the start, before it surprises you halfway through a proof.

## 2. Build the "already known" wall first

A finding that is missing from the repo's audit PDFs may still be known. So the known-issues list
draws on every audit report, and on the code comments that document intentional design. The
existing tests go in too (if a test asserts a behaviour, that behaviour is intended), and after them
upstream issues *and* pull requests, release notes, the protocol spec and public disclosures.

Keep two lists. The first is *known and still present*. These carry the highest duplicate risk:
they look new and aren't. The second is *design decisions that look like bugs*, and false
positives come from there. Both lists go into every later analysis.

The novelty statement always reads: *"No public duplicate or prior-art match was found. Private
reports are not observable."* Never state flatly that something is not a duplicate.

## 3. Write the invariant specification

Read every in-scope file in full first. Then write down the security invariants, the predicates an
attacker has to break to steal or grief. The usual classes are solvency and asset conservation,
payment conservation, replay/uniqueness, resource accounting, isolation between operations, memory
safety of hand-rolled assembly, validation/execution separation and reentrancy coverage.

Each invariant gets an ID and its formal predicate. It also gets the exact code that enforces it at
`file:line`, its assumptions, and the single most plausible way it breaks under the threat model.
Those break hypotheses are what you hunt for. Without them, hunting is just undirected reading.

## 4. Adversarial method

I take one attack surface at a time, with the threat model, the invariant spec and the known-issues
list at hand. The work is on the real source files, not on excerpts. Assembly gets simulated word by
word and gas, value and offset figures are worked out as concrete numbers; any unchecked arithmetic
is traced to the reachable input that would wrap it. Coming up empty is a valid result.

Whatever comes out of this is a candidate, and each candidate then faces three sceptical questions:

- Can it be refuted? Re-derive the control flow from source and look for the guard, type bound or
  earlier revert that blocks it.
- Is it already known, or intended? Compare it with the known-issues list, the code comments, the
  tests and the spec.
- What is the impact? Who actually loses money or liveness, and how much? Is it self-griefing? Does
  it need a victim that is already broken?

A candidate that is still in doubt counts as refuted. Getting through these checks proves nothing on
its own, though; only a running proof with an in-scope root cause and measured impact does.
Each round ends with a look at coverage: which surface, invariant or attacker role got too little
attention? The next round starts there.

## 5. The five-link chain

A candidate is reported only if all five links hold. One missing link and it is dropped.

1. An attacker-controlled input, stated exactly: which bytes, fields or values the attacker sets.
2. A reachable path: the concrete call sequence with `file:line` for each hop, and the reason no
   earlier require/revert blocks it.
3. A violated invariant, written as a precise predicate that references its spec ID.
4. Measured impact in numbers: value stolen, gas lost, unauthorized executions or a verifiable DoS
   cost. "Could be bad" does not count.
5. A reproducible proof, meaning a runnable test against the real contracts at the scope commit.

Some things are rejected outright: gas/style optimization, centralization and admin risk, a
"missing zero-check" with no exploit, unreachable theoretical overflow. So is anything that needs
the victim to be malicious or broken already.

## 6. Scope gate for untrusted entities

In many protocols some entities sit outside the trust boundary. Say an attacker deploys their own
malicious contract of that kind: that is a valid adversarial primitive, and on its own it does not
put the finding out of scope. The defect has to be in the in-scope core code, though, in the way it
*mishandles* that untrusted behaviour.

Reject the candidate only if one of these holds:

- the root cause is entirely in that entity's own implementation;
- the attack needs an *honest* counterparty to be non-compliant;
- a standards-compliant simulation would already reject the operation;
- the result is the attacker griefing themselves;
- no honest operation, deposit, invariant or availability property is affected.

Keep the phases apart. Validation-time rules do not apply to the execution or callback phases. So
an execution-phase attack should not be rejected automatically just because it breaks validation
rules.

## 7. Proof-of-concept rules

- The root cause has to be in scope, so confirm exactly which directories are. Interface and doc
  files may be *referenced*, but they are labelled "reference only, not in scope."
- No mock may make the real flow easier. The attacker's contract can be custom, but everything the
  test goes through has to be real: the entry point, the accounting, the revert/callback behaviour.
  A state-injection helper is acceptable *only* to place attacker-controlled state or to
  reach the in-scope branch, never to shortcut the core's own logic. The test header has to
  disclose it.
- A negative control is mandatory. Take the attacker input away and assert that the effect
  disappears. That proves it comes from the claimed root cause and not from the harness.
- Assert the invariant with concrete values: balances before and after, execution counts, the exact
  wrong field value. The test should fail on fixed code and pass on vulnerable code.
- Reuse the project's own test helpers. Study the existing tests first and don't reinvent them.
- Failures that were already in the suite can mask a new result. So run the proof on its own first,
  and only then together with the existing suite.

## 8. Execution semantics on a real client

A pass on a local simulator is not proof of how a real client behaves. If the result depends on a
specific hardfork's execution, or on behaviour specific to one client, reproduce it on a real client
at the correct hardfork. If the local network cannot execute the feature at all, an *approximation*
that proves the control-flow defect is acceptable, provided it is labelled as an approximation and a
second proof is built on a real client.

Pin external clients by digest, since a tag can move. Record the image name and the digest, the
client version and commit, the chain config and the exact run command. Some tests skip themselves
when the client is unreachable. A skipped result is not evidence. A successful reproduction has to
report the expected pass count.

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
edit; a stale hash is a red flag.

Severity is judged apart from pass/fail. A passing test proves the behaviour exists, and nothing
more. A high-severity claim has to establish more than that. Is there an honest victim, and real
economic loss or unauthorized execution? What does it cost the attacker, and does it scale? Which
mitigations exist already? Is the impact a single transaction, or repeatable? A Low you can defend
is worth more than a Medium that gets disputed.

## 10. Packaging hygiene

Submit a solid finding when you have it; don't hold it back for a bigger one. Later work goes into
the existing thread as a supplement, never as a duplicate report. Any archive keeps the exact
repo-relative tree. Flatten it and the relative imports break, and the reviewer sees compile errors
that aren't real. Never include the whole repo, dependency directories, version-control metadata,
keys, tokens or seeds. The report has to make sense on its own: the archive holds the complete
evidence, but a clear write-up still has to explain it.
