# Serhat Atılgan | Backend engineering

[Türkçe](README.tr.md) · [GitHub](https://github.com/hilberspace-dev)

I build backend systems in Go, PostgreSQL and TypeScript. Most of my work is
payment reconciliation and API integration, and I also take over the maintenance
of existing applications. I live in Türkiye and work in Turkish and English.

## Projects

### ReconPilot

A Go/PostgreSQL application that imports PSP reports, bank statements and
marketplace settlements. It applies exact, tolerant and group matching, then
classifies the remaining records. Runtime checks reject results that leave an
input unaccounted for or assign a transaction to multiple match groups.

The public repository includes the CLI, HTTP service, HTML report, tests and a
seeded synthetic benchmark. The benchmark compares matches with the groups the
generator intended. It has never run on customer data, so it says nothing about
accuracy there.

[Source and run instructions](https://github.com/hilberspace-dev/reconpilot) ·
[Case study](projects/03-reconpilot-payment-reconciliation/)

### AURA

My private research prototype combines browser-based facial measurement and
surgical preview with clinic workflows. I lead technical design and review across
the web application, API and research code. It has no users or revenue yet.
Nobody independent has validated it on living faces yet. The preview shows a
proposed plan; it does not predict the result of surgery.

[Project scope and current limits](projects/04-aura-photoreal-3d-clinic-platform/)

## Security reviews

- [ERC-4337 EntryPoint](projects/02-erc4337-entrypoint-review/): an internally
  assessed Low-severity correctness finding, with recorded local and client-based
  reproductions. It has not been submitted to a bounty programme or independently
  validated. The full mechanism and proofs remain private.
- [Smart-contract investigation](projects/01-smart-contract-security-audit/):
  a hypothesis tested against a pinned local fork and rejected because the operator
  could recover from the observed condition. No finding was submitted. The public
  excerpt shows how the test is built, but you cannot run it as a reproduction.

## Working together

I take fixed-scope engagements. The initial call and assessment are free.
When a problem needs investigating first, a paid discovery phase ends with a
diagnosis and a proposed scope before any implementation starts. The scope
includes deliverables, acceptance criteria and a timeline. Payment follows
delivery milestones; I do not invoice the first milestone if it fails the agreed
criteria.

Handover includes source, tests, operating instructions and any agreed session
with the receiving team. Client work is subject to confidentiality; client source
and data are excluded from this portfolio.

[Delivery process](DELIVERY-METHODOLOGY.md) ·
[Security review method](METHODOLOGY.md)

## Contact

[hilberspace@gmail.com](mailto:hilberspace@gmail.com) ·
[WhatsApp](https://wa.me/905431064025) · [+90 543 106 40 25](tel:+905431064025)

Please include the problem, current stack, expected deliverable, timeline and
access constraints. Use anonymised samples for an initial data review.
