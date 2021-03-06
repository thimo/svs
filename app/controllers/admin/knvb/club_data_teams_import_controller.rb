module Admin
  module Knvb
    class ClubDataTeamsImportController < Admin::BaseController
      def new
        authorize ClubDataTeam
        ClubdataScheduler::TeamsAndCompetitionsJob.enqueue
        flash_message(:success, "Import is ingepland.")
        redirect_to admin_knvb_club_data_teams_path
      end
    end
  end
end
