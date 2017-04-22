class TeamsController < ApplicationController
  before_action :create_team, only: [:new, :create]
  before_action :set_team, only: [:show, :edit, :update, :destroy]
  before_action :breadcumbs

  def show
    @players = @team.team_members.player.asc.includes(:member).includes(:team).includes(:field_positions)
    @staff = @team.team_members.staff.asc.includes(:member).includes(:team).group_by(&:member)
    @team_evaluations = policy_scope(TeamEvaluation).by_team(@team).desc
  end

  def new; end

  def create
    if @team.save
      redirect_to @team, notice: 'Team is toegevoegd.'
    else
      render :new
    end
  end

  def edit; end

  def update
    old_status = @team.status

    if @team.update_attributes(permitted_attributes(@team))
      @team.transmit_status(@team.status, old_status)

      redirect_to @team, notice: 'Team is aangepast.'
    else
      render 'edit'
    end
  end

  def destroy
    redirect_to @team.age_group, notice: 'Team is verwijderd.'
    @team.destroy
  end

  private

    def create_team
      @age_group = AgeGroup.find(params[:age_group_id])

      @team = if action_name == 'new'
                @age_group.teams.new
              else
                Team.new(permitted_attributes(Team.new))
              end
      @team.age_group = @age_group

      authorize @team
    end

    def set_team
      @team = Team.find(params[:id])
      authorize @team
    end

    def breadcumbs
      add_breadcrumb "#{@team.age_group.season.name}", @team.age_group.season
      add_breadcrumb @team.age_group.name, @team.age_group
      if @team.new_record?
        add_breadcrumb 'Nieuw'
      else
        add_breadcrumb @team.name, @team
      end
    end
end
