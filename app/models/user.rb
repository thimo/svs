# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :inet
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  first_name             :string
#  last_name              :string
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :inet
#  middle_name            :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :integer          default("member")
#  sign_in_count          :integer          default(0), not null
#  status                 :integer          default("active")
#  unconfirmed_email      :string
#  uuid                   :uuid
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  tenant_id              :bigint
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_tenant_id             (tenant_id)
#  index_users_on_tenant_id_and_email   (tenant_id,email) UNIQUE
#  index_users_on_uuid                  (uuid)
#
class User < ApplicationRecord
  include Filterable
  include Statussable

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # Removed :validatable for compatability with acts_as_tenant
  devise :registerable, :confirmable, :database_authenticatable, :recoverable, :rememberable, :trackable

  acts_as_tenant :tenant
  has_many :favorites, dependent: :destroy
  has_many :email_logs, dependent: :destroy
  has_many :logs, dependent: :destroy
  has_many :todos, dependent: :destroy
  has_many :injuries, dependent: :destroy
  has_many :user_settings, dependent: :destroy
  has_and_belongs_to_many :members
  has_many :group_members, -> { active }, through: :members
  has_many :all_groups, through: :group_members, source: :group
  has_many :direct_groups, -> { where(group_members: {memberable_type: nil, memberable_id: nil}).active },
    through: :group_members,
    source: :group
  has_many :direct_roles, through: :direct_groups, source: :roles

  has_many :indirect_groups, -> { where.not(group_members: {memberable_type: nil, memberable_id: nil}) },
    through: :group_members,
    source: :group
  has_many :indirect_roles, through: :indirect_groups, source: :roles

  has_paper_trail

  validates :email, presence: true, format: Devise.email_regexp
  validates_uniqueness_to_tenant :email
  validates :password, presence: true, length: {in: 6..30}, if: :password_required?

  enum role: {member: 0, admin: 1}

  scope :asc, -> { order(last_name: :asc, first_name: :asc) }
  scope :role, ->(role) { where(role: role) }
  scope :query, ->(query) {
    where("email ILIKE ? OR first_name ILIKE ? OR last_name ILIKE ?", "%#{query}%", "%#{query}%", "%#{query}%")
  }
  scope :by_email, ->(email) { where("lower(email) = ?", email.downcase) }

  after_save :update_members

  # Setter
  def name=(name)
    split = name.split(" ", 2)
    self.first_name = split.first
    self.last_name = split.last
  end

  def name
    if first_name.blank? && last_name.blank?
      email
    else
      "#{first_name} #{middle_name} #{last_name}".squish
    end
  end

  def email_with_name
    if name == email
      email
    else
      %("#{name}" <#{email}>)
    end
  end

  def teams
    Team.for_members(members).distinct
  end

  def active_teams
    Team.for_members(members).active.for_active_season.distinct
  end

  def active_teams_as_staff
    Team.for_members(members).active.as_not_player.for_active_season.distinct
  end

  def active_teams_as_group_member
    Team.for_group_members(members).active.for_active_season.distinct
  end

  def active_age_groups
    AgeGroup.for_group_members(members).active.for_active_season.distinct
  end

  def teams_as_staff
    Team.for_members(members).as_not_player.distinct
  end

  def teams_as_staff_in_season(season)
    Team.for_members(members).as_not_player.for_season(season).distinct
  end

  def members_as_active_staff
    team_ids = active_teams_as_staff.pluck(:id)
    Member.by_team(team_ids)
  end

  # NOTE: can't rename this to `member?` because of conflict with enum role
  def has_member?(member)
    members.where(id: member.id).size.positive?
  end

  def team_member_for?(record)
    team_id = team_id_for(record)
    members.by_team(team_id).size.positive?
  end

  def team_staff_for?(record)
    team_id = team_id_for(record, false)
    members.by_team(team_id).team_staff.size.positive?
  end

  def favorite_teams
    @favorite_teams ||= Team.joins(:favorites)
      .where(favorites: {user_id: id, favorable_type: Team.to_s})
      .active
  end

  def favorite_age_groups
    @favorite_age_groups ||= AgeGroup.joins(:favorites)
      .where(favorites: {user_id: id, favorable_type: AgeGroup.to_s})
      .active
  end

  def favorite?(member)
    @favorite_members ||= favorites.where(favorable_type: Member.to_s).pluck(:id)
    @favorite_members.include?(member.id)
  end

  def set_new_password
    self.password = User.password
  end

  def self.password
    Password.pronounceable(8) + rand(100).to_s
  end

  def send_new_account(password)
    # Don't use `deliver_later`, does not seem to work correctly yet
    UserMailer.new_account_notification(self, password).deliver_now
  end

  def send_password_reset(password)
    # Don't use `deliver_later`, does not seem to work correctly yet
    UserMailer.password_reset(self, password).deliver_now
  end

  def prefill(member)
    self.first_name = member.first_name
    self.middle_name = member.middle_name
    self.last_name = member.last_name
    self.email = member.email
  end

  def setting(name)
    settings[name].presence || UserSetting.default_for(name)
  end

  def set_setting(name, value)
    @settings = nil
    user_settings.find_or_initialize_by(name: name).update!(value: value)
  end

  def export_columns
    @export_columns ||= setting(:export_columns)
  end

  def remember_me
    true
  end

  def active_for_authentication?
    super && (members.any? || admin?) && tenant.active?
  end

  def inactive_message
    if tenant.draft? || tenant.archived?
      "#{Tenant.setting("application_name")} is op dit moment niet geactiveerd voor \
      #{Tenant.setting("club_name_short")}. Probeer het later nog een keer of neem contact op met de beheerder."
    elsif !confirmed?
      "Je e-mailadres is nog niet bevestigd. Klik op de link \
      \"#{I18n.t("devise.shared.links.didn_t_receive_confirmation_instructions")}\" hieronder om een nieuwe \
      bevestiging aan te vragen."
    else
      "Met dit account is het helaas niet mogelijk om in te loggen. Ga alsjeblieft zelf na of het e-mailadres dat \
      je gebruikt wel is gekoppeld aan een lidmaatschap in de ledenadministratie van \
      #{Tenant.setting("club_name_short")}."
    end
  end

  def toggle_include_member_comments
    set_setting(:include_member_comments, !setting(:include_member_comments))
  end

  def active_comments_tab=(tab)
    set_setting(:active_comments_tab, tab) if tab.present?
  end

  def after_confirmation
    update_members
  end

  # Run on `after_save` because on `before_save` the email may be changed, but not yet
  # updated because of Devise's :confirmable (see `after_confirmation` above)
  def update_members
    self.members = Member.by_email(email).active

    if members.any?
      activate
    else
      deactivate
    end
  end

  def any_beheer_role?
    admin? || direct_role_names.any? { |role| role.start_with?("beheer_") }
  end

  def role?(role, record = nil)
    admin? || direct_role_names.include?(role.to_s) || indirect_role_names_for(record).include?(role.to_s)
  end

  def indirect_role?(role)
    admin? || indirect_role_names.include?(role.to_s)
  end

  def show_evaluations?
    admin? || role?(Role::MEMBER_SHOW_EVALUATIONS) || indirect_role?(Role::MEMBER_SHOW_EVALUATIONS)
  end

  def self.find_or_create_and_invite(member)
    user = User.where(email: member.email).first_or_initialize(
      password: (generated_password = User.password),
      first_name: member.first_name, middle_name: member.middle_name, last_name: member.last_name
    )

    if user.new_record?
      user.skip_confirmation!
      user.save!
      user.send_new_account(generated_password)
    end

    user
  end

  def self.deactivate_for_inactive_members
    User.active.each(&:update_members)
  end

  def self.activate_for_active_members
    User.archived.each(&:update_members)
  end

  def members?
    members.any?
  end

  def remove_member(member)
    members.delete(member)
    deactivate if members.none?
  end

  private

  def team_id_for(record, as_team_staf = false)
    @team_id_for ||= {}
    key = [record, as_team_staf]
    @team_id_for[key] ||= case [record.class]
                          when [Team]
                            record.id
                          when [Member]
                            # Find overlap in teams between current user and given member
                            team_members = as_team_staf ? record.team_members.staff : record.team_members
                            team_members = team_members.active if member?
                            team_members.pluck(:team_id).uniq
                          when [PlayerEvaluation]
                            record.team_evaluation.team_id
                          when [TeamMember], [TeamEvaluation], [Note], [TrainingSchedule], [Training]
                            record.team_id
                          when [Comment]
                            if record.commentable_type == "Team"
                              record.commentable_id
                            elsif record.commentable_type == "Member"
                              record.commentable.active_team&.id
                            else
                              0
                            end
                          when [Presence]
                            if record.presentable_type == "Match"
                              record.presentable.teams.pluck(:id)
                            else
                              record.presentable.team_id
                            end
                          when [Match]
                            record.persisted? ? record.teams.pluck(:id) : record.teams.map(&:id)
                          else
                            0
    end
  end

  def age_group_id_for(record)
    @age_group_id_for ||= {}
    @age_group_id_for[record] ||= case [record.class]
                                  when [AgeGroup]
                                    record.id
                                  when [Team]
                                    record.age_group_id # Included here to make sure it works for new Team objects
                                  else
                                    ids = AgeGroup.draft_or_active.by_team(team_id_for(record)).pluck(:id)
                                    ids = record.suggested_age_groups.pluck(:id) if ids.blank? && record.is_a?(Member)
                                    ids
    end
  end

  def direct_role_names
    @direct_role_names ||= direct_roles.distinct.pluck(:name)
  end

  # All role names from indirect groups, should only be used on special occasions. Preferred
  # way is through `indirect_role_names_for(record)``
  def indirect_role_names
    @indirect_role_names ||= indirect_roles.distinct.pluck(:name)
  end

  def indirect_role_names_for(record)
    return [] if record.nil?

    @indirect_role_names_for ||= {}
    @indirect_role_names_for[record] ||= indirect_roles_for(record).distinct.pluck(:name)
  end

  def indirect_roles_for(record)
    age_group_id = age_group_id_for(record)
    team_id = team_id_for(record)
    groups = (Group.for_member(members).for_memberable("AgeGroup", age_group_id) +
               Group.for_member(members).for_memberable("Team", team_id)).compact
    Role.by_group(groups)
  end

  # Copied from validatable module
  def password_required?
    new_record? || password.blank? || password_confirmation.blank?
  end

  def settings
    @settings ||= user_settings.each_with_object({}.with_indifferent_access) { |setting, hash|
      hash[setting.name] = setting.value
    }
  end
end
