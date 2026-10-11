[![Türkçe sürüm](https://img.shields.io/badge/Language-T%C3%BCrk%C3%A7e-E30A17?style=for-the-badge)](README.tr.md)

# Case study: ERC-4337 EntryPoint v0.8 security review

> ### Finding: a deterministic correctness defect in `EntryPoint` v0.8 core
>
> | | |
> |---|---|
> | Severity | Low: an attribution/correctness defect; it allows neither theft nor censorship |
> | Prior audits | Three public audit reports ship in the repository |
> | Reproduced | Twice: on the local toolchain, then again under real EIP-7702 semantics on a digest-pinned Prague client |
> | Isolated by | A sibling code path that handles the equivalent case correctly, which rules out "intended behaviour" |
> | Upstream status | Still unfixed at time of review |
> | Disclosure | Not submitted to any program; mechanism withheld (see below) |

- Role: independent security researcher
- Target: ERC-4337 Account Abstraction, the `EntryPoint` v0.8 core contracts (open-source, widely deployed)
- Scope commit: `4cbc06072cdc19fd60f285c5997f4f7f57a588de`
- Outcome: one Low-severity deterministic correctness defect, reproduced with two independent proofs of
  concept and written up to submission standard

> For non-technical readers: millions of cryptocurrency wallet accounts rely on one shared piece of
> public infrastructure code that has been professionally inspected at least three times. I reviewed
> it independently and found a small but real flaw in how it records who was at fault when certain
> operations fail. It is a bookkeeping error and gives no way to steal funds. I reproduced it in two
> environments. The full mechanism stays private.

> Disclosure status: the report was prepared to submission standard but has not been submitted to a
> bug bounty program, and the defect is not fixed upstream. For that reason the specific file,
> function and mechanism are withheld from this public case study. Nothing here claims
> that any program reviewed, validated or paid for this finding. Full materials are available
> privately, under confidentiality, on request.

## The target

Three public audit reports for ERC-4337's `EntryPoint` ship in its repository, and multiple firms
have reviewed it.

The finding is a Low-severity attribution/correctness defect. It is neither a theft nor a censorship
exploit. The rest of this page describes how it was found and proved.

## Method

### The invariant comes from the protocol's own documentation

The defect violates a property that the project's interface documentation states explicitly. The
report cites the documented semantics as the oracle, so the bug is measured against the protocol's
own specification. My opinion of how the code should behave does not come into it.

### Isolated by a sibling code path

An analogous path in the same function handles the equivalent case correctly. Showing that asymmetry
turns "this looks wrong" into "this is objectively an oversight". It rules out intended behaviour,
and with it the most common triager objection.

### Negative control built into the proof

Both the defect case and the control place the failing operation in the same position; only the
affected path misreports. Because the sole difference is the code path taken, the harness is ruled
out as the cause.

### Two execution environments

The local toolchain isolates the control-flow defect, but it caps at an EVM revision that cannot
execute the delegation semantics the path depends on. A second proof therefore runs against a
digest-pinned Prague client with a real authorization tuple and a deployed delegate. The inner
revert string is the delegate's own message, which confirms that the delegated code really executed
and that the branch was not reached for some unrelated reason.

### Impact bounded by reachability

The report keeps the primary impact (a deterministic, in-scope correctness defect) apart from the
secondary effects. Those are written with "may" and explicitly marked as conditional on a specific
off-chain consumer's behaviour. The report says outright that there is no fund loss, no unauthorized
execution and no direct on-chain censorship. It also documents the reachability limit: a
standards-compliant bundler would filter the failing operation before it ever reaches a bundle. A
reviewer does not have to find that weakness in the argument on their own.

## Report structure

The write-up has these sections:

Title · Summary · Severity · Affected commit and in-scope files (supporting files marked
out-of-scope) · Root cause with the vulnerable code and the correct sibling path · Expected vs Actual ·
Observable deterministic defect · Protocol-level impact (primary vs conditional-secondary) ·
Reachability and limitations · Environment freeze · Production-code-diff evidence · How to
reproduce with exact file placement · Exact commands and full verbatim output · Negative control ·
Proof-of-concept sources · Public duplicate-search summary · Suggested remediation with a concrete patch.

The duplicate search covered the three in-repo audit reports, in-code comments, the existing test
suite, upstream issues and pull requests, release notes and the relevant ERC specifications. The
closest prior art was examined: it sits in a different location, uses a different mechanism, and was
already fixed in the reviewed tree. The search found no public duplicate. Private reports cannot be
observed.

## Artifacts

| File | Contents |
|---|---|
| `evidence/reproducibility.md` | Environment freeze, pinned client digest, dual-PoC results, production-diff evidence |
| `../../METHODOLOGY.md` | The engineering standard this engagement followed |
| `private-annex/` | Full report, both PoC test files, and the test-only helper contract (on request, under confidentiality) |

## Stack used

Solidity · Hardhat · TypeScript · ERC-4337 Account Abstraction · EIP-7702 delegation · EVM hardfork
semantics (Cancun vs Prague) · Docker-pinned geth · Foundry-style negative-control test design
