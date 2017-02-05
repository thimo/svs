class AgeGroupPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    @user.role_admin?
  end

  def update?
    @user.role_admin?
  end

  def destroy?
    @user.role_admin?
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
