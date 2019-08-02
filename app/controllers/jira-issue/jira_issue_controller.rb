module JiraIssue
  class JiraIssueController < ::ApplicationController
    requires_plugin JiraIssue

    before_action :ensure_logged_in

    def index
    end
  end
end
