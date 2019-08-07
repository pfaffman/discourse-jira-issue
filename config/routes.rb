require_dependency "jira_issue_constraint"

JiraIssue::Engine.routes.draw do
  get "/" => "jira_issue#index", constraints: JiraIssueConstraint.new
  get "/actions" => "actions#index", constraints: JiraIssueConstraint.new
  get "/actions/:id" => "actions#show", constraints: JiraIssueConstraint.new
end
