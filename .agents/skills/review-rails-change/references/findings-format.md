# Findings Format

List findings from highest to lowest severity. Each finding contains:

```text
[Severity] Short title
Location: path:line (when applicable)
Criterion/risk: violated criterion or concrete failure mode
Evidence: reasoning, command output summary, or reproduction path
Remediation: smallest reasonable correction
```

Severity meanings:

- **Critical:** plausible security/privacy breach, unrecoverable data loss/corruption, destructive migration failure, or production-wide outage.
- **Major:** acceptance criterion failure, authorization gap, incorrect state/data behavior, material regression, unsafe deployment behavior, or missing coverage that prevents confidence in such behavior.
- **Minor:** localized maintainability, clarity, performance, accessibility, or style issue without a current material correctness failure.
- **Question:** missing information whose answer may or may not reveal a defect.

Do not inflate severity for personal preferences. Repository conventions outrank external style preferences unless correctness or security is affected.

After findings, include:

- checks independently run and their results;
- assumptions/questions;
- concise verdict: `APPROVE`, `CHANGES REQUIRED`, or `BLOCKED`.

