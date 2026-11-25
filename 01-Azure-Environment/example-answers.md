# Assignment 1 — Example answers (theory)

**Do not submit these.** They are training for the exam, and they are useful knowledge in the software industry. Answer the questions in [questions.md](questions.md) **in your own words first**, then open this file and compare.

A few sentences is enough. Copying this text into the exam will not help — you will be asked to explain, not recite.

---

### Question 1: CLI vs. Portal

**See:** Guided section A–B (why CLI), section C (budget in the Portal).

The CLI is repeatable: the same command creates the same resource next week, and it can go into a script (`provision.ps1`). It is also easier to review and share than a click path. The Portal is still better for **seeing** things (Cost analysis, budget form, Overview blades) and for one-off exploration. Use CLI to create, Portal to verify.

### Question 2: Resource group

**See:** Guided section B — what a resource group does.

One group is one cost view and one cleanup. (a) Cost analysis and the budget can target the course only, not the whole subscription. (b) At the end of the course `az group delete` removes everything in one command — no orphan plans or forgotten apps.

### Question 3: Tags

**See:** Section B (tags do not inherit) and Step 15.

Cost analysis and inventory filter on **resource** tags, not the group's tags. If the plan and web app have no `Owner` or `Environment`, a leftover B1 plan is hard to attribute and easy to leave running. `Owner=you@school.fi` means the bill has a person; `Environment=dev` means nobody mistakes it for production.

### Question 4: Naming convention

**See:** Course naming convention in section B.

`rg-cloud26-matti-dev` tells you type, course, person, and environment without opening the Portal. Without a convention you get `test`, `newapp2`, and `Copy of plan` — people delete the wrong resource or cannot find the one that is billing.

### Question 5: Budget first

**See:** Course principle in the welcome, guided section C.

The budget is the safety net **before** a mistaken SKU or a forgotten resource can surprise you. It **emails** you at the thresholds you set. It does **not** freeze or delete resources — spending continues until you change or delete them.

### Question 6: Actual vs. Forecasted

**See:** Step 8 table and the Actual vs. Forecasted reminder.

*Actual* fires when money has already been spent (50% / 80% of €10). *Forecasted* fires when Azure **predicts** the month will hit the limit at the current rate. Forecasted gives more time: you can still stop or delete before the money is gone.

### Question 7: SKU choice

**See:** Section D (SKU), Step 17 pricing table, F1 limits reminder.

Besides price, B1 has dedicated compute (no daily CPU quota), can scale out, and can stay always-on. F1 is free but sleeps, has 60 CPU minutes/day, and only one instance. F1 is no longer enough when you need scale-out, Always On, or you hit the daily quota (the site stops answering).

### Question 8: CapEx vs. OpEx

**See:** [Cloud Concepts — CapEx vs. OpEx](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/Cloud-Concepts.md#capex-vs-opex) and section E cleanup.

The plan is **OpEx**: you pay while it exists, even at zero users. In a datacenter (CapEx) the server is already bought — leaving it on does not add a monthly bill. In Azure an idle B1 still meters every hour, so unused resources must be scaled down or deleted.

### Question 9: PaaS shared responsibility

**See:** Section D (what App Service is) and [Cloud Concepts](https://github.com/xamk-mire/Xamk-wiki/blob/main/Cloud%20technologies/Cloud-Concepts.md).

**Microsoft:** OS, patching, the physical host, HTTPS front end, the platform that runs your process. **You:** the application code, configuration and secrets, what you store, SKU and region choices, and cleaning up what you created.

### Question 10: Same code, different environment

**See:** Step 13 `/info` comparison.

The process can be recycled, moved, or duplicated. Hostnames, paths, and "this machine" are not stable. If you scale out, each instance is a different machine — any assumption about local files or in-memory data will be wrong on the next request.

### Question 11: Reviewing AI output

**See:** Guided section F, rule of thumb after Step 21.

`show` / `list` cannot delete your lab. `create` / `update` / `delete` can create a paid SKU, overwrite tags, or `az group delete` the whole course environment. Review mutating lines one by one — a hallucinated resource name or a missing `--os-type Linux` is cheap to catch and expensive to run.
