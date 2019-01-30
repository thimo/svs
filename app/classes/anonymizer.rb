# frozen_string_literal: true

class Anonymizer
  def self.convert_for_demo
    raise "This method may only be run in the demo environment" if Rails.env != "demo"

    convert_demo_tenant
    old_club_name = Tenant.setting("club.name_short")
    update_settings
    update_matches(old_club_name)
    update_competitions(old_club_name)
    convert_members
  end

  class << self
    private

      def demo_tenant
        Tenant.find(1)
      end

      def convert_demo_tenant
        demo_tenant.update(
          domain: "localhost",
          name: "Demo",
          subdomain: "demo"
        )
      end

      def update_settings
        ActsAsTenant.with_tenant(demo_tenant) do
          Tenant.set_setting("application.hostname", "localhost:3001")
          Tenant.set_setting("application.email", "thimo@teamplanpro.nl")
          Tenant.set_setting("application.favicon_url",
                             "https://s3.eu-central-1.amazonaws.com/teamplan/demo/favicon.ico")
          Tenant.set_setting("application.email", "thimo@teamplanpro.nl")
          club_name = "FC Demo"
          Tenant.set_setting("club.name", club_name)
          old_club_name = Tenant.setting("club.name_short")
          Tenant.set_setting("club.name_short", club_name)
          Tenant.set_setting("club.website", "https://www.teamplanpro.nl/")
          Tenant.set_setting("club.sportscenter", "Sportcentrum Demorijk")
          street = Faker::Address.street_name
          house_number = Faker::Address.building_number
          Tenant.set_setting("club.address", "#{street} #{house_number}")
          Tenant.set_setting("club.zip", Faker::Address.zip)
          Tenant.set_setting("club.city", Faker::Address.city)
          Tenant.set_setting("club.logo_url", "https://s3.eu-central-1.amazonaws.com/teamplan/demo/FC+Demo+logo.svg")
        end
      end

      def update_matches(old_club_name)
        Match.all.each do |match|
          match.thuisteam = match.thuisteam.sub(/^#{old_club_name} /, "#{club_name} ")
          match.uitteam = match.uitteam.sub(/^#{old_club_name} /, "#{club_name} ")
          if match.wedstrijd.present?
            match.wedstrijd = match.wedstrijd.sub(/^#{old_club_name} /, "#{club_name} ")
            match.wedstrijd = match.wedstrijd.sub(/- #{old_club_name} /, "- #{club_name} ")
          end

          match.save if match.changed?
        end
      end

      def update_competitions(old_club_name)
        Competition.all.each do |competition|
          next if competition.ranking.blank? || !competition.ranking.is_a?(Array)

          competition.ranking.each do |ranking|
            ranking["teamnaam"] = ranking["teamnaam"].sub(/^#{old_club_name} /, "#{club_name} ")
          end

          competition.save if competition.changed?
        end
      end

      def convert_members
        ActsAsTenant.with_tenant(demo_tenant) do
          Member.all.each do |member|
            first_name = member.gender == "V" ? Faker::Name.female_first_name : Faker::Name.male_first_name
            member.first_name = first_name
            member.middle_name = Faker::Name.middle_name if member.middle_name.present?
            member.last_name = Faker::Name.last_name
            member.born_on = Faker::Date.between(member.born_on.beginning_of_year, member.born_on.end_of_year)
            street = Faker::Address.street_name
            house_number = Faker::Address.building_number
            member.address = "#{street} #{house_number}"
            member.street = street
            member.house_number = house_number
            member.zipcode = Faker::Address.zip
            member.city = Faker::Address.city
            member.phone = Faker::PhoneNumber.phone_number          if member.phone.present?
            member.phone2 = Faker::PhoneNumber.phone_number         if member.phone2.present?
            member.phone_home = Faker::PhoneNumber.phone_number     if member.phone_home.present?
            member.phone_parent = Faker::PhoneNumber.phone_number   if member.phone_parent.present?
            member.phone_parent_2 = Faker::PhoneNumber.phone_number if member.phone_parent_2.present?

            # TODO: keep mail addresses consitent between Users and families
            # member.email = Faker::Internet.email          if member.email.present?
            # member.email_2 = Faker::Internet.email        if member.email_2.present?
            # member.email_parent = Faker::Internet.email   if member.email_parent.present?
            # member.email_parent_2 = Faker::Internet.email if member.email_parent_2.present?

            member.association_number = Faker::Code.nric if member.association_number.present?
            member.initials = Faker::Name.initials if member.initials.present?
            member.conduct_number = Faker::Code.asin if member.conduct_number.present?
            member.full_name = "#{member.last_name}, #{member.first_name} #{member.middle_name}"
            member.full_name_2 = "#{member.first_name} #{member.middle_name} #{member.last_name}"
            # - photo ??

            member.save
          end
        end
      end
  end
end