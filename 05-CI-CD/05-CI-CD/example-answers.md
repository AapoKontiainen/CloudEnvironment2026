# Assignment 5 — Example answers (theory)

**Do not submit these.** They are training for the exam, and they are useful knowledge in the software industry. Answer the questions in [questions.md](questions.md) **in your own words first**, then open this file and compare.

A few sentences is enough. You will be asked to explain OIDC vs. a stored password, and why the smoke test failed with a stopped database.

---

### Question 1: CI vs. Delivery vs. Deployment

**See:** Guided section A and [CI/CD wiki — CI and CD](https://github.com/xamk-mire/Xamk-wiki/blob/main/Development-guidelines/CI-CD.md).

**CI** is "every change is built and tested automatically" — merge is still a human decision, deploy may not exist. **Continuous Delivery** is "every change is *deployable*"; a human presses the last button. **Continuous Deployment** is "green gates *are* the decision" — merge deploys. The guided section built **Deployment**. Exercise 2 added a GitHub Environment reviewer, which temporarily made it **Delivery**.

### Question 2: Fresh `ubuntu-latest`

**See:** Step 8 table (`runs-on`) and the wiki CI table ("works on my machine").

The runner has none of your leftover SDKs, global tools, or `appsettings` accidents. It catches **environment-dependent bugs**: a package you installed only on your laptop, a path that works on Windows, or a test that needs a local PostgreSQL you forgot the pipeline does not have.

### Question 3: No bypass, even for you

**See:** Step 10 ("Do not allow bypassing") and section A (rung 2: humans skip steps under deadline).

Deadline pressure is when *you* would push straight to main. The setting protects the **habit and the history**, not only the files: every change has a PR, checks, and a review trail. A one-person repo still becomes a team repo later — the wall is already there.

### Question 4: Whitespace as a gate

**See:** Step 8 (`dotnet format --verify-no-changes`).

**For:** style debates end in CI; diffs stay about behaviour. **Against:** a one-space fail can block a real fix and train people to hate the pipeline. **Verdict (course):** keep it — `dotnet format` locally is cheap, and a noisy gate you skip is worse than a strict one you run before push.

### Question 5: What InMemory cannot catch

**See:** Step 5 reminder (why not real PostgreSQL) and Testcontainers.

A unique index, `ON DELETE` behaviour, or raw SQL that InMemory ignores can **pass in CI and fail on Azure**. To catch that in CI, run tests against a real engine — typically [Testcontainers](https://dotnet.testcontainers.org/) starting a throwaway PostgreSQL on the runner.

### Question 6: `WebApplicationFactory<Program>`

**See:** Assignment 1 (`public partial class Program;`) and Steps 5–6.

The `partial` line makes `Program` a type the test project can name. `WebApplicationFactory<Program>` **boots the real `Program.cs`** (DI, endpoints, seeding) inside the test process. HTTP-level tests guard the **public contract** (status codes, `/api/events`, duplicate email) — the same surface the pipeline and users rely on. Calling `PostgresEventStore` directly would miss a broken route or a wrong status code.

### Question 7: Stored credential vs. OIDC

**See:** Section F and [CI/CD wiki — OIDC](https://github.com/xamk-mire/Xamk-wiki/blob/main/Development-guidelines/CI-CD.md#azure-kirjautuminen-putkessa-oidc).

A publish profile or SP password is **long-lived** and works from anywhere if it leaks. OIDC issues a **short-lived token** that Azure accepts only for the federated `subject`. Risks removed: (1) a leaked secret that never expires; (2) a credential that works from a laptop or another repo, not only from *this* workflow on *this* branch.

Bonus: `id-token: write` lets the job **ask GitHub for the OIDC token**. Without it no token is issued, so `azure/login` fails before it even talks to Azure — the most common OIDC mistake in the troubleshooting table.

### Question 8: Forks and the `subject`

**See:** Step 15 and the wiki `subject` paragraph.

The attacker can run workflows **in the fork** (their Actions, their secrets). They **cannot** deploy to your Azure: the fork's token carries the fork's `subject` (`repo:<attacker>@<id>/<repo>@<other-id>:…`), which does not match the credential, so Azure rejects the exchange. That is why Exercise 1 needs a *second* credential for `…:pull_request` — PR runs are a different subject, still only *your* repo.

Bonus: names can change hands — delete your repo and someone can register the same `owner/repo` name, or you rename yours and the old name is free. A credential keyed on the name alone would then trust the wrong repository. The numeric IDs never change and are never reused, so trust follows *this* repository, not its current name.

### Question 9: Next rung for `PG_PASSWORD`

**See:** Step 16 reminder (secrets ladder).

Today the password sits in **GitHub Secrets** (masked, still readable by repo admins) and is passed into Bicep. The next rung: the pipeline (or the app) fetches it from **Key Vault**, or **Managed Identity** removes the password entirely. Identifiers (`AZURE_CLIENT_ID`) can stay in Secrets by convention — they are not the secret.

### Question 10: Least privilege and the pipeline identity

**See:** Steps 13–14 ("Why scope it down?", "Why not an app registration?") and the MyLeague comparison.

With Contributor on **one resource group**, a hijacked pipeline could change or delete everything in that group — the web app, the database, the storage account — but **nothing outside it**: no other resource groups, no subscription settings, and no new role assignments (Contributor cannot grant rights). Scoping to the subscription would make the blast radius "everything you own". Least privilege is the default, not paranoia.

A **managed identity** is an ordinary Azure resource created with your *subscription* rights, so it works in a school tenant where students cannot create Entra ID objects (`az ad app create` → `Insufficient privileges`), and it disappears with the resource group. An **app registration** lives in the directory and needs directory rights (MyLeague uses one in its own tenant). The workflow side is **identical**: `azure/login` with `client-id`, `tenant-id` and `subscription-id` — only the Azure object behind the `client-id` differs.

### Question 11: `needs` and `concurrency`

**See:** Step 17 table.

**`needs: infra`:** the app zip must not land on a resource group whose Bicep deploy failed or is still running — you would publish onto missing or half-updated infrastructure. **`concurrency`:** two merges a minute apart must **queue**, not overlap — otherwise two what-if/create runs fight over the same group (or the slower one overwrites the newer app).

### Question 12: Green deploy, red smoke test, skipped infra

**See:** Step 21 ("Why skip infra?") and the Step 17 table (smoke test loop).

(a) `azure/webapps-deploy` only reports that the **zip landed** on App Service. The app then restarts, and `Program.cs` touches the database on startup (`EnsureCreated` + seeding). With the server stopped the process never comes up, so `/health` returns App Service's *Application Error* page (503) instead of the app's own JSON. "Deploy succeeded" was true; "the app runs" was false — that gap is what the smoke test exists for.

(b) A Bicep deployment against a **stopped** Flexible Server neither succeeds nor fails: Azure keeps waiting for the server (30+ minutes). With the infra job in the run the demo would **hang** instead of failing, and no e-mail would come. So: the resource can *exist* (the template is satisfied), yet not be *updatable* (Bicep waits), and not be *working* (the app cannot connect). A pipeline must fail **fast and loud** — a quiet wait is the worst outcome.

### Question 13: Retry loop vs. one check

**See:** Step 17 smoke-test loop (cold start).

App Service after deploy is often **not ready on the first request** (cold start, swap, warmup). One check would fail a healthy release. Too many retries (100 × 15 s) **hide a real outage**: the job stays yellow for half an hour, you get no email, and a broken `/health` looks like "still starting". Ten tries is a bounded wait, then fail loud.

### Question 14: What the failure e-mail cannot tell you

**See:** Step 21 (last paragraph) and the Step 21 reminder about the meter.

The e-mail is sent **only when a workflow run fails**. A fault that happens *between* deployments — the database stopped on Friday evening, a disk full, the app crashing under load on Saturday — produces no run and therefore no e-mail; the next person to notice is a user. To catch those you add **Azure-side monitoring**: an availability test or an alert rule on `/health` (Application Insights / Azure Monitor) that notifies you independently of the pipeline. Later on this course.

### Question 15: Fix or justify

**See:** Step 12 table and the AI-review reminder.

**Ignore:** comments pile up, nobody trusts review, and a real finding is lost in noise. **Blind-fix:** you take bad advice (wrong severity, out-of-scope "improvements") and the PR becomes the model's architecture, not yours. **Justify** keeps the human as owner: the history shows *why* a comment was declined — the same trail branch protection is for.
