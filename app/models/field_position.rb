class FieldPosition < ApplicationRecord
  has_and_belongs_to_many :team_members

  default_scope {order(position: :asc)}

  def self.options_for_select
    all.collect do |pos|
      # name = "#{'- ' if pos.indent_in_select}#{pos.name}"
      name = "#{pos.name}"
      # Hide blank field positions for now
      unless pos.blank?
        id = pos.blank? ? '' : pos.id
        [ name, id ]
      end
    end
  end
end
