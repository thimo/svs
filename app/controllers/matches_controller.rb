class MatchesController < ApplicationController
  include SchedulesHelper

  before_action :set_team, only: [:new, :create]
  before_action :create_match, only: [:new, :create]
  before_action :set_match, only: [:show, :edit, :update, :destroy]
  before_action :set_team_for_show, only: [:show]
  before_action :add_breadcrumbs, only: [:show, :new, :edit]

  def show
    if policy(@match).show_presences? && @team.present?
      @presences = @match.find_or_create_presences(@team).asc
      @players = @presences.present
    end
  end

  def new; end

  def create
    if @team.present?
      if @match.is_home_match == 'true'
        @match.thuisteamid = @team.club_data_team.teamcode
        @match.thuisteam   = @team.club_data_team.teamnaam
        @match.uitteamid   = nil
        @match.uitteam     = @match.opponent
      else
        @match.thuisteamid = nil
        @match.thuisteam   = @match.opponent
        @match.uitteamid   = @team.club_data_team.teamcode
        @match.uitteam     = @team.club_data_team.teamnaam
      end
    end

    @match.created_by = current_user
    @match.edit_level = current_user.admin? || current_user.club_staff? ? :club_staff : :team_staff

    if @match.save
      @match.teams << @team
      redirect_to [@match, team: @team], notice: "Wedstrijd is toegevoegd."
    else
      render :new
    end
  end

  def edit; end

  def update
    if @match.update(match_params.merge(user_modified: true))
      redirect_to @match, notice: "Wedstrijd is aangepast."
    else
      render 'edit'
    end
  end

  def destroy
    @match.update(afgelast: true, afgelast_status: "Afgelast door #{current_user.name}")
    redirect_to @match, notice: "Wedstrijd is afgelast."
  end

  private

    def set_team
      @team = Team.find(params[:team_id])
    end

    def set_team_for_show
      @team = Team.find(params[:team]) if params[:team]
      @team ||= @match.teams.first if @match.teams.size == 1
    end

    def create_match
      @match = if action_name == 'new'
                 Match.new(
                   wedstrijddatum: Match.new_match_datetime,
                   competition: Competition.custom.asc.first
                 )
               else
                 Match.new(match_params.merge(
                   user_modified: true,
                   wedstrijdcode: Match.new_custom_wedstrijdcode,
                   eigenteam: true
                 ))
               end

      authorize @match
    end

    def set_match
      @match = Match.find(params[:id])
      authorize @match
    end

    def match_params
      params.require(:match).permit(:competition_id, :wedstrijddatum, :wedstrijdtijd, :thuisteam, :uitteam, :uitslag,
        :opponent, :is_home_match,
        :accomodatie, :plaats, :adres, :postcode, :telefoonnummer, :route)
      # Automatisch
      # wedstrijd (string, team - team)
      # wedstrijdcode, negatief, zoals bij competitie
      # thuisteamid?
      # uitteamid?
      # eigenteam (true|false)
      # uitslag_at
      # afgelast
      # afgelast_status

    end

    def add_breadcrumbs
      [@team || @match.teams].flatten.each do |team|
        add_breadcrumb team.name, team
      end
      if @match.new_record?
        add_breadcrumb 'Nieuw'
      else
        add_breadcrumb schedule_title(@match), @match
      end
    end
end
