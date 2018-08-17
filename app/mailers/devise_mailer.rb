# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  include DefaultUrlOptions
  # helper :application # gives access to all helpers defined within `application_helper`.
  # include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  # default template_path: 'devise/mailer' # to make sure that your mailer uses the devise views
  default from: "\"#{Setting['club.name_short']} #{Setting['application.name']}\" <#{Setting['club.email']}>"
end