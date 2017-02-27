class TeamPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    index?
  end

  def create?
    return false if @record.archived?

    @user.admin? || @user.club_staff?
  end

  def update?
    create?
  end

  def destroy?
    return false unless @record.draft?

    @user.admin? || @user.club_staff?
  end

  def show_comments?
    @user.admin? ||
    @user.club_staff? ||
    @user.is_team_staff_for?(@record)
  end

  def show_evaluations?
    show_comments?
  end

  def show_favorite?
    true
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
