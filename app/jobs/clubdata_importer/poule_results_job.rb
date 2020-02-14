# frozen_string_literal: true

module ClubdataImporter
  class PouleResultsJob < ApplicationJob
    include ClubdataJob
    queue_as :default

    def perform(tenant_id:, competition_id:)
      ActsAsTenant.current_tenant = Tenant.find(tenant_id)
      competition = Competition.find(competition_id)

      url = "#{Tenant.setting('clubdata_urls_pouleuitslagen')}&poulecode=#{competition.poulecode}" \
            "&client_id=#{Tenant.setting('clubdata_client_id')}"
      json = JSON.parse(RestClient.get(url))
      json.each do |data|
        match = update_match(data, competition)
        match.set_uitslag(data["uitslag"])

        if match.new_record?
          match.save!
        elsif match.changed?
          match.save!
        end
      end
    rescue RestClient::BadRequest => e
      handle_bad_request(:poule_results_import, competition, e)
    end
  end
end