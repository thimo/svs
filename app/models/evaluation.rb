class Evaluation < ApplicationRecord
  RATING_OPTIONS = [["goed", "8"], ["voldoende", "6"], ["matig", "5"], ["onvoldoende", "4"]]
  FIELD_POSITION_OPTIONS = {
      "Aanval" => ["linksbuiten", "spits", "rechtsbuiten"],
      "Middenveld" => ["linkshalf", "centrale middenvelder", "rechtshalf"],
      "Verdediging" => ["linksachter", "voorstopper", "rechtsachter", "laatste man", "keeper"],
      "As" => ["linker as", "centrale as", "rechter as"],
      "Linie" => ["aanvaller", "middenvelder", "verdediger"],
    }
  PREFERED_FOOT_OPTIONS = %w(linksbenig rechtsbenig tweebenig)
  ADVISE_NEXT_SEASON_OPTIONS = %w(hoger zelfde lager)

  belongs_to :team_evaluation, required: true
  belongs_to :member, required: true

  default_scope -> {joins(:member).order('members.last_name ASC, members.first_name ASC') }

  def draft?
    team_evaluation.draft?
  end

  def active?
    team_evaluation.active?
  end

  def archived?
    team_evaluation.archived?
  end
end
