module GoogleMapsHelper
  def google_maps_url(object:, type:, user: nil, zoom: 12)
    base_url = "#{Setting['google.maps.base_url']}#{type}"

    params = {
      key: Setting['google.maps.api-key']
    }
    case type
    when 'place'
      params.merge!(
        q: object.google_maps_address,
        zoom: zoom,
      )
    when 'directions'
      params.merge!(destination: object.google_maps_address)
      if user.present?
        member = user.members.sportlink_active.first
        params.merge!(origin: "#{member.address},#{member.zipcode} #{member.city}") if member.present?
      else
        params.merge!(origin: "#{Setting['club.sportscenter']},#{Setting['club.address']},#{Setting['club.zip']} #{Setting['club.city']}")
      end
    end

    "#{base_url}?#{params.to_param}"
  end
end
