# name: JiraIssue
# about: Create Jira Issue for all topics in a category
# version: 0.1
# authors: pfaffman
# url: https://github.com/pfaffman

register_asset "stylesheets/common/jira-issue.scss"
register_asset "stylesheets/desktop/jira-issue.scss"
register_asset "stylesheets/mobile/jira-issue.scss"

enabled_site_setting :jira_issue_enabled

PLUGIN_NAME ||= "JiraIssue".freeze

load File.expand_path('../lib/jira-issue/engine.rb', __FILE__)

after_initialize do
  # https://github.com/discourse/discourse/blob/master/lib/plugin/instance.rb
end
