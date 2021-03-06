# == Schema Information
#
# Table name: roles
#
#  id            :bigint           not null, primary key
#  body          :text
#  description   :text
#  name          :string
#  resource_type :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  resource_id   :bigint
#  tenant_id     :bigint
#
# Indexes
#
#  index_roles_on_name_and_resource_type_and_resource_id  (name,resource_type,resource_id)
#  index_roles_on_resource_type_and_resource_id           (resource_type,resource_id)
#  index_roles_on_tenant_id                               (tenant_id)
#

# User roles, handed out through groups
class Role < ApplicationRecord
  acts_as_tenant :tenant
  has_and_belongs_to_many :users, join_table: :users_roles
  has_and_belongs_to_many :groups, join_table: :groups_roles

  AGE_GROUP_ROLES = %w[AGE_GROUP_CREATE AGE_GROUP_UPDATE AGE_GROUP_SHOW_EVALUATIONS AGE_GROUP_SHOW_TODOS
    AGE_GROUP_SHOW_MEMBER_COUNT AGE_GROUP_TEAM_ACTIONS AGE_GROUP_SET_STATUS
    AGE_GROUP_SHOW_INJUREDS AGE_GROUP_AVAILABLE_MEMBERS].freeze
  BEHEER = %w[BEHEER_ROLES BEHEER_GROUPS BEHEER_USERS BEHEER_MEMBERS
    BEHEER_KNVB_CLUB_DATA BEHEER_OEFENWEDSTRIJDEN BEHEER_CONTRIBUTIE_SPEELVERBODEN
    BEHEER_VERSION_UPDATES BEHEER_SETTINGS BEHEER_EMAIL_LOG BEHEER_COMPETITIONS
    BEHEER_SOCCER_FIELDS BEHEER_TEAM_EVALUATION_CONFIGS].freeze
  COMMENT_ROLES = %w[COMMENT_CREATE COMMENT_GENERIC COMMENT_TECHNIQUE COMMENT_BEHAVIOUR COMMENT_CLASSIFICATION
    COMMENT_MEMBERSHIP].freeze
  DASHBOARD_ROLES = %w[DASHBOARD_CEO_CHARTS].freeze
  GROUP_ROLES = %w[GROUP_CREATE GROUP_SHOW].freeze
  GROUP_MEMB_ROLES = %w[GROUP_MEMB_CREATE].freeze
  INJURY_ROLES = %w[INJURY_CREATE].freeze
  MEMBER_ROLES = %w[MEMBER_SHOW_NEW MEMBER_SHOW_PRIVATE_DATA MEMBER_PREVIOUS_TEAM MEMBER_SHOW_EVALUATIONS
    MEMBER_SHOW_FULL_BORN_ON MEMBER_SHOW_SPORTLINK_STATUS MEMBER_SHOW_CONDUCT
    MEMBER_CREATE_EVALUATIONS].freeze
  NOTE_ROLES = %w[NOTE_SHOW NOTE_CREATE].freeze
  ORG_ROLES = %w[ORG_SHOW ORG_MEMBERS_SHOW ORG_LOCAL_TEAMS_SHOW].freeze
  PLAY_BAN_ROLES = %w[PLAY_BAN_SHOW].freeze
  SEASON_ROLES = %w[SEASON_INDEX SEASON_TEAM_ACTIONS SEAON_SET_STATUS].freeze
  STATUS_ROLES = %w[STATUS_DRAFT].freeze
  TEAM_ROLES = %w[TEAM_CREATE TEAM_DESTROY TEAM_SET_STATUS
    TEAM_SHOW_EVALUATIONS TEAM_CREATE_EVALUATIONS TEAM_MEMBER_DOWNLOAD
    TEAM_SHOW_COMMENTS TEAM_SHOW_NOTES TEAM_SHOW_STATISTICS TEAM_SHOW_TODOS].freeze
  TEAM_MEMB_ROLES = %w[TEAM_MEMBER_CREATE TEAM_MEMBER_SET_ROLE TEAM_MEMBER_DESTROY TEAM_MEMBER_SET_STATUS
    TEAM_MEMBER_ALERT].freeze
  TRA_SCHED_ROLES = %w[TRAINING_SCHEDULE_CREATE].freeze
  TRAINING_ROLES = %w[TRAINING_CREATE].freeze
  USER_ROLES = %w[USER_SHOW USER_CREATE USER_EDIT USER_IMPERSONATE].freeze
  KEEPER_ROLES = %w[KEEPER_SHOW].freeze

  ROLES = BEHEER + DASHBOARD_ROLES + TEAM_ROLES + MEMBER_ROLES + AGE_GROUP_ROLES + SEASON_ROLES + COMMENT_ROLES +
    STATUS_ROLES + TEAM_MEMB_ROLES + PLAY_BAN_ROLES + INJURY_ROLES + TRAINING_ROLES + TRA_SCHED_ROLES +
    NOTE_ROLES + USER_ROLES + ORG_ROLES + GROUP_ROLES + GROUP_MEMB_ROLES + KEEPER_ROLES
  ROLES.each do |role|
    const_set(role.upcase, role.downcase.to_sym)
  end

  validates :name, presence: true

  scope :by_group, ->(group) { joins(:groups).where(groups: {id: group}) }
  scope :asc, -> { order(name: :asc) }

  def self.create_all
    Tenant.active.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        ROLES.each do |role|
          Role.find_or_create_by(name: role.downcase)
        end
      end
    end
  end

  def self.create_all_for_active_tenants
    Tenant.active.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        create_all
      end
    end
  end
end
