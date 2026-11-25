# Assignment 4 — What to return and theory

## What to return

**All returns go to the Learn platform.** Submit only the screenshots and the live link below. Do not upload code or Bicep files.

Theory questions further down this file are **not submitted**. They are training for the exam, and they are useful knowledge in the software industry. Write your own answers first — you will be asked to explain the resurrection test (what came back and what did not). Example answers are in [example-answers.md](example-answers.md) — use them to check yourself, not as a copy-paste.

- [ ] Screenshot: your `main.bicep` open in the editor — parameters and modules visible, **no passwords anywhere**
- [ ] Screenshot: what-if output from Step 7 or 11, with a 1–2 sentence explanation of every `+`/`~` line
- [ ] Screenshot: the drift experiment — what-if detecting your Portal change (Step 14)
- [ ] Screenshot: `/health` returning 503 after deletion, and `Healthy` + events after resurrection (Steps 16–17)
- [ ] **Link:** your resurrected app's URL on `azurewebsites.net`
- [ ] Screenshot: exercise 1 — test environment evidence, and confirmation that you deleted it
- [ ] Screenshot: exercise 2 — what-if after the module refactor, showing **no new or renamed resource** (the known noise lines from Step 11 may still be there)
- [ ] Screenshot: exercise 3 — `deploy.ps1` run output (what-if preview + confirmation prompt visible)

Written work that is not a screenshot (Step 18 what came back / what did not, AI review notes, exercise 1 reflection, exercise 2 `existing` + `dependsOn` sentences) goes in your Learn answers document.

---

# Theory questions

**Do not submit these answers.** They train you for the exam, and they are good knowledge to have in the software industry. Try each question yourself, then compare with [example-answers.md](example-answers.md).

Answer in your own words. Short answers are fine (2–5 sentences), but they must show you understand the *why*, not just the *what*. Questions 13–14 are longer: they are a writing exercise, not an exam-style answer. Everything you need is in this assignment's README (and the wiki / Learn links under Additional material).

## IaC concepts

1. Explain the difference between **declarative** and **imperative** infrastructure provisioning. Place your Assignment 3 `provision-db.ps1` and this assignment's `main.bicep` on those two sides, and name one concrete piece of work the script did that the template gets for free.

2. Your `provision.ps1` checked `az group exists` before creating anything. Why does `main.bicep` contain no such checks — where did that logic go?

3. What does it mean that Bicep has **no state file** (unlike Terraform)? What does ARM compare the template against during a deployment?

## What-if and drift

4. Why should `what-if` be run before *every* deployment, even when you are "sure" nothing else has changed? Use your Step 13–15 drift experiment as evidence.

5. Incremental deployments ignore resources that exist in Azure but are **absent from the template**. What-if in the drift experiment (Step 14) proposed changing a tag that *is* in the template. Explain the difference — what does an incremental deployment enforce, and what does it ignore? (Hint: the reminder at the end of Step 15.)

6. A teammate says: "We use IaC, so our Azure environment is fully under control." Based on question 5, give one concrete scenario where this is false, and one practice (tooling or discipline) that closes the gap.

## Secrets and configuration

7. The PostgreSQL password is a `@secure()` parameter read from an environment variable (`readEnvironmentVariable`), and the connection string is *derived* inside the template from the module's output. Name two distinct problems this design prevents, compared to Assignment 3's approach of hand-building the connection string and setting it with the CLI.

8. Which rung of the secrets ladder is this assignment on (code / config file / Application Settings / Key Vault + Managed Identity)? What specifically did Bicep improve about secret handling, and what did it *not* change?

9. In Step 10 you had to put **both** connection strings into the template's `appSettings`, even though `ConnectionStrings__Storage` already existed on the web app from Assignment 3. What would the next deployment have done if you had listed only the database string — and why does "incremental mode leaves things alone" not protect you here?

## The resurrection test

10. After deleting and recreating the PostgreSQL server, the three seeded events came back but your hand-made registrations did not. Explain both facts, and state the general principle in one sentence (hint: **IaC ≠ ___**).

11. Flexible Server takes automatic backups with 7-day retention. Why did those backups not save your registrations in the resurrection test? What would a production team do differently before deleting a database server?

## AI

12. In Step 20 the AI-generated template contained mistakes of two kinds: those that **fail loudly** before anything wrong exists in Azure (the compiler or linter rejects the file, or the deployment itself refuses), and those that **deploy successfully but are wrong** (e.g. an oversized SKU). Give one example of each kind, and explain which kind is more dangerous and why.

13. **Write the prompt.** The Step 20 prompt was short, and the AI filled the gaps with guesses. Now that you have done the work yourself, write a prompt that would make an AI coding agent (one that can edit your repository and run commands in your terminal) do the core of this assignment for you: turn your existing Assignment 3 environment into `infra/main.bicep`, `infra/modules/postgres.bicep` and `infra/dev.bicepparam`, preview the result with what-if, and deploy it. Use the Step 21 prompt (`deploy.ps1`) as a model for the shape. Your prompt must cover:
    - **Context the AI cannot guess:** the resource group, the existing resource names (including any suffix from Assignment 1), the SKUs, the runtime and the app settings that already exist on the web app
    - **The secret rule:** where the PostgreSQL password comes from, and where it must never appear
    - **Stop points:** the moments where the agent must stop and wait for you before it continues
    - **Done:** how you, not the agent, check that the result is correct

14. Pick **three** details from your prompt that you only knew because you built this environment by hand. For each one, say what the agent would most likely have done without it, and whether that mistake would have failed loudly or deployed silently (question 12).
