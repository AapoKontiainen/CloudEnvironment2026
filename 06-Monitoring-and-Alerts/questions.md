# Assignment 6 — What to return and theory

## What to return

**All returns go to the Learn platform.** Submit only the screenshots and written notes below. Do not upload code or Bicep files.

Theory questions further down this file are **not submitted**. They are training for the exam, and they are useful knowledge in the software industry. Write your own answers first — you will be asked which observability pillar detected the stopped database vs. which one explained it, and why the resolved email matters. Example answers are in [example-answers.md](example-answers.md) — use them to check yourself, not as a copy-paste.

**Through the pipeline (sections B–C)**

- [ ] Screenshot: the merged monitoring PR — gates green, the what-if check showing the two new resources, AI review reacted to (Step 4)

**Telemetry (sections D–E)**

- [ ] Screenshot: one end-to-end transaction in Transaction search — your `POST …/registrations` request, the `postgresql` dependency under it, and your `Registration … created` trace (Step 9)
- [ ] Screenshots: your three hand-written KQL queries **with** their results (Step 10)
- [ ] In your answers document: the AI-generated KQL + your verification notes — which column names you checked and against what (Step 11)

**The incident (sections F–H)**

- [ ] Screenshot: both **Fired** e-mails (`alert-cloud26-http5xx` and `avail-health`) and both **Resolved** e-mails, timestamps visible (Steps 17, 19)
- [ ] In your answers document: root-cause write-up (Step 18) — timeline from the first e-mail to the confirmed cause, the exception you pasted, the AI's hypothesis, and the CLI command that confirmed it
- [ ] Screenshot: dashboard with the incident visible in the charts (Step 20)

**Exercises**

- [ ] Exercise 1: screenshot of the pipeline's what-if log for the alerts PR (`2 to create`) and of the next run's what-if (no change) — idempotence proven
- [ ] Exercise 1: your one-sentence answer on the availability test, in your answers document
- [ ] Exercise 2: in your answers document — log hygiene findings: fixes, justifications, AI false positives, and your decision on EF Core's SQL logging

Written work that is not a screenshot (KQL verification, root-cause write-up, exercise answers) goes in your Learn answers document.

---

# Theory questions

**Do not submit these answers.** They train you for the exam, and they are good knowledge to have in the software industry. Try each question yourself, then compare with [example-answers.md](example-answers.md).

Answer in your own words. Short answers are fine (2–5 sentences), but they must show you understand the *why*, not just the *what*. Everything you need is in this assignment's README (and the wiki / Learn links under Additional material).

## Observability concepts

1. Define logs, metrics, and traces, and give a Campus Events example of each. For the section G incident (stopped database), state which pillar *detected* it and which pillar *explained* it.

2. Explain the roles of Log Analytics Workspace and Application Insights, and how they relate to each other in the workspace-based model. Why does "one store for all telemetry" matter for investigations?

3. The App Service `Http5xx` metric existed before you installed any SDK, but the PostgreSQL dependency telemetry did not. Explain the difference between platform metrics and SDK telemetry — what does each see, and what does each miss?

## Logging practices

4. Explain the difference between `logger.LogInformation("Created {RegistrationId}", id)` and `logger.LogInformation($"Created {id}")` — both print the same text. What exactly do you lose with the second form, and in which tool did you see the difference?

5. Why is logging a user's email address worse than storing it in the database, even though both live in Azure? Name at least two concrete reasons (think: access, lifetime, GDPR).

6. The assignment told you *not* to log "request received" lines. Why is that log line harmful rather than merely redundant? (Think: ingestion cost, signal-to-noise, and what already exists.)

## Alerts

7. Alert rules and Action Groups are configured separately. What operational problem does this separation solve? Describe a scenario in a team where the separation pays off.

8. Your 5xx alert uses threshold 0, window 5 min, evaluation 1 min. Explain what **alert fatigue** is, why threshold 0 would cause it in production, and what information you would need to pick a real threshold.

9. In the fault drill, roughly 5–15 minutes passed between breaking the app and the first email. Walk through where that time goes, and explain why "shorter is always better" is *not* true for alert windows (what does a very short window do to flapping/noise?).

10. The availability test targets `/health`, which checks the database — the same endpoint your pipeline's smoke test uses. These two checks run at different *times* for different *reasons*. State the distinct question each one answers, and give a fault that only the availability test would catch.

## Incident response

11. Reconstruct the diagnosis loop from section G as a numbered list (alert → ... → fix), and mark the step where AI participated. Why was it important to verify the AI's hypothesis with `az postgres flexible-server show` even though its explanation sounded convincing?

12. The alert also emailed you when it **resolved**. Why is the resolved notification operationally valuable, not just polite? (Think: on-call handoffs, incident duration records, and knowing whether your fix worked.)

## Cost and design

13. Application Insights samples telemetry at high volumes by default (SDK version 3 rate-limits traces per second). Explain what sampling does, why it is acceptable for metrics-style questions ("how many 5xx?") but dangerous for audit-style questions ("did user X's request succeed?").

## Permissions

14. Your own `az deployment group create` runs in Assignment 4 never complained about resource providers, but the pipeline's first monitoring deploy failed with `MissingSubscriptionRegistration`. Explain the difference in *who* was deploying and *what scope* their permissions covered — and why giving the pipeline identity Owner on the subscription would be the wrong fix.
