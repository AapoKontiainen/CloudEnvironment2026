# Assignment 4 — Example answers (theory)

**Do not submit these.** They are training for the exam, and they are useful knowledge in the software industry. Answer the questions in [questions.md](questions.md) **in your own words first**, then open this file and compare.

A few sentences is enough. You will be asked what came back after resurrection — explain **IaC ≠ backup**, not only "we used Bicep".

---

### Question 1: Declarative vs. imperative

**See:** Guided section A (the provisioning ladder).

**Imperative** is a list of commands in order (`az ... create`, `if exists`). **Declarative** describes the end state; ARM computes the diff. `provision-db.ps1` is imperative — you wrote the "already exists" checks. `main.bicep` is declarative. The template gets those existence checks **for free**.

### Question 2: No `az group exists` in Bicep

**See:** Section A (ARM compare) and Step 4 (no resource group in the template).

The checks moved into **Azure Resource Manager**. Bicep says "a plan like this exists"; ARM compares that claim to the live resource group. Missing → create, different → change, same → do nothing. The template does not target creating the resource group itself — that already exists from Assignment 1.

### Question 3: No state file

**See:** Section A diagram (`main.bicep` → ARM JSON → Resource Manager).

Terraform stores last-applied state in a file. Bicep does not. ARM compares the **compiled template** to **live Azure** in that resource group. There is no extra file to drift or to lock — but incremental mode also cannot "remember" resources you deleted from the template.

### Question 4: What-if every time

**See:** Step 7 reminder and Steps 13–15.

Someone (or you, on Friday in the Portal) may have changed a tag or SKU. What-if shows the diff **before** you apply it. In the drift experiment, what-if showed `Environment: production => dev` — you would have missed that if you deployed blind.

### Question 5: Incremental enforce vs. ignore

**See:** Step 15 reminder (what drift detection does NOT catch).

Incremental mode **enforces** resources (and properties) that are **in the template** — that is why the tag change was a `~`. It **ignores** resources that exist in Azure but are **not** in the template — a forgotten VM or an extra storage account does not even appear in what-if, and the deployment leaves it running. Exercise 2 *refactors* storage into a module; it does not remove it from the description.

### Question 6: "We have IaC, so we are in control"

**See:** Question 5 and the `ManagedBy` tag in Step 4.

False when a teammate creates a resource only in the Portal — incremental deploy never sees it, and it keeps billing. Close the gap with **tag discipline** (`ManagedBy: Bicep`), Cost analysis by tag, or a tool that lists orphans (deployment stacks). IaC controls what the file claims, not the whole subscription by magic.

### Question 7: `@secure()` + derived connection string

**See:** Steps 9–10 (password and connection strings).

Two problems prevented: (1) the password is **not in a versioned file or deploy log** — `readEnvironmentVariable` keeps it out of `dev.bicepparam`, and `@secure()` stores only `SecureString` in the deployment history; (2) the hostname cannot go stale — it is taken from the module output, so a new server name still matches the app setting. Assignment 3's hand-built string could disagree with the real FQDN. Current Bicep does not prompt for a parameter omitted from a `.bicepparam` file (`BCP258`).

### Question 8: Secrets ladder

**See:** Step 10 reminder (secrets ladder, revisited).

Still **Application Settings** — the password ends up on the web app. Bicep improved *how* it gets there (environment variable + `@secure()` + derived string). It did **not** remove the password from config. Key Vault + Managed Identity is a later rung.

### Question 9: Both connection strings, or the deployment un-sets one

**See:** Step 10 callout ("Why *both* strings must be in the template").

`appSettings` is deployed as a **complete list**: whatever the template contains *replaces* the web app's settings. With only the database string listed, the next deployment would have silently removed `ConnectionStrings__Storage`, and poster uploads would have started failing. Incremental mode only protects whole **resources** that are outside the template — *inside* a resource that is in the template, the template's word is final. Adopting a hand-built environment therefore means describing everything you once set by hand.

### Question 10: What came back

**See:** Step 18 table.

Seeded events came back because **app code** (`EnsureCreated` + seeder) fills an empty database. Hand-made registrations did not — they were **data**, not infrastructure. **IaC ≠ backup.**

### Question 11: Automatic backups vs. delete

**See:** Step 18 last paragraph.

Deleting the **server** deletes its backup store too. Retention only helps while the server exists. Production: take a `pg_dump` or restore a copy to another server first, and delete only when a backup lives somewhere the delete cannot reach (another server, Blob Storage, a vault). If the data is wanted back soon, **stop** instead of delete.

### Question 12: Two kinds of AI mistakes

**See:** Step 20 table and Step 21.

Fails loudly: an invented API version or a misspelled property (the compiler rejects the file), or `alwaysOn: true` on F1 (compiles fine, the **deployment** refuses it). Nothing wrong ever exists in Azure. Deploys but wrong: a valid but **expensive SKU**, or a missing `reserved: true` that quietly gives you a Windows plan. The second kind is more dangerous — the deploy is green and the bill (or the runtime) is not, so nobody looks. Loud failures are the cheap ones.

### Question 13: Write the prompt

**See:** Steps 4–11 (names, SKUs, both connection strings, the password), Step 7 (what-if) and Step 20 (the short prompt and its failures).

Your prompt will differ. Compare it with this one, checking that each of the four parts is there:

```
You are working in my Campus Events repository. Describe my EXISTING Azure
environment as Bicep. Do not design a new one. The goal is that the first
deployment adopts what is already there.

Context:
- Resource group: rg-cloud26-<name>-dev (exists, has a budget alert,
  do NOT put the resource group in the template)
- Existing names (must match exactly, or a second resource gets created):
  plan-cloud26-<name>-dev, app-cloud26-<name>-dev<suffix>,
  pg-cloud26-<name>-dev, stcloud26<name>dev
- App Service Plan: Linux, F1, reserved: true. Web app: DOTNETCORE|10.0,
  httpsOnly, minTls 1.2, FTPS disabled. alwaysOn only when the SKU is not F1.
- PostgreSQL Flexible Server in modules/postgres.bicep: Standard_B1ms /
  Burstable, version 16, 32 GB, 7-day backups, no HA, public access on,
  database "campusevents", firewall rule AllowAzureServices 0.0.0.0.
  No firewall rule for my own IP.
- Storage account Standard_LRS StorageV2 with a private "posters" container.
- The web app already has TWO app settings: ConnectionStrings__DefaultConnection
  and ConnectionStrings__Storage. The template must set both, derived from the
  module output and listKeys(). appSettings replaces the whole list.
- Tags on every resource: Environment, Course=cloud26, Owner, ManagedBy=Bicep.
- Parameters in infra/dev.bicepparam.

Secret rule:
- The PostgreSQL password is a @secure() param, read in dev.bicepparam with
  readEnvironmentVariable('POSTGRES_ADMIN_PASSWORD'). Never write it into a
  file, an output, a commit or the terminal. Never set the variable yourself.

Stop points:
1. After writing the files: run az bicep build, fix every error and warning,
   then STOP and show me the files.
2. Run az deployment group what-if. STOP. Explain every + and ~ line.
   Do not deploy.
3. Run az deployment group create only after I reply "deploy".
4. Never delete anything and never use --mode Complete.

Done (I check these myself): what-if after the deploy shows no + lines,
/health returns Healthy, events and posters still load.
```

What matters is not the exact wording but that the prompt carries **your knowledge**: names that must match, both connection strings, F1 limits, where the password lives. The stop points keep the decision to apply changes with you. "Done" is something you can check yourself, not the agent saying "deployment succeeded".

### Question 14: What only you knew

**See:** Step 4 callout (name suffix), Step 5 (`alwaysOn`, `reserved`), Step 10 callout (both strings), Step 20 table.

Any three of these, for example:

| Detail | Without it, the agent would… | Kind |
|--------|-----------------------------|------|
| Exact names (and the Assignment 1 suffix) | Invent tidy new names → what-if plans a **second** web app, server and an empty storage account | Silent: it deploys and costs money. What-if shows the `+` lines, but only a human reading them catches it |
| Both connection strings in `appSettings` | List only the database string → the deploy wipes `ConnectionStrings__Storage` | Silent: green deploy, poster uploads break |
| `reserved: true` on the plan | Forget it → Windows plan | Silent: deploys, then the Linux runtime does not work |
| `alwaysOn` off on F1 | Set `alwaysOn: true` | Loud: the deployment refuses it |
| Password via `readEnvironmentVariable` + `@secure()` | Hard-code it or use a plain `param` | Silent and the worst: the password ends up in git |
| B1ms / Burstable SKU | Pick a General Purpose SKU "for production" | Silent: shows up only on the bill |

Most of these are the silent kind. That is the point of question 12: the context you put in the prompt prevents the mistakes that no compiler catches.
