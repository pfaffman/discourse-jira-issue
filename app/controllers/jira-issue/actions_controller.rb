module JiraIssue
  class ActionsController < ::ApplicationController
    requires_plugin JiraIssue

    before_action :ensure_logged_in

    def index
      render_json_dump({ actions: [] })
    end

    def show
      render_json_dump({ action: { id: params[:id] } })
    end
  end
end
