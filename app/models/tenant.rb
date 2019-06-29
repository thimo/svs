# frozen_string_literal: true

class Tenant < ApplicationRecord
  include RailsSettings::Extend
  include Statussable

  has_one :tenant_setting, dependent: :destroy

  # TODO: Enable after cached settings have been removed
  # def settings
  #   # Auto-create tenant_setting
  #   tenant_setting || create_tenant_setting
  # end

  def self.from_request(request)
    host_parts = request.host.split(".")
    domain = host_parts.last(2).join(".")
    subdomains = host_parts[0..-3]

    tenant = Tenant.find_by(domain: domain.downcase)
    tenant ||= Tenant.find_by(subdomain: subdomains.last.downcase) if subdomains.any?
    tenant
  end

  def self.setting(name)
    Setting.for_current_tenant(var: name).value
  end

  def self.set_setting(name, value)
    Setting.for_current_tenant(var: name).update(value: value)
  end
end
