module JiraIssue
  class Engine < ::Rails::Engine
    engine_name "JiraIssue".freeze
    isolate_namespace JiraIssue

    config.after_initialize do
      Discourse::Application.routes.append do
        mount ::JiraIssue::Engine, at: "/jira-issue"
      end
    end
  end
end
