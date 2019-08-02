class JiraIssueConstraint
  def matches?(request)
    SiteSetting.jira_issue_enabled
  end
end
