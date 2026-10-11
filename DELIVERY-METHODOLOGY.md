[![Türkçe sürüm](https://img.shields.io/badge/Language-T%C3%BCrk%C3%A7e-E30A17?style=for-the-badge)](DELIVERY-METHODOLOGY.tr.md)

# Delivery and quality-gate methodology

This is how I take a production system from a change request to a shipped release without relying on
anyone remembering to be careful. Nothing in it is tied to one stack. It came out of a multi-tenant
platform with a GPU/ML workload, built under data-protection constraints.

Its counterpart is the [security review and proof-of-concept methodology](METHODOLOGY.md), which
covers adversarial review, proving defects and packaging them for triagers. The
[portfolio README](README.md) gives the short version of how an engagement runs; this document is the
long version of what happens inside one.

The principle behind all of it is that a rule which depends on someone remembering it will sooner or
later be forgotten. So every lesson that cost real time to learn ends up as something a machine
checks; otherwise the same mistake comes back.

## 0. Ground rules

1. Evidence comes before assertions. Nothing is called fixed, passing or complete without the command
   that was run, its output and its exit code. Reading the code is not verification, and a green
   re-run does not cancel an earlier failure. Anything that was not run is said out loud.
2. Fix the class of bug as well as the instance. The commit that fixes the bug is half the work. The
   other half is working out which check should have caught it and didn't, and then building that
   check.
3. Debt is frozen and never allowed to grow. Existing problems are measured and pinned at their
   current size, and new ones fail the build. Nobody edits a baseline to make a gate go green.
4. Fail closed, and name the blind spot. On any path that carries money, safety or personal data,
   ambiguity means refusal. Every measurement tool says in its own file what it cannot see.
5. Make the smallest change that fixes the root cause. Unrelated cleanup, reformatting, speculative
   abstraction and unrequested API breaks stay out of the diff.

## 1. Definition of done for a change

Before any code is written, the observable goal, the acceptance criteria, the scope and the
invariants that must survive are pinned down. Then comes reading: the existing implementation, its
tests and the full call chain, meaning the whole chain the changed function sits in. Every file,
route, command and setting the plan relies on is checked to exist before the work starts.

Then implement the smallest coherent change, run targeted checks while working, and run the
regression suite that the change actually calls for. A targeted test plus a screenshot does not
count as a regression pass.

Finish by reading the whole diff for scope, security and side effects, and by recording what was run
and what it returned. Skipped work is recorded as skipped, with the reason.

Behaviour-preserving refactors are planned before they are executed. Each split of an oversized
module is written down as its own small change, with rules attached: move only code that already
exists inside the unit being split, keep the extracted piece thin and its dependencies injected,
never rename a route or change a response shape in the same change as a move, and leave existing
tests passing without edits beyond imports.

## 2. The gate ladder

There are four check sets. Each one is a chain that stops at the first failure, so it is always clear
which command failed.

| Tier | Covers | Trigger |
| --- | --- | --- |
| Fast gate | Secret scan, type build, lint, the policy scanners. No suites. | Pre-push hook |
| CI | The same policy set, then lint, server tests, frontend tests, build, end-to-end and smokes, collapsed into one required check | Configured to run on every pull request |
| Full local run | The policy set plus the full suites, build and the operational smokes | On demand |
| Release and drift | Everything above plus dependency and lockfile policy, audit, governance, deploy readiness, release build and artifact verification | Every release; a weekly schedule is also configured |

The local hook is the gate that does the work. It installs itself through the package lifecycle and
does nothing outside a checkout, so a fresh clone is covered without anyone setting it up. The remote
policy job runs the same scanner set; skipping the local one only delays the failure.

The escape hatch cannot switch off the floor. There is exactly one documented bypass. It
skips the fast gate but never the secret scanning, it announces itself, and using it to save time is
explicitly against the rules. Exceptions inside individual scanners follow the same idea: each one is
line-level, carries a written reason and shows up in the diff for review. None of them mutes a rule
silently.

Every CI step writes its output to a log and exits with the child process's own status, so no wrapper
can turn a failure into a passing step. Each job builds a sanitised diagnostic snapshot and uploads it
only when something fails. Environment dumps, secrets files, runtime databases and uploads are left
out of it.

## 3. Ratchets: how legacy debt is held

Existing debt is measured and pinned, and any growth fails the build. Releases go on, and the debt
cannot grow while they do.

A *numeric ratchet* is a single integer that may only go down. Examples are raw colour literals
outside the design tokens, permissive schema entries in the API contract, and endpoints guarded below
their intended tier. The tool that writes the baseline refuses to record a larger number, so the count
cannot creep up by accident.

An *inventory ratchet* is a sorted list of known offenders. A new entry fails the build, and so does a
*stale* one: if a listed problem has been fixed, its line has to be removed in the same change.
Otherwise repaid debt stays in the list as cover for future debt.

Wherever a machine can demand a justification, it does. A newly baselined exception is written with
an `UNJUSTIFIED` placeholder, and the gate keeps failing until it is replaced with a real reason.

The detectors test themselves. Each pattern rule ships with one matching and one non-matching sample,
and the run fails if a rule stops catching its own bad sample or starts catching the good one. A rule
that has decayed into a no-op is worse than no rule, because it still looks like coverage.

Baselines live in their own files, separate from the scripts that read them. An inventory hardcoded
in a checker drifts without anyone noticing. In a checked-in file, every exception shows up in a diff
and has to be approved.

## 4. Tests judged by what they catch

Coverage measures which lines ran. It says nothing about whether the suite would have failed. It stays
as a floor against collapse, and the assurance itself comes from the practices below.

### Harness fidelity

Anything that depends on global middleware (authentication, tenant resolution, CSRF, body parsing,
rate limiting) is tested through the real application composition. A handler mounted on a bare
framework instance does not count. Existing shortcuts are frozen in a baseline, and new ones fail.

### Regression tests that fail first, for the intended reason

A non-trivial test opens by naming the defect class, the symptom, and why the previous layer missed
it. The strongest form proves the point. The test inlines the pre-fix implementation and asserts that
it violates the law under test, so running the file shows the old code failing.

### Property tests with an independent oracle

Independent means the reference implementation shares no arithmetic with the code under test, so it
cannot inherit the defect it exists to catch. On money paths that means computing the expected value
a structurally different way. Example-based tests pin the known tricky points; the property test
states the law those points are instances of.

### Mutation testing where it pays

Each money-handling module gets one narrow configuration that mutates a single file and runs only that
module's tests. Thresholds come from measured runs, with the provably equivalent mutants accounted for
in a comment, so the break value means that any *new* surviving mutant fails the run. Thresholds go up
as coverage improves and never come down to make a run pass.

### Test hygiene

- Determinism is built in. There are no arbitrary sleeps; asynchronous assertions wait on a
  condition. Time-dependent logic takes the clock as a parameter, so it needs no mock, and that also
  makes it cheap to mutate. Assertions use explicit UTC timestamps.
- A probe that measured nothing counts as a failure. If an isolation test made zero cross-boundary
  attempts, or its control probe never succeeded against its own side, the run fails as a vacuous
  measurement and does not report a clean result. This is the delivery-side twin of the negative
  control in the [security methodology](METHODOLOGY.md#7-proof-of-concept-rules).
- Flaky tests get investigated, never retried. That goes double for accessibility failures, which are
  real defects with a legal dimension. Where a suite is flaky by nature, the source of the flakiness
  is removed (animation disabled, fonts awaited). Wrapping it in a retry would hide a real
  regression.

### Under load

A non-functional tier, scheduled weekly in the CI configuration, checks whether the system stays
healthy under pressure. It has a load smoke, a long soak and a stress suite. The stress suite allows
some errors and asserts the *shape* of failure. A contended booking slot must produce exactly one
winner. Hostile input must be rejected without taking the process down. Tenants racing at the same
moment must not read each other's data. Backpressure counts as the shield working; any other kind of
failure does not. Load thresholds are calibrated from a measured plateau, never picked because they
sound comfortable.

## 5. API contract and module boundaries

The API specification is the contract. It states cross-cutting behaviour once, in one place, and a
new route cannot be pushed before it appears there.

Coverage is measured in both directions, and twice. A text scan of the source only sees literal paths
passed directly to a route method. It misses routers mounted under a prefix, registrations that take
the path as a variable, and loops over a path array. So a second measurement boots the application,
walks the live routing table and compares by path shape. A sanity assertion on the number of routes
found keeps a broken walker from passing silently. The two numbers are expected to differ, and the
runtime count is the correct one.

Other checks cover what coverage cannot see. One looks for unresolved references, which look fine in
review but make the document invalid for every strict consumer. Another looks for keywords from an
older dialect; a current validator ignores them without complaint, so their meaning is lost silently.
A third looks for operations with no declared security, which every integrator and code generator
will read as public.

Module boundaries are enforced by checks. Server code never imports browser code. The module graph
has no cycles; cycle detection runs over a parsed import graph and leaves out type-only edges, because
those disappear at runtime. Both allowlists are at zero, so they have stopped being ratchets and work
as invariants. All browser traffic to the API goes through one client that owns credentials, headers,
timeouts and the circuit breaker, and anything that bypasses it needs a written reason in a baseline.

Type checking runs in build mode across a project graph. The projects have different library and
target settings, and one flat pass would check server code against browser globals.

## 6. Migrations and recovery

Migrations are files, applied in order and recorded with a content hash. A committed migration is
never edited, and review does not have to catch it: the next boot recomputes the hash, refuses to
start and says what to do instead.

Only the leader runs migrations, under a cross-process lock, and each file is applied atomically. The
lock is taken before the first schema write, so several processes starting at once cannot race to
create the same tables on a fresh database. Crash recovery reclaims a lock only from a process that is
provably gone. It falls back to a staleness check on file age only when it cannot tell whether the
holder is alive. The reason is that a synchronous migration blocks the event loop: a long index build
cannot refresh its own timestamp while it is very much alive, and a rule based on age alone would let
a booting peer steal the lock out from under it. The tests for this spawn real processes that contend
for the same file, with no mocks.

There are no down migrations. Rollback is a restore from a snapshot. That fits a deployment with one
stack per customer, and it is recorded as a decision so that nobody first learns about it during an
incident.

Operational procedures are scripts, so nobody has to remember them: scheduled backups with retention
and pruning, size monitoring with warning and critical tiers, a restore command that validates against
path traversal, and a cleanup command that is a dry run by default. Recovery targets and the ordering
the storage model demands are in a runbook, next to the numbers that trigger the next architectural
decision.

## 7. Security posture

Each defensive primitive lives in its own module, which opens with a comment naming the attack or
incident it closes. That way it can be reviewed on its own, and the reasoning stays with the code
through refactors.

Callbacks that move money are treated as hostile input. The signature is verified first. Then the
returned token is bound to the one stored on the intent with a constant-time comparison, the
authoritative record is fetched from the provider, and the collected amount is checked against the
expected one. Only after that does state change. Amounts are parsed from the digit string, because
multiplying in floating point rounds inconsistently and can read a correct settlement as short. State
transitions repeat their guard inside the SQL predicate, so a concurrent callback cannot win a
read-then-write race. Terminal states are terminal, and idempotency is a database constraint.

Some controls have two halves that must agree, for example a path exempted from body parsing and the
same path exempted from CSRF. A structural test asserts both halves and fails on a stale entry as well
as a missing one, so the next addition cannot ship with only one side wired.

Permission tiers are settled by measurement. When the question "how many endpoints are under-guarded"
got two different answers on two different days, the response was a script that produces the same
census the same way every time. It freezes both the number and the list, so swapping one entry for
another cannot hide a new one. A behavioural test backs it up, because a text scan goes stale wherever
dependency injection hides the guard.

Secrets are scanned at two depths, the working tree and the committed history, so a credential that
was committed and later removed still blocks the push. Supply-chain policy is written as code: a
pinned lockfile format, registry-only resolution, an allowlist of packages permitted to run install
scripts, third-party CI actions pinned to a full commit hash, explicit permissions on every workflow,
and no interpolation of untrusted input into shell commands.

Every finding is triaged; none is simply accepted or dropped. A later review checks each earlier
finding against the code again. A disproved finding stays on record as a correction with the
counter-evidence, and an area that was not reviewed in the time available is recorded as not reviewed,
never as clean.

## 8. Release and deployment

The release artifact is built from an explicit allowlist (not an ignore list), staged, and then walked
a second time to re-assert the same exclusions. It ships with a checksum and a manifest that records
what went in and which rules were applied.

Verification rebuilds and re-tests the *extracted* copy; the working tree plays no part. The verifier
checks the hash, extracts with a reader that rejects absolute paths and traversal, and then runs
install, the policy scanners, lint, build and the test suites with the working directory set inside
the extracted copy. A blocked subprocess is reported as an environment blocker and is fatal in CI, so
the check cannot silently shrink into a file listing.

Deployment promotes an artifact that has already been published; it never builds one. The remote
script verifies the checksum, extracts into a per-release directory (refusing to overwrite an existing
one), snapshots the data first, installs on the host, records the outgoing release, flips the live
pointer, restarts, polls the health endpoints and rolls back automatically on failure. Readiness is a
real dependency probe that runs an actual query and actual filesystem checks. An endpoint that always
returns healthy keeps a broken instance in rotation.

The release documentation says plainly that a green test run is not production sign-off, and lists
what sign-off needs: a live payment and refund against a real provider, freshly generated secrets, and
an off-host backup with a *proven* restore. A configured restore is not enough.

## 9. Shipping dark, with compliance as a precondition

Significant features ship disabled. A single curated catalogue is the only place that lists them for
operators. For each flag it has to mirror the semantics of the code that consumes it, and each entry
cites that code; a looser re-implementation of the same check is not allowed.

The status vocabulary has three values. *On* tells the truth about what is actually running, even
when a precondition has since regressed. *Off* means dark and ready. *Blocked* means dark with an
unmet precondition.

Some preconditions are facts a machine can check, such as a key being present or a provider being
configured. Others are human: a privacy notice approved and published, or an experiment
pre-registered. These are attested through the same flag mechanism so that the check stays
machine-readable. That puts a legal or methodological obligation *on the activation path* itself, and
the feature stays blocked until it is met.

Rollout percentages bucket on a stable hash of the flag and the entity, so a partial rollout holds the
same entities on every evaluation and does not reshuffle per request. Every evaluation returns a
machine-readable reason that names the rule that decided it.

Outbound integrations go through a durable outbox and a worker, so a user-facing request never waits
on a third party. Idempotency is a unique index over the logical event. Retries back off with a cap,
and a job that runs out of retries moves to an explicit dead state that operators can see, so nothing
disappears. Integrations that carry a regulatory obligation fail closed and cite their primary source
in the module header. Approval approves; rejection *or the absence of any record* blocks, because no
record means the action is not lawful. Their cache keeps a definitive answer for a long time and an
error for a short time, so an outage leaves them blocked and quick to recover, never permissive.

## 10. Documentation as evidence

In any document someone might act on, each claim is marked either verified, with the command that
produced it, or open. There is no third state, and anything unmarked counts as unverified.

Anything with measurements in it records the commit and the date of the measurement and says that the
numbers decay. Once a reader finds one stale number, they start to doubt everything else in the
document.

Decision records have a fixed shape. The header has the date, the status and a link back to the
finding that prompted the decision. The context is an observation-and-evidence table in which every
observation cites a concrete file or setting. The decision itself is one sentence. The work is then
split in two: what to do now, with each item mapped to the check that will hold it, and what to do
when a named numeric trigger fires. The record closes by naming the one input that cannot be derived
from the code and asking for a decision on it.

Audit findings get stable identifiers that follow them around. The same identifier appears in the
decision record, in the check that enforces the fix and in the follow-up work. An audit also records
which checks were actually executed and says plainly what it did not cover.

Anything that makes a causal claim is pre-registered before any data exists: the primary metric and
hypothesis, the exclusions, the stopping rule, and which secondary metrics are barred from headline
claims. The design includes a table that binds each pre-registered rule to the test that enforces it.
Simulation work runs two arms side by side. The null arm's gate is that it must never produce a usable
result. The known-truth arm is checked against a tolerance derived analytically, and nobody tunes that
tolerance until the run passes.

## 11. Working discipline

A green gate is enough to push a branch; merging needs more. Changes arrive as pull requests, and
diffs that touch authentication, authorisation, tenant isolation, payment logic, signature validation
or migrations get a second review before merge.

Failure handling has a defined stopping point. After two consecutive failed corrections in the same
area, stop editing. Reproduce the failure, re-check the assumptions and the whole call chain, write a
test that fails for the intended reason, and only then fix the root cause. If that fix fails too,
there is no third patch. Leave the failing test and the working tree as they are, write down both
attempts, the hypothesis and why it did not hold, and raise the next step as a decision. Brute-forcing toward
green leaves a codebase where nobody knows which fix was the real one.

Development runs against local environments and CI only. There are no connections to production
databases, hosts or secrets, and no ad-hoc queries against production, however urgent. Real customer
data is never used for debugging; a defect reported from production is reproduced with synthetic data
shaped like the report. A step that needs production access is never run from the development
environment.

The development environment is engineered as well. A preflight script runs before build and start,
checks the required files and directories, and actually exercises the native dependencies to prove
they load. Known platform failure modes are handled by checked-in scripts, so the fix does not live
only in someone's memory.

## 12. What this method does not give you

Ratchets stop regression, and paying the debt down is separate work. A gate reports that the debt
grew; it cannot tell you the debt is too large. Reduction happens only when someone schedules it.

A gate proves one property. It cannot prove that there are no problems. Every check here has a stated
scope, and several describe their own blind spots in their own files. A green run means the things
being measured did not get worse.

A manifest that describes required checks and reviews can pass validation for internal consistency
while the hosting platform enforces none of it. What a manifest declares and what the platform
enforces have to be checked separately.

A rule that sensitive changes get a second review is only a commitment until something enforces
it.

Some of it is only justified at this scale. Computing operational visibility at query time, with no
metrics stack, is a reasonable trade for a single instance per customer and a bad one at fifty. Every
architectural choice here has a size at which it stops being right. What helps is knowing which
numeric trigger tells you that you have reached it.
