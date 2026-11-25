# Assignment 2 — What to return and theory

## What to return

**All returns go to the Learn platform.** Submit only the screenshots below. Do not upload code.

Theory questions further down this file are **not submitted**. They are training for the exam, and they are useful knowledge in the software industry. Write your own answers first — you will be asked to explain the Step 8 flip-flop in your own words. Example answers are in [example-answers.md](example-answers.md) — use them to check yourself, not as a copy-paste.

- [ ] Screenshot: Step 7 — two different `machine` values **or**, if Azure stayed at one instance after five minutes, `az webapp list-instances` (one row) plus `plan show` (`B1` / `workers: 2`)
- [ ] Screenshot: Step 8 — the `seatsTaken` flip-flop **or**, if you only had one live instance, the constant `seatsTaken` loop plus a one-sentence explanation in your answers document
- [ ] Screenshot: plan back on `F1` with `workers: 1` (Step 12 verification)
- [ ] Screenshot: Cost analysis showing the B1 charge (can be submitted a day later)

Written work that is not a screenshot (edited ADR from Step 15, exercise 1–3 write-ups) goes in your Learn answers document.

---

# Theory questions — Architecture paradigms and scaling

**Do not submit these answers.** They train you for the exam, and they are good knowledge to have in the software industry. Try each question yourself, then compare with [example-answers.md](example-answers.md).

Answer the following questions in your own words. Answers do not need to be long — a few sentences are enough as long as you demonstrate understanding. Everything you need is in this assignment's README (section A paradigms, sections D–F, and the wiki / Learn links under Additional material).

---

## Part 1: Paradigms

### Question 1: Monolith is not a dirty word

Campus Events is a monolith, and for this course that is the right choice. Give two reasons why starting with a monolith is often correct, and one signal that would tell you it is time to split it.

### Question 2: Serverless fit

Describe a workload from your own experience (school, hobby, work) that would fit Azure Functions well. Why? What property of the workload makes serverless cheaper or simpler than an always-on App Service?

### Question 3: Event-driven decoupling

What does it mean that a queue "decouples" a producer from a consumer? Give a concrete benefit during a traffic spike — what happens with the queue, and what would happen with a direct HTTP call instead?

---

## Part 2: Scaling and state

### Question 4: Explain the flip-flop

In Step 8, two instances behind one URL can return `seatsTaken: 1` and `seatsTaken: 2` on consecutive requests. Explain precisely why, mentioning the load balancer and where each instance's data lives. (If Azure started only one instance for you, still explain the two-instance case — that is the exam question.)

### Question 5: Scale up vs. scale out

Your app is slow under load. Give one situation where scaling **up** is the right first move, and one where scaling **out** is — and what must be true about the app before scale-out helps at all.

### Question 6: Sticky sessions

ARR affinity made the app *look* correct from a single browser in Exercise 2. List two problems that stickiness leaves unsolved.

### Question 7: Autoscale danger

Suppose we had enabled autoscale (2–10 instances) on the current in-memory app. Describe what users would experience during a busy registration day.

---

## Part 3: Decisions and cost

### Question 8: The meter

The B1 experiment cost a few cents. Describe the four-step cost habit from Section E (before changing SKU → during → after → verification), and name one real-world consequence of skipping the "after" step.

### Question 9: ADR value

Why write an Architecture Decision Record instead of just doing the change? Who reads an ADR six months later, and what question are they trying to answer?

### Question 10: AI in architecture work

In Step 14 you asked AI to argue both sides of a decision. Why is "argue both sides" a better prompt for architecture work than "tell me the best option"? Connect your answer to how AI models tend to respond.
