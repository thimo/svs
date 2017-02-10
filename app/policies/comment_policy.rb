class CommentPolicy < ApplicationPolicy
  def show?
    false
  end

  def show_generic?
    true
  end

  def show_technique?
    @user.admin? || @user.club_staff?
  end

  def show_behaviour?
    @user.admin? || @user.club_staff?
  end

  def show_classification?
    @user.admin? || @user.club_staff?
  end

  def show_membership?
    @user.admin? || @user.club_staff?
  end

  def create?
    true
  end

  def update?
    @user.admin? || @record.user = @user
  end

  def destroy?
    @user.admin? || @record.user = @user
  end

  class Scope < Scope
    def resolve
      scope # TODO: filter for 'private'
    end
  end
end
