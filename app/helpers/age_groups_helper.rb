module AgeGroupsHelper
  def year_of_birth_range(age_group)
    range = ""
    unless age_group.year_of_birth_from.nil? && age_group.year_of_birth_to.nil?
      if age_group.year_of_birth_from.nil?
        range += "tot "
      else
        range += "#{age_group.year_of_birth_from}"
      end
      unless age_group.year_of_birth_from.nil? || age_group.year_of_birth_to.nil?
        range += " - "
      end
      if age_group.year_of_birth_to.nil?
        range += " en ouder"
      else
        range += "#{age_group.year_of_birth_to}"
      end
    end
    return range
  end
end
