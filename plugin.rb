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
  ccfs = [ 'jira_url',
           'jira_user',
           'jira_pass',
           'jira_project_key',
           'jira_issuetype',
           'jira_tag_field'
         ]

  ccfs.each do |ccf|
    Category.register_custom_field_type(ccf, :boolean)
    Site.preloaded_category_custom_fields << ccf if Site.respond_to? :preloaded_category_custom_fields
    add_to_serializer(:basic_category, :default_tags) { object.custom_fields[ccf] }
  end
  Category.register_custom_field_type('jira_create_issue', :string)
  Site.preloaded_category_custom_fields << 'jira_create_issue' if Site.respond_to? :preloaded_category_custom_fields
  add_to_serializer(:basic_category, :default_tags) { object.custom_fields['jira_create_issue'] }

  class ::Topic
    def jira_create_issue?
      :jira_issue_enabled && self.category && self.category.custom_fields["jira_create_issue"]
    end

    def jira_url
      self.category.custom_fields['jira_url'].gsub(/\/$/, '')
    end

    def jira_auth
      return (self.category.custom_fields['jira_username'], self.category.custom_fields['jira_password'])
    end

    def jira_project_key
      self.category.custom_fields['jira_project_key']
    end

    def jira_jira_issuetype
      self.category.custom_fields['jira_jira_issuetype']
    end

    def jira_tag_field?
      self.category_custom_fields['jira_tag_field'].length > 0
    end

    def jira_tag_field
      self.category_custom_fields['jira_tag_field']
    end

    def jira_post_issue
      puts "Gonna create some issue for #{self.category.custom_fields}!"

      if self.jira_create_issue?
        uri = URI.parse("#{self.jira_url}/rest/api/2/issue")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = self.jira_url[4] == 's'
        request = Net::HTTP::Post.new(uri.request_uri,  'Content-Type' => 'application/json')
        request.basic_auth(self.jira_auth)

        if self.jira_custom_field?
        data = {"fields" =>
                {"project" => {"key" => self.jira_project_key},
                 "issuetype"=> {"name"=> self.jira_issuetype},
                 self.jira_custom_field => self.tags.pluck(:name).join(", "),
                 "summary" => "self.title",
                 "description" => self.raw + "\n---\n" self.cooked
                }}
        else
          data = {"fields" =>
                  {"project" => {"key" => self.jira_project_key},
                   "issuetype"=> {"name"=> self.jira_issuetype},
                   "summary" => "self.title",
                   "description" => self.raw + "\n---\n" self.cooked
                  }}
        end
        request.body = data.to_json
        response = http.request(request)
        puts response.body
        end
      end
    response
    end

    DiscourseEvent.on(:post_created) do
      # FIX THIS
      self.topic_tag_default_tags.each do |tag|
        TopicTag.create(topic_id: self.id, tag_id: tag.id)
      end
    end
  end

  class ::Category
    before_validation do
      puts "WTF: #{self.custom_fields}"
      # self.custom_fields['default_tags'] = self.custom_fields['default_tags'].join('|')
    end
  end


end
