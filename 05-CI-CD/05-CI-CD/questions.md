# Assignment 5 — Theory questions (exam training)

**Do not submit these answers.** They are not part of the Learn return — what you return is listed in [README.md](README.md) under *What do you return?* and *Submission*. These questions train you for the exam, and they are good knowledge to have in the software industry: you will be asked to explain OIDC vs. a stored password, and why the smoke test failed with a stopped database.

Try each question yourself, then compare with [example-answers.md](example-answers.md) — use it to check yourself, not as a copy-paste.

Answer in your own words. Short answers are fine (2–5 sentences), but they must show you understand the *why*, not just the *what*. Everything you need is in this assignment's README (and the wiki / Learn links under Additional material).

## CI and quality gates

1. Explain the difference between **Continuous Integration**, **Continuous Delivery**, and **Continuous Deployment**. Which one did the guided section build, and which one did Exercise 2 temporarily turn it into?

2. Why does the CI pipeline run in a fresh `ubuntu-latest` VM instead of on your machine? Name one class of bug this catches that local testing structurally cannot.

3. Branch protection made the checks mandatory *even for you*, the repository admin. Why is "Do not allow bypassing" the right setting even in a one-person project? (Hint: think about deadline pressure, and about what the setting protects besides the code.)

4. The `dotnet format --verify-no-changes` gate fails a PR over whitespace. Is that overkill? Give one argument for and one against strict lint gates, and your own verdict.

## Testing

5. The integration tests replace PostgreSQL with EF Core's InMemory provider. Name one concrete bug that these tests **cannot** catch because of that substitution, and the tool you would adopt if you needed to catch it in CI.

6. `public partial class Program;` was added to `Program.cs` back in Assignment 1. Explain what `WebApplicationFactory<Program>` does with it, and why testing through real HTTP requests (instead of calling `PostgresEventStore` methods directly) was the right level for these gate tests.

## OIDC and secrets

7. Compare the two ways a pipeline can authenticate to Azure: a stored credential (publish profile / service principal password) vs. **OIDC federated identity**. Give two concrete risks the OIDC approach eliminates. Bonus: what does `permissions: id-token: write` do, and what happens if you leave it out?

8. In the federated credential, the `subject` claim was `repo:<owner>@<owner-id>/<repo>@<repo-id>:ref:refs/heads/main`. Explain what an attacker who forked your repository (and can run workflows in the fork) can and cannot do, and why. Bonus: why did GitHub add the numeric IDs?

9. `AZURE_CLIENT_ID` is stored in GitHub *Secrets* although it is not really a secret, while `PG_PASSWORD` genuinely is one. What would the next rung of the secrets ladder look like for `PG_PASSWORD` in this pipeline?

10. The pipeline identity got **Contributor on your resource group only**, not on the subscription. Describe what someone who hijacks the pipeline could and could not do with that role. Also: why did the lab use a user-assigned **managed identity** instead of an app registration, and which part of the workflow stays identical either way?

## The deploy pipeline

11. The deploy workflow has `needs: infra` on the app job and a `concurrency` group on the whole workflow. Describe one concrete failure scenario that *each* of these two settings prevents.

12. In Step 21 you skipped the infra job on purpose, the *Deploy to App Service* step went green, and only the smoke test caught the problem. Explain (a) why "deploy succeeded" did not mean the app was running, and (b) why the infra job had to be skipped instead of being left in the run. What does this teach about the difference between "the resource exists", "the resource can be updated", and "the service works"?

13. The smoke test polls `/health` up to 10 times with 15-second waits. Why is a retry loop the right design instead of a single check — and what risk appears if you make the loop *too* patient (say, 100 retries)?

14. The GitHub failure e-mail told you about a broken deploy. Name one kind of fault it will *never* tell you about, and what you would add to catch it.

## AI in the pipeline

15. The course rule is "every AI review comment gets a human decision: fix or justify". Explain why the *justify* half matters as much as the *fix* half — what goes wrong in a team where AI comments are silently ignored, and in a team where they are all blindly fixed?
