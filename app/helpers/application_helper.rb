module ApplicationHelper
  # Returns the full title on a per-page basis.
  def full_title(page_title = '')
    base_title = "#{Setting['application.name']} · #{Setting['club.name']}"
    if page_title.empty?
      base_title
    else
      page_title + ' | ' + base_title
    end
  end

  def pnotify_type(message_type)
    case message_type
    when "success", "notice"
      "success"
    when "alert", "warning"
      "notice"
    when "danger", "error"
      "error"
    else
      "info"
    end
  end

  def pnotify_duration(message_type)
    case message_type
    when "success", "notice"
      4000
    when "alert", "warning"
      8000
    when "danger", "error"
      8000
    else
      4000
    end
  end

  def errors_for(model, attribute)
    html_builder = lambda {|error_message| "<div class='form-text text-muted'>#{model.class.human_attribute_name(attribute)} #{error_message}</div>" }
    model.errors[attribute].map { |error_message|  html_builder.call(error_message) }.join(' ').html_safe
  end

  def has_error(model, attribute)
    not model.errors[attribute].blank?
  end

  def avatar_url(user)
    # default_url = "#{root_url}startui/img/avatar-2-32.png"
    default_url = "svs.defrog.nl/startui/img/avatar-2-32.png"
    gravatar_id = Digest::MD5.hexdigest(user.email.downcase)
    "https://gravatar.com/avatar/#{gravatar_id}.png?s=48&d=#{CGI.escape(default_url)}"
  end

  def markdown(content)
    @markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, space_after_headers: true, fenced_code_blocks: true)
    @markdown.render(content)
  end

  def true?(obj)
    obj.to_s == "true"
  end

  def replace_param_in_request_path(params)
    uri = URI.parse(request.path)
    query = Rack::Utils.parse_query(uri.query).merge(params)
    uri.query = Rack::Utils.build_query(query)
    uri.to_s
  end

  def flash_message(type, text)
    flash[type] ||= []
    flash[type] << text
  end
end
