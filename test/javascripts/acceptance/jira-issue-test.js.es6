import { acceptance } from "helpers/qunit-helpers";

acceptance("JiraIssue", { loggedIn: true });

test("JiraIssue works", async assert => {
  await visit("/admin/plugins/jira-issue");

  assert.ok(false, "it shows the JiraIssue button");
});
