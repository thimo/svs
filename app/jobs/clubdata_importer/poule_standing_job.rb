# frozen_string_literal: true

module ClubdataImporter
  class PouleStandingJob < ApplicationJob
    include ClubdataJob
    queue_as :default

    def perform(tenant_id:, competition_id:)
      ActsAsTenant.current_tenant = Tenant.find(tenant_id)
      competition = Competition.find(competition_id)

      url = "#{Tenant.setting('clubdata_urls_poulestand')}&poulecode=#{competition.poulecode}" \
            "&client_id=#{Tenant.setting('clubdata_client_id')}"
      json = JSON.parse(RestClient.get(url))
      if json.present?
        competition.ranking = json
        if competition.changed?
          competition.save!
        end
      end
    rescue RestClient::BadRequest => e
      handle_bad_request(:poule_results_import, competition, e)
    end
  end
end