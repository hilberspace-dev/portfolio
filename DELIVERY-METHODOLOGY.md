[![Türkçe sürüm](https://img.shields.io/badge/Language-T%C3%BCrk%C3%A7e-E30A17?style=for-the-badge)](DELIVERY-METHODOLOGY.tr.md)

# Delivery & Quality-Gate Methodology

How I take a production system from a change request to a shipped release without depending on
anyone remembering to be careful. It is stack-agnostic; the worked example that produced it was a
multi-tenant commercial platform with a GPU/ML workload, operated under data-protection constraints
and maintained by a very small team.

This is the counterpart to the [Security Review & Proof-of-Concept Methodology](METHODOLOGY.md),
which covers adversarial review, defect proof and triager-ready packaging. The
[portfolio README](README.md) has the short version of how an engagement runs; this is the long
version of what happens inside it.

**North star: a rule that depends on being remembered is not a rule.** Every lesson that cost real
time to learn ends up as something a machine checks, or it comes back.

---

## 0. Prime directives

1. **Evidence before assertions.** Nothing is described as fixed, passing or complete without the
   command that was run, its output and its exit code. Reading the code is not verification. A green
   re-run does not cancel an earlier failure. Anything that was not run gets said out loud.
2. **Fix the class, not the instance.** The commit that fixes the bug is half the work. The other
   half is answering which check should have caught it and did not, and then building that check.
3. **Freeze debt, never widen it.** Existing problems get measured and pinned at their current size.
   New ones fail the build. Nobody edits a baseline to make a gate go green.
4. **Fail closed, and name the blind spot.** On any path carrying money, safety or personal data,
   ambiguity resolves to refusal. Every measurement tool states in its own file what it cannot see.
5. **Smallest change that addresses the root cause.** No unrelated cleanup, no reformatting, no
   speculative abstraction, no unrequested API break riding along in the same diff.

---

## 1. Definition of done for a change

Before writing code: the observable goal, the acceptance criteria, the scope, and the invariants that
must survive. Then read the existing implementation, its tests and the full call chain — not the
function being changed, the chain it sits in. Confirm that every file, route, command and setting the
plan depends on actually exists rather than assuming it from the name.

Then implement the smallest coherent change, run targeted checks while working, and run the
regression suite the change actually calls for. A targeted test plus a screenshot is not a regression
pass, and saying so early is cheaper than being caught by it later.

Finish by reading the whole diff for scope, security and side effects, and by recording what was run
and what it returned. Work that was deliberately skipped is recorded as skipped, with the reason.

Behaviour-preserving refactors are planned before they are executed. Each split of an oversized
module is written down as its own small change, with rules attached: move only code that already
exists inside the unit being split, keep the extracted piece thin and its dependencies injected,
never rename a route or change a response shape in the same change as a move, and leave existing
tests passing without edits beyond imports.

---

## 2. The gate ladder

Four check sets, each a chain that stops at the first failure so the failing command is never
ambiguous.

| Tier | Covers | Runs |
| --- | --- | --- |
| Fast gate | Secret scan, type build, lint, the policy scanners. No suites. | Pre-push hook |
| CI | The same policy set, then lint, server tests, frontend tests, build, end-to-end and smokes, collapsed into one required check | Every pull request |
| Full local run | The policy set plus the full suites, build and the operational smokes | On demand |
| Release and drift | Everything above plus dependency and lockfile policy, audit, governance, deploy readiness, release build and artifact verification | Weekly schedule and every release |

Two things make this work rather than merely exist.

**The local hook is the practical gate.** It installs itself through the package lifecycle and does
nothing outside a checkout, so a fresh clone is covered without anyone configuring it. The remote
policy job runs the same scanner set, so bypassing the local one buys nothing but delay.

**The escape hatch cannot disable the floor.** There is exactly one documented bypass. It skips the
fast gate, never the secret scanning, it announces itself, and reaching for it to save time is
against the rules rather than merely discouraged. Exceptions inside individual scanners work the same
way: they are line-level, carry a written reason, and show up in the diff for review instead of
silently muting a rule.

Every CI step writes its output to a log and exits with the child process's own status, so no wrapper
can turn a failure into a passing step. Each job produces a sanitised diagnostic snapshot, uploaded
only when something fails, and deliberately excluding environment dumps, secrets files, runtime
databases and uploads.

---

## 3. Ratchets: how legacy debt is held

Refusing to ship until the codebase is clean is not a plan. Ignoring the debt is not one either. The
middle path is to measure it, pin it, and make growth fail.

A **numeric ratchet** is one integer that may only go down: raw colour literals outside the design
tokens, permissive schema entries in the API contract, endpoints guarded below their intended tier.
The tool that writes the baseline refuses to record a larger number, so there is no accidental path
upward.

An **inventory ratchet** is a sorted list of known offenders. A new entry fails the build. So does a
*stale* one — if a listed problem has since been fixed, its line has to go in the same change.
Otherwise repaid debt sits in the list as cover for future debt.

Three details separate a ratchet that works from one that decorates the repository:

- **Justifications are required where a machine can require them.** A newly baselined exception is
  written with an `UNJUSTIFIED` placeholder, and the gate keeps failing until somebody replaces it
  with a real reason.
- **Detectors test themselves.** Each pattern rule ships a matching and a non-matching sample, and
  the run fails if a rule stops catching its own bad sample or starts catching the good one. A rule
  that quietly rotted into a no-op is worse than no rule, because it reads as coverage.
- **Baselines live in files, not in the scripts that read them.** An inventory hardcoded in a checker
  drifts silently. In a checked-in file, every exception appears in a diff and someone has to approve
  it.

---

## 4. Tests that detect rather than tests that execute

Coverage measures which lines ran. It does not measure whether the suite would have failed. Coverage
stays as a floor against collapse; the assurance comes from four other things.

**Harness fidelity.** Anything depending on global middleware — authentication, tenant resolution,
CSRF, body parsing, rate limiting — is tested through the real application composition, never against
a handler mounted on a bare framework instance. That distinction is not theoretical: two defects that
reached production were invisible to convenient test setups and obvious the moment the tests booted
the real thing. Existing shortcuts get frozen in a baseline; new ones fail.

**Regression tests that fail first, for the intended reason.** A non-trivial test opens by naming the
defect class, the symptom, and why the previous layer missed it. The strongest version proves it: the
test inlines the pre-fix implementation and asserts that it violates the law under test, so the file
demonstrably fails against the old code rather than merely claiming it would.

**Property tests with an independent oracle.** Independent means the reference implementation shares
no arithmetic with the code under test, so it cannot inherit the defect it exists to catch. On money
paths that means computing the expected value a structurally different way. Example-based tests pin
the known tricky points; the property test states the law those points are instances of.

**Mutation testing where it pays.** One narrow configuration per money-handling module, mutating a
single file and running only that module's tests. Thresholds come from measured runs with the
provably equivalent mutants accounted for in a comment, so the break value means that any *new*
surviving mutant fails. Thresholds go up as coverage improves. They never come down to make a run
pass.

Three habits sit underneath all of it:

- **Determinism is arranged, not hoped for.** No arbitrary sleeps; asynchronous assertions wait on a
  condition. Time-dependent logic takes the clock as a parameter instead of being mocked, which also
  makes it cheap to mutate. Assertions use explicit UTC timestamps.
- **A probe that measured nothing is a failure.** If an isolation test made zero cross-boundary
  attempts, or its control probe never succeeded against its own side, the run fails as a vacuous
  measurement rather than reporting a clean result. This is the delivery-side twin of the negative
  control in the [security methodology](METHODOLOGY.md#7-proof-of-concept-rules).
- **Flakes are investigated, not retried.** Especially accessibility failures, which are defects with
  a legal dimension, not noise. Where a suite is flaky by nature, the flake source is removed —
  animation disabled, fonts awaited — rather than wrapped in a retry that hides a real regression.

Beyond correctness, a weekly non-functional tier asks whether the system stays healthy under
pressure: a load smoke, a long soak, and a stress suite that asserts the *shape* of failure rather
than the absence of errors. A contended booking slot must produce exactly one winner. Hostile input
must be rejected without taking the process down. Tenants racing simultaneously must not read each
other's data. Deliberate backpressure counts as the shield working; anything else does not. Load
thresholds are calibrated from a measured plateau, not chosen because they sound comfortable.

---

## 5. Contracts and boundaries

The API specification is the contract, not documentation written afterwards. It states cross-cutting
behaviour once rather than repeating it per operation, and a new route cannot be pushed before it
appears there.

Coverage is measured from both directions, and twice. A text scan of the source can only see literal
paths passed directly to a route method; it cannot see routers mounted under a prefix, registrations
taking the path as a variable, or loops over a path array. So a second measurement boots the
application, walks the live routing table and compares by path shape, with a sanity assertion on the
number of routes found so a broken walker cannot pass silently. The runtime number is the honest one
and the two are expected to disagree. Three sibling checks protect what coverage cannot see:
unresolved references, which invalidate the document for every strict consumer while looking fine in
review; keywords from an older dialect, which a current validator ignores rather than rejects, making
them silent semantic loss; and operations with no declared security, which read as public to every
integrator and code generator.

Module boundaries are enforced by checks rather than by good intentions. Server code never imports
browser code. The module graph has no cycles, detected over a parsed import graph with type-only
edges excluded because they disappear at runtime. Both allowlists sit at zero, which turns them from
ratchets into invariants. All browser traffic to the API goes through one client that owns
credentials, headers, timeouts and the circuit breaker; anything bypassing it needs a written reason
in a baseline.

Type checking runs in build mode across a project graph rather than as one flat pass, because the
projects have different library and target settings and collapsing them would check server code
against browser globals.

---

## 6. Data, migrations and recovery

Migrations are files, applied in order, recorded with a content hash. Committed migrations are never
edited, and that is not a review convention: the next boot recomputes the hash, refuses to start, and
says what to do instead.

Execution is leader-only, locked across processes and atomic per file. The lock is taken before the
first schema write, so several processes starting at once cannot race to create the same tables on a
fresh database. Crash recovery reclaims a lock only from a process that is provably gone, and falls
back to a staleness check on file age only when liveness cannot be determined — because a synchronous
migration blocks the event loop, so a long index build cannot refresh its own timestamp while very
much alive, and an age-only rule would let a booting peer steal the lock out from under it. That is
verified with real spawned processes contending on the same file, not with mocks.

There are no down migrations. Rollback is a restore from a snapshot. For a single-stack-per-customer
deployment that is the honest answer, and writing it down as a decision beats discovering it during
an incident.

Operational procedures are scripted rather than remembered: scheduled backups with retention and
pruning, size monitoring with warning and critical tiers, and restore and cleanup commands where the
restore validates against path traversal and the cleanup is dry-run by default. Recovery targets and
the ordering the storage model demands live in a runbook, next to the numbers that trigger the next
architectural decision.

---

## 7. Security posture

Each defensive primitive lives in its own module and opens with a comment naming the attack or
incident it closes, which keeps it reviewable in isolation and keeps the reasoning attached to the
code through refactors.

Callbacks that move money are treated as hostile input: verify the signature first, bind the returned
token to the one stored on the intent with a constant-time comparison, retrieve the authoritative
record from the provider, check the collected amount against the expected one, and only then change
state. Amounts are parsed from the digit string rather than multiplied in floating point, because the
floating-point path rounds inconsistently and can read a correct settlement as short. State
transitions repeat their guard inside the SQL predicate so a concurrent callback cannot win a
read-then-write race, terminal states are terminal, and idempotency is a database constraint rather
than an application check.

Where a control has two halves that must agree — a path exempted from body parsing and the same path
exempted from CSRF, for example — a structural test asserts both, and fails on a stale entry as well
as a missing one, so the next addition cannot ship with only one side wired.

Permission tiers get measured rather than argued about. When the question "how many endpoints are
under-guarded" produced two different answers on two different days, the answer was not a third
opinion but a script that produces the same census the same way every time, freezing both the number
and the list so that swapping one entry for another cannot hide a new one. A behavioural test backs
it up, because a text scan goes stale wherever dependency injection hides the guard.

Secrets are scanned at two depths: the working tree, and committed history, so that a credential
which was committed and later removed still blocks the push. The supply chain is policy in code —
pinned lockfile format, registry-only resolution, an allowlist for packages permitted to run install
scripts, third-party CI actions pinned to a full commit hash, explicit permissions on every workflow,
and no interpolation of untrusted input into shell commands.

Findings are triaged rather than accepted or dropped. Review rounds re-score earlier findings, check
each one's primary citation against the code, and write up disproved findings as corrections with the
counter-evidence instead of deleting them. An area that ran out of review budget is recorded as not
done, never described as clean.

---

## 8. Release and deployment

The release artifact is built from an explicit allowlist rather than an ignore list, staged, and then
walked a second time to re-assert the same exclusions. It ships with a checksum and a manifest
recording what went in and which rules were applied.

Verification rebuilds and re-tests the *extracted* copy, not the working tree. The verifier checks the
hash, extracts with a reader that rejects absolute paths and traversal, and then runs install, the
policy scanners, lint, build and the test suites with the working directory set inside the extracted
copy. A blocked subprocess is reported as an environment blocker and is fatal in CI, so the check
cannot quietly downgrade itself into a file listing.

Deployment promotes an already-published artifact and never builds one. The remote script verifies the
checksum, extracts into a per-release directory, refuses to overwrite an existing one, snapshots data
first, installs on the host, records the outgoing release, flips the live pointer, restarts, polls the
health endpoints and rolls back automatically on failure. Readiness is a real dependency probe — an
actual query and actual filesystem checks — because an endpoint that returns healthy unconditionally
keeps a broken instance in rotation.

Release documentation is explicit that a green test run is not the same thing as production sign-off,
and lists the conditions that are: a live payment and refund against a real provider, freshly
generated secrets, and an off-host backup with a *proven* restore rather than a configured one.

---

## 9. Shipping dark, and compliance as a precondition

Significant features ship disabled. One curated catalogue is the only place that lists them for
operators, and its view of each flag has to mirror the consuming code's own semantics, with that code
cited per entry, rather than re-implementing a looser version of the same check.

The status vocabulary has three values on purpose. *On* tells the truth about what is actually running
even when a precondition has since regressed. *Off* means dark and ready. *Blocked* means dark with an
unmet precondition.

The interesting part is what counts as a precondition. Alongside machine-checkable facts — a key is
present, a provider is configured — sit human ones, such as a privacy notice being approved and
published, or an experiment being pre-registered. Those are attested through the same flag mechanism
specifically so the check stays machine-readable. The effect is that a legal or methodological
obligation sits *on the activation path* instead of on a checklist beside it, which is the difference
between a control and a good intention.

Rollout percentages bucket on a stable hash of the flag and the entity, so a partial rollout contains
the same entities every evaluation instead of reshuffling per request, and every evaluation returns a
machine-readable reason naming the rule that decided it.

Outbound integrations go through a durable outbox and a worker, so a user-facing request never waits
on a third party. Idempotency is a unique index over the logical event. Retries back off with a cap,
and exhausted jobs move to an explicit dead state visible to operators rather than disappearing.
Integrations carrying a regulatory obligation fail closed and cite their primary source in the module
header: approval approves, and rejection *or the absence of any record* blocks, because no record
means the action is not lawful. Their cache uses a long lifetime for a definitive answer and a short
one for an error, so an outage degrades to blocked-and-quick-to-recover rather than to permissive.

---

## 10. Documentation as evidence

Documents anyone might act on mark each claim as verified, with the command that produced it, or
open. There is no third state, and anything unmarked is treated as unverified.

Anything containing measurements records the commit and the date it was measured at, and says that
the numbers decay. A document with stale numbers invites the reader to check everything else in it,
which is the opposite of what it was written for.

Decision records follow a fixed shape: a header with date, status and a link back to the finding that
prompted it; context as an observation-and-evidence table where every observation cites a concrete
file or setting; the decision in one sentence; then the work split into what to do now, each item
mapped to the check that will hold it, and what to do when a named numeric trigger fires. They close
by naming the one input that cannot be derived from the code and asking for a decision on it.

Audit findings get stable identifiers and then travel: the same identifier appears in the decision
record, in the check that enforces the fix, and in the follow-up work. An audit also records which
checks were actually executed and states plainly what it did not cover.

Anything with a causal claim is pre-registered before data exists — the primary metric and hypothesis,
the exclusions, the stopping rule, and which secondary metrics are barred from headline claims — and
the design carries a table binding each pre-registered rule to the test that enforces it. Simulation
work runs a null arm, whose gate is that it must never produce a usable result, alongside a
known-truth arm checked against a tolerance derived analytically rather than tuned until it passes.

---

## 11. Working discipline

**Push and merge are separate authorities.** A green gate authorises a push, not a merge. Changes
arrive as pull requests, and diffs touching authentication, authorisation, tenant isolation, payment
logic, signature validation or migrations get reviewed by someone who was not involved in writing
them.

**Nobody rewrites work they did not author.** Uncommitted work belonging to someone else is left
alone, and a superseded branch waits for its owner rather than being tidied away.

**Failure handling has a defined stopping point.** After two consecutive failed corrections in the
same area, stop editing: reproduce the failure, re-check the assumptions and the whole call chain,
write a test that fails for the intended reason, and only then fix the root cause. If that fix also
fails, do not try a third patch — leave the failing test and the working tree in place, write down
both attempts, the hypothesis and why it did not hold, and escalate it as a decision. Brute-forcing
toward green produces a codebase where nobody knows which fix was the real one.

**Development runs against local environments and CI only.** No connections to production databases,
hosts or secrets, and no ad-hoc queries against production regardless of urgency. Real customer data
is never used for debugging; a production-reported defect is reproduced with synthetic data shaped
like the report. Steps that genuinely need production access are prepared and handed over rather than
executed.

**The development environment is engineered, not endured.** A preflight script runs before build and
start, checks the required files and directories, and actually exercises the native dependencies
rather than trusting that they load. Known platform failure modes get checked-in scripts instead of
tribal knowledge. Heavy jobs do not overlap, and available headroom is checked before starting one.

---

## 12. What this method does not give you

**Ratchets stop regression; they do not repay debt.** No gate will ever tell you the debt is too
large — only that it grew. Reduction has to be scheduled deliberately, and if it is not scheduled it
does not happen.

**A gate proves a property, not the absence of problems.** Every check here has a stated scope, and
several state their own blind spots in their own files. A green run means the things being measured
did not get worse.

**Declared governance is not applied governance.** A manifest describing required checks and reviews
can be validated for internal consistency without any of it being enforced by the hosting platform.
The two are worth keeping separate in your head.

**Process cannot substitute for a second pair of eyes.** Independent review of a sensitive change is
a commitment, not a mechanism, unless something actually enforces it. On a small team that gap is
real and worth naming rather than papering over.

**Some of it is only justified at this scale.** Computing operational visibility at query time
instead of running a metrics stack is a reasonable trade for a single instance per customer and a bad
one at fifty. Every architectural choice here has a size where it stops being right; the useful part
is knowing which numeric trigger tells you that you have arrived there.
