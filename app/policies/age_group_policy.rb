class AgeGroupPolicy < ApplicationPolicy
  # def index?
  #   true
  # end

  def show?
    @record.archived? || @record.active? ||
      @user.role?(Role::STATUS_DRAFT) || @user.indirect_role?(Role::STATUS_DRAFT)
  end

  def create?
    return false if @record.season.archived?

    @user.role?(Role::AGE_GROUP_CREATE)
  end

  def update?
    @user.role?(Role::AGE_GROUP_UPDATE, @record)
  end

  def destroy?
    return false if @record.archived? || @record.active?

    create?
  end

  def show_favorite?
    !@record.draft?
  end

  def show_evaluations?
    @user.role?(Role::AGE_GROUP_SHOW_EVALUATIONS, @record)
  end

  def show_play_bans?
    return false if @record.archived?

    @user.role?(Role::PLAY_BAN_SHOW, @record)
  end

  def show_todos?
    return false if @record.archived?

    @user.role?(Role::AGE_GROUP_SHOW_TODOS, @record)
  end

  def show_injureds?
    return false if @record.archived?

    @user.role?(Role::AGE_GROUP_SHOW_INJUREDS, @record)
  end

  def show_available_members?
    return false if @record.archived?

    @user.role?(Role::AGE_GROUP_AVAILABLE_MEMBERS, @record) && !record.training_only
  end

  def show_status?
    return false if @record.status == @record.season.status

    @user.role?(Role::STATUS_DRAFT) || @user.indirect_role?(Role::STATUS_DRAFT)
  end

  def show_member_count?
    return false if @record.season.archived?

    @user.role?(Role::AGE_GROUP_SHOW_MEMBER_COUNT, @record)
  end

  def show_alert?
    return false if @record.archived?

    @user.role?(Role::TEAM_MEMBER_ALERT, @record)
  end

  def set_status?
    return false if @record.new_record? || !@record.season.active?

    @user.role?(Role::AGE_GROUP_SET_STATUS, @record)
  end

  def team_actions?
    @user.role?(Role::AGE_GROUP_TEAM_ACTIONS, @record)
  end

  def download_team_members?
    team_actions?
  end

  def bulk_email?
    team_actions?
  end

  def modify_members?
    return false if @record.new_record? || @record.archived?

    # Don't allow coordinators to create members with a second parameter to the `role?` call
    @user.role?(Role::BEHEER_GROUPS) || @user.role?(Role::GROUP_MEMB_CREATE)
  end

  def add_members?
    # Only admin can add more than 1 group member per AgeGroup
    modify_members? && (@record.group_members.blank? || @user.admin?)
  end

  def permitted_attributes
    attributes = [:name, :year_of_birth_from, :year_of_birth_to, :gender, :players_per_team, :minutes_per_half,
      :training_only]
    attributes << :status if set_status?
    attributes
  end

  class Scope < Scope
    def resolve
      if @user.role?(Role::STATUS_DRAFT) || @user.indirect_role?(Role::STATUS_DRAFT)
        scope
      else
        scope.active_or_archived
      end
    end
  end
end
