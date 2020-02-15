# frozen_string_literal: true

module ClubdataScheduler
  class PoulesJob < Que::Job
    include ClubdataJob

    def run
      Tenant.active.find_each do |tenant|
        next if tenant.skip_update?

        ActsAsTenant.with_tenant(tenant) do
          Season.active_season_for_today.competitions.active.each do |competition|
            ClubdataImporter::PouleStandingJob.enqueue(tenant_id: ActsAsTenant.current_tenant, competition_id: competition.id)
            ClubdataImporter::PouleMatchesJob.enqueue(tenant_id: ActsAsTenant.current_tenant, competition_id: competition.id)
            ClubdataImporter::PouleResultsJob.enqueue(tenant_id: ActsAsTenant.current_tenant, competition_id: competition.id)
          end
        end
      end
    end
  end
end
