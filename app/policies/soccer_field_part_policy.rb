class SoccerFieldPartPolicy < AdminPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end
end
