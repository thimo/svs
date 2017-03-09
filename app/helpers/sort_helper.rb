module SortHelper
  # Sort array of objects in an human expected way
  def human_sort(objects = [], attribute = "")
    return objects if attribute.blank?
    
    objects.sort_by { |obj| obj[attribute].to_s.split(/(\d+)/).map { |e| [e.to_i, e] } }
  end

end
