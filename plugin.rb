# name: JiraIssue
# about: Create Jira Issue for all topics in a category
# version: 0.1
# authors: pfaffman
# url: https://github.com/pfaffman/discourse-jira-issue

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
           'jira_tag_field',
           'jira_tag_group'
         ]

  ccfs.each do |ccf|
    Category.register_custom_field_type(ccf, :string)
    Site.preloaded_category_custom_fields << ccf if Site.respond_to? :preloaded_category_custom_fields
    add_to_serializer(:basic_category, ccf.to_sym) { object.custom_fields[ccf] }
  end
  Category.register_custom_field_type('jira_create_issue', :boolean)
  Site.preloaded_category_custom_fields << 'jira_create_issue' if Site.respond_to? :preloaded_category_custom_fields
  add_to_serializer(:basic_category, :jira_create_issue) { object.custom_fields['jira_create_issue'] }

  class ::Topic
    def jira_create_issue?
      :jira_issue_enabled && self.category && self.category.custom_fields["jira_create_issue"]
    end

    def jira_url
      self.category.custom_fields['jira_url'].gsub(/\/$/, '')
    end

    def jira_project_key
      self.category.custom_fields['jira_project_key']
    end

    def jira_issuetype
      self.category.custom_fields['jira_issuetype']
    end

    def jira_tag_field?
      self.category.custom_fields['jira_tag_field'].length > 0
    end

    def jira_tag_field
      self.category.custom_fields['jira_tag_field']
    end

    def jira_post_issue
      puts "Gonna create some issue for #{self.id}!"

      topic = self
      post = Post.find_by(topic_id: topic.id, post_number: 1)
      return unless topic

      if topic.jira_create_issue?
        uri = URI.parse("#{topic.jira_url}/rest/api/2/issue")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = topic.jira_url[4] == 's'
        request = Net::HTTP::Post.new(uri.request_uri,  'Content-Type' => 'application/json')
        request.basic_auth(self.category.custom_fields['jira_user'],
                           self.category.custom_fields['jira_pass'])

        puts "URI: #{uri}"

        topic_url = "#{Discourse.base_url}/t/#{topic.slug}/#{topic.id}"

        description = "From Discourse: #{topic_url}\n\n#{post.raw}"

        if topic.jira_tag_field?
        data = {"fields" =>
                {"project" => {"key" => topic.jira_project_key},
                 "issuetype"=> {"name"=> topic.jira_issuetype},
                 topic.jira_tag_field => topic.tags.pluck(:name).join(", "),
                 "summary" => topic.title,
                 "description" => description
                }}
        else
          data = {"fields" =>
                  {"project" => {"key" => topic.jira_project_key},
                   "issuetype"=> {"name"=> topic.jira_issuetype},
                   "summary" => topic.title,
                   "description" => description
                  }}
        end
        puts "DATA: #{data}"
        request.body = data.to_json
        response = http.request(request)
        puts "RESPONSE: #{response.body}"
      end
      response
    end
  end

  DiscourseEvent.on(:post_created) do |post, opts, user|
    puts "JPI: #{post}"
    if post.post_number == 1
      puts "It's a topic!!!!"
      topic = Topic.find(post.topic_id)
      topic.jira_post_issue unless !topic
    end
  end


  class ::Category
    before_validation do
      puts "WTF: #{self.custom_fields}"
      # self.custom_fields['default_tags'] = self.custom_fields['default_tags'].join('|')
    end
  end


end
