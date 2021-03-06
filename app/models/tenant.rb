# == Schema Information
#
# Table name: tenants
#
#  id         :bigint           not null, primary key
#  domain     :string
#  host       :string
#  name       :string
#  status     :integer          default("active")
#  subdomain  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Tenant < ApplicationRecord
  include Statussable

  has_one :tenant_setting, dependent: :destroy
  has_many :seasons, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :members, dependent: :destroy

  def settings
    # Auto-create tenant_setting
    tenant_setting || create_tenant_setting
  end

  def skip_update?
    ActsAsTenant.with_tenant(self) do
      !active? || Season.active_season_for_today.blank? || Tenant.setting("clubdata_client_id").blank?
    end
  end

  def self.from_request(request)
    tenant = Tenant.find_by(domain: domain(request))
    tenant ||= Tenant.find_by(subdomain: subdomain(request))
    tenant ||= Tenant.find_by(host: request.host)
    tenant
  end

  def self.setting(name)
    return if ActsAsTenant.current_tenant.nil?

    ActsAsTenant.current_tenant.settings.send(clean_up(name))
  end

  def self.set_setting(name, value)
    return if ActsAsTenant.current_tenant.nil?

    ActsAsTenant.current_tenant.tenant_setting.update!(clean_up(name) => value)
  end

  ##
  # Private class methods, should be called with tenant context
  #
  class << self
    private

    def clean_up(name)
      name.gsub(/[-.]/, "_")
    end

    def domain(request)
      request.host.split(".").last(2).join(".").downcase
    end

    def subdomain(request)
      request.host.split(".")[0..-3].last.downcase
    end
  end
end
