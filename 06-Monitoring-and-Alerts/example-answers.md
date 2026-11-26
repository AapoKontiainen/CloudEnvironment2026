# Assignment 6 — Example answers (theory)

**Do not submit these.** They are training for the exam, and they are useful knowledge in the software industry. Answer the questions in [questions.md](questions.md) **in your own words first**, then open this file and compare.

A few sentences is enough. You will be asked which pillar detected the stopped database vs. which one explained it, and why the resolved email matters.

---

### Question 1: Three pillars + the incident

**See:** Section A tables and section G.

**Logs** = what happened (`Registration … created`). **Metrics** = how much / how fast (`Http5xx` count). **Traces** = the chain (HTTP request → PostgreSQL dependency). The **metric / availability** side *detected* the outage (5xx > 0, `/health` down). **Logs + traces** (Failures, the exception, the dependency) *explained* it.

### Question 2: Workspace vs. App Insights

**See:** Section A (Azure pieces), Step 2 (why workspace-based) and [wiki — Azure Monitor family](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/Azure/Monitoring-and-Application-Insights.md#azure-monitor--kokonaisuus) ([🇬🇧](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/eng/Azure/Monitoring-and-Application-Insights.md#the-azure-monitor-family)).

**App Insights** is the app-level collector (SDK + some Portal views). **Log Analytics** is the store KQL queries. Workspace-based App Insights writes into that one workspace. One store matters because an investigation joins **requests, dependencies, traces, exceptions** without hopping silos.

### Question 3: Platform metrics vs. SDK

**See:** Section A and the opening of section C.

**Platform metrics** are Azure's free numbers on the resource (App Service `Http5xx`, CPU). They see the **outside**. They do **not** see PostgreSQL queries or your log lines. The **SDK** sees the **inside** (requests, dependencies, exceptions, `ILogger`). It misses what the platform sees when the process is down — no SDK, no in-app telemetry.

### Question 4: Templates vs. interpolation

**See:** Step 6 table, Step 10 query 2 and [wiki — structured logging](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/Azure/Monitoring-and-Application-Insights.md#rakenteinen-loki-structured-logging) ([🇬🇧](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/eng/Azure/Monitoring-and-Application-Insights.md#structured-logging)).

Both print the same sentence. The template stores `{RegistrationId}` as a **field** (`customDimensions`). `$"…"` is dead text — you can only `contains` search. You saw the field in **Logs** (`customDimensions.EventId` / `RegistrationId`).

### Question 5: Email in logs vs. in the database

**See:** Step 6 (no PII) and [wiki — PII section](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/Azure/Monitoring-and-Application-Insights.md#pii-ja-salaisuudet-eivät-kuulu-lokiin) ([🇬🇧](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/eng/Azure/Monitoring-and-Application-Insights.md#pii-and-secrets-do-not-belong-in-logs)).

Telemetry is **copied** (workspace, exports, developer screens) and **kept** for retention. Access is wider than the app database. GDPR erasure does not practically reach logs. The database is one controlled store; logs are not built for "delete this person".

### Question 6: "Request received"

**See:** Step 6 last paragraph and the cost note / wiki ingestion table.

The `requests` table already has every HTTP call. Extra "request received" lines **pay ingestion**, bury the business events, and add no new field. Harmful: noise + cost, not a helpful duplicate.

### Question 7: Rules vs. Action Groups

**See:** Step 12 and [wiki — alerts and Action Groups](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/Azure/Monitoring-and-Application-Insights.md#hälytykset-ja-action-groupit) ([🇬🇧](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/eng/Azure/Monitoring-and-Application-Insights.md#alerts-and-action-groups)).

**What to watch** and **whom to tell** change on different schedules. When the on-call person rotates, you edit **one** Action Group; every 5xx / availability / budget rule keeps working. If email were hard-wired into each rule, a team of six rules would mean six edits and missed pages.

### Question 8: Alert fatigue

**See:** Step 13 reminder and [wiki — alert fatigue](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/Azure/Monitoring-and-Application-Insights.md#hälytysväsymys-alert-fatigue-ja-resolved-ilmoitus) ([🇬🇧](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/eng/Azure/Monitoring-and-Application-Insights.md#alert-fatigue-and-the-resolved-notification)).

Fatigue = so many pages that people **mute or ignore** them. Threshold 0 fires on a single 5xx among thousands — normal in production. To pick a real threshold you need **baseline traffic**: typical 5xx rate, peak hours, and what "actually wake someone" means.

### Question 9: Why the email was slow

**See:** Step 17 and [wiki — window and evaluation frequency](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/Azure/Monitoring-and-Application-Insights.md#metric-alert-vs-log-alert) ([🇬🇧](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/eng/Azure/Monitoring-and-Application-Insights.md#metric-alert-vs-log-alert)).

The metric looks at a **5-minute window**, every **1 minute**; availability probes every **5 minutes** per location; then email delivery. A 10-second window would page on a **blip** (one bad request, one cold start) and flap fire/resolve. Detection delay is the price of not crying wolf.

### Question 10: Smoke test vs. availability test

**See:** Step 14 and Assignment 5 (smoke test on deploy).

**Smoke test:** "Is *this deploy* healthy?" — runs when the pipeline deploys. **Availability test:** "Is the *service* up *now*?" — runs every 5 minutes from outside. A fault **between** deployments (you stopped PostgreSQL at 2 AM, no push) is invisible to the pipeline and visible to availability.

### Question 11: Diagnosis loop

**See:** Steps 17–19.

1. Alert email (Fired). 2. Failures view — which operations. 3. Open exception text. 4. **AI hypothesis** (this is the AI step). 5. Verify with `az postgres flexible-server show`. 6. Start the server (fix). 7. Resolved email. Verify even when AI sounds right: Assignment 3's fork (timeout vs. `28P01`) — a fluent wrong cause wastes the night.

### Question 12: Resolved email

**See:** Steps 13 and 19 and [wiki — the resolved notification](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/Azure/Monitoring-and-Application-Insights.md#hälytysväsymys-alert-fatigue-ja-resolved-ilmoitus) ([🇬🇧](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/eng/Azure/Monitoring-and-Application-Insights.md#alert-fatigue-and-the-resolved-notification)).

It closes the incident: **duration** is first-Fired to Resolved, the next on-call person sees it is over, and you know the **fix worked** (not "I started the server and hoped"). Without it you keep watching Failures by hand.

### Question 13: Sampling

**See:** the sampling reminder after Step 10 and [wiki — sampling note under Costs](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/Azure/Monitoring-and-Application-Insights.md#kustannukset) ([🇬🇧](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/eng/Azure/Monitoring-and-Application-Insights.md#costs)).

Sampling **drops a fraction of telemetry** so volume (and cost) stay bounded — SDK version 3 caps traces per second and tags what it kept with `microsoft.sample_rate`. Counts and rates stay usable ("about this many 5xx"; `sum(itemCount)` estimates the real number). A missing individual request is **not proof** it never happened — so "did user X succeed?" is the wrong question for sampled Logs.

### Question 14: `MissingSubscriptionRegistration`

**See:** Step 4 (register the resource providers) and Assignment 5 section F (managed identity with Contributor on the resource group).

In Assignment 4 **you** deployed, as subscription **Owner**: ARM registered each new provider on the fly. The pipeline deploys as a **managed identity with Contributor on one resource group** — registering a provider is a *subscription*-level write, outside that scope, so ARM refused. The fix is a one-time registration by a human, not a bigger role: Owner on the subscription would let a compromised pipeline token create resources anywhere, assign roles and run up cost — the exact blast radius least privilege exists to limit.
