# Assignment 1 — What to return and theory

## What to return

**All returns go to the Learn platform.** Submit only the screenshots and the live link below. Do not upload code or script files.

Theory questions further down this file are **not submitted**. They are training for the exam, and they are useful knowledge in the software industry. Write your own answers first. Example answers are in [example-answers.md](example-answers.md) — use them to check yourself, not as a copy-paste.

- [ ] Screenshot: resource group in the Portal, tags visible
- [ ] Screenshot: budget and alert thresholds (Budgets view)
- [ ] **Link:** your app's `/api/events` URL on `azurewebsites.net` (the teacher will open it)
- [ ] Screenshot: `/api/stats` response from your Azure URL (exercise 2)
- [ ] Screenshot: `check.ps1` output (guided section F) and `provision.ps1` run output (exercise 1)

Written work that is not a screenshot (exercise 1 — what you asked AI, what it suggested, what you changed) goes in your Learn answers document.

---

# Theory questions — Azure environment and cost management

**Do not submit these answers.** They train you for the exam, and they are good knowledge to have in the software industry. Try each question yourself, then compare with [example-answers.md](example-answers.md).

Answer the following questions in your own words. Answers do not need to be long — a few sentences are enough as long as you demonstrate understanding. Everything you need is in this assignment's README (and the wiki / Learn links listed under Additional material).

---

## Part 1: Working environment and resources

### Question 1: CLI vs. Portal

Why do we create resources primarily with the Azure CLI on this course instead of clicking in the Portal? Give at least 2 reasons. When is the Portal still the better tool?

### Question 2: Resource group

Why are all course resources created in the same resource group? What is the benefit for (a) cost tracking and (b) at the end of the course?

### Question 3: Tags

Tags set on a resource group do not inherit to the resources inside it. Why is it still worth tagging every resource? Give a concrete example where an `Owner` or `Environment` tag saves time or money.

### Question 4: Naming convention

What is the benefit of a consistent naming convention (e.g. `rg-cloud26-matti-dev`)? What problems would arise if everyone named resources however they liked?

---

## Part 2: Costs

### Question 5: Budget first

Why was the budget alert created **before** any application? What does a budget do, and what does it **not** do (does it stop spending)?

### Question 6: Actual vs. Forecasted

Explain the difference between *Actual* and *Forecasted* alert conditions. Which one gives more time to react, and why?

### Question 7: SKU choice

You compared F1 and B1 tiers in the pricing calculator. Apart from price, what else differs between them? In what situation would F1 no longer be enough?

### Question 8: CapEx vs. OpEx

An App Service Plan is billed by the hour even if the app has zero users. How does this relate to CapEx vs. OpEx thinking, and why is cleaning up unused resources more important in the cloud than in your own datacenter?

---

## Part 3: App Service and PaaS

### Question 9: PaaS shared responsibility

When your app runs on App Service, which responsibilities belong to Microsoft and which to you? Give at least 2 items for each (hint: shared responsibility model).

### Question 10: Same code, different environment

In Step 13 you compared `/info` locally and in Azure. The `machine` field showed a different value even though the code was the same. Why should an application never assume anything about the machine it runs on? How does this relate to scalability?

---

## Part 4: AI as a tool

### Question 11: Reviewing AI output

In the assignment we agreed that read commands (`show`, `list`) may be run from an AI suggestion with a lighter check, but mutating and deleting commands (`create`, `delete`) are reviewed line by line. Why is this split sensible? Give an example of damage that a blindly run AI-generated command could cause in an Azure environment.
