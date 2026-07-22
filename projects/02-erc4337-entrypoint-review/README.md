# Case Study — ERC-4337 EntryPoint v0.8 Security Review

> ### Finding: a deterministic correctness defect in `EntryPoint` v0.8 core
>
> | | |
> |---|---|
> | **Severity** | Low (attribution/correctness — not theft, not censorship) |
> | **Target difficulty** | One of the ecosystem's most heavily audited contracts — three public audit reports ship in the repo |
> | **Reproduced** | **Twice** — local toolchain, then again under genuine EIP-7702 semantics on a digest-pinned Prague client |
> | **Isolated by** | A sibling code path that handles the equivalent case **correctly** → rules out "intended behaviour" |
> | **Upstream status** | Still unfixed at time of review |
> | **Disclosure** | **Not submitted** to any program — mechanism withheld (see below) |

**Role:** Independent security researcher (solo)
**Target:** ERC-4337 Account Abstraction — `EntryPoint` v0.8 core contracts (open-source, widely deployed)
**Scope commit:** `4cbc06072cdc19fd60f285c5997f4f7f57a588de`
**Outcome:** One **Low-severity** deterministic correctness defect identified, reproduced with two
independent proofs of concept, and written up to submission standard.

> **In plain terms (for non-technical readers).** Millions of cryptocurrency wallet accounts rely on
> one shared piece of public infrastructure code that has been professionally inspected at least
> three times. I reviewed it independently and found a small but genuine flaw in how it records who
> was at fault when certain operations fail — a bookkeeping error, not a way to steal funds. I
> reproduced it in two environments and am withholding the technical recipe until the maintainers
> fix it.

> **Disclosure status — stated plainly.** This report was prepared to submission standard but has **not
> been submitted** to a bug bounty program, and the defect is **not fixed upstream**. Accordingly, the
> specific file, function, and mechanism are **deliberately withheld** from this public case study. No
> claim is made that any program reviewed, validated, or paid for this finding. Full materials are
> available privately, under confidentiality, on request.

---

## What this demonstrates

ERC-4337's `EntryPoint` is one of the most heavily audited contracts in the ecosystem — three public
audit reports ship in the repository, and it has been reviewed by multiple firms. Finding anything
real in it requires reading the code far more carefully than an audit checklist does.

The finding is a **Low-severity attribution/correctness defect**, not a theft or censorship exploit.
The review demonstrates specification-driven analysis, environment fidelity and controlled
reproduction on heavily audited infrastructure.

---

## Method

**Invariant sourced from the protocol's own documentation.** The defect is a violation of a property
the project's interface documentation states explicitly. The report cites the documented semantics as
the oracle, so the bug is a deviation from the protocol's own specification rather than from my
opinion about how it should behave.

**Isolated by a sibling code path.** An analogous path in the same function handles the equivalent case
**correctly**. Demonstrating that asymmetry is what turns "this looks wrong" into "this is objectively
an oversight, not intended behaviour" — and it removes the most common triager objection.

**Negative control built into the proof.** Both the defect case and the control place the failing
operation in the same position; only the affected path misreports. Because the sole difference is the
code path taken, the harness is ruled out as the cause.

**Two execution environments.** The local toolchain isolates the control-flow defect but caps at an
EVM revision that **cannot execute the delegation semantics** on which the path depends. A second
proof therefore runs against a digest-pinned Prague client with a genuine authorization tuple and a
deployed delegate. The inner revert string is the delegate's own message, confirming that delegated
code executed rather than reaching the branch for an unrelated reason.

**Impact bounded by reachability.** The report separates the **primary** impact (a deterministic,
in-scope correctness defect) from **secondary** effects, which are written with "may" and explicitly
marked conditional on a specific off-chain consumer's behaviour. It states outright: *no fund loss, no
unauthorized execution, no direct on-chain censorship.* It also documents the reachability limits — a
standards-compliant bundler would filter the failing operation before it ever reaches a bundle — so a
reviewer does not have to discover the weakness in the argument themselves.

---

## Report structure

The write-up follows the same submission template I use for every finding:

Title · Summary · Severity · Affected commit and in-scope files (supporting files marked
out-of-scope) · Root cause with the vulnerable code and the correct sibling path · Expected vs Actual ·
Observable deterministic defect · Protocol-level impact (primary vs conditional-secondary) ·
Reachability and limitations · Environment freeze · Production-code-diff evidence · How to
reproduce with exact file placement · Exact commands and full verbatim output · Negative control ·
Proof-of-concept sources · Public duplicate-search summary · Suggested remediation with a concrete patch.

**Duplicate search** covered the three in-repo audit reports, in-code comments, the existing test
suite, upstream issues and pull requests, release notes, and the relevant ERC specifications. The
closest prior art was identified, examined, and shown to be a **distinct location and mechanism**, and
confirmed already fixed in the reviewed tree. The search found no public duplicate; private reports
are not observable.

---

## Artifacts

| File | Contents |
|---|---|
| `evidence/reproducibility.md` | Environment freeze, pinned client digest, dual-PoC results, production-diff evidence |
| `../../METHODOLOGY.md` | The engineering standard this engagement followed |
| `private-annex/` | Full report, both PoC test files, and the test-only helper contract — on request, under confidentiality |

## Stack used

Solidity · Hardhat · TypeScript · ERC-4337 Account Abstraction · EIP-7702 delegation · EVM hardfork
semantics (Cancun vs Prague) · Docker-pinned geth · Foundry-style negative-control test design
