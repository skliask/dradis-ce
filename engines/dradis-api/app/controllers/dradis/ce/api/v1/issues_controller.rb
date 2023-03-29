module Dradis::CE::API
  module V1
    class IssuesController < Dradis::CE::API::APIController
      include ActivityTracking
      include Dradis::CE::API::ProjectScoped

      before_action :validate_state, only: [:create, :update]

      def index
        @issues = current_project.issues.includes(:tags).order('updated_at desc')
        @issues = @issues.page(params[:page].to_i) if params[:page]
        @issues = @issues.sort
      end

      def show
        @issue = current_project.issues.find(params[:id])
      end

      def create
        @issue = current_project.issues.new(issue_params)
        @issue.author   = current_user.email
        @issue.category = Category.issue
        @issue.node     = current_project.issue_library

        if @issue.save
          track_created(@issue)
          @issue.tag_from_field_content!
          render status: 201, location: dradis_api.issue_url(@issue)
        else
          render_validation_errors(@issue)
        end
      end

      def update
        @issue = current_project.issues.find(params[:id])
        if @issue.update(issue_params)
          track_updated(@issue)
          render node: @node
        else
          render_validation_errors(@issue)
        end
      end

      def destroy
        @issue = current_project.issues.find(params[:id])
        @issue.destroy
        track_destroyed(@issue)
        render_successful_destroy_message
      end

      private
      def issue_params
        params.require(:issue).permit(:state, :text)
      end

      def validate_state
        return if issue_params[:state].nil?

        unless Issue.states.keys.include? issue_params[:state]
          issue = Issue.new
          issue.errors.add(:state, 'invalid value.')
          render_validation_errors(issue)
        end
      end
    end
  end
end
