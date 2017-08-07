class Training < ApplicationRecord
  include Activatable

  belongs_to :team
  belongs_to :training_schedule
  has_many :presences, as: :presentable, dependent: :destroy

  attr_accessor :start_time, :end_time

  validates_presence_of :started_at, :ended_at, :team_id

  scope :not_modified, -> { where(user_modified: false) }
  scope :from_now,     -> { where('started_at > ?', DateTime.now) }
  scope :this_week,    -> (date) { where('started_at > ?', date.beginning_of_week).where('started_at < ?', date.end_of_week) }
  scope :in_period, -> (start_date, end_date) { where('started_at > ?', start_date).where('started_at < ?', end_date)}

  # Accessors for time aspects of start and end dates
  def start_time
    started_at.to_time if started_at.present?
  end

  def start_time=(time)
    self.started_at = started_at.change(hour: time[4], min: time[5])
  end

  def end_time
    ended_at.to_time if ended_at.present?
  end

  def end_time=(time)
    self.ended_at = started_at.change(hour: time[4], min: time[5])
  end

  def find_or_create_presences
    if presences.empty?
      team.team_members.player.asc.each do |team_member|
        presences.create(member: team_member.member)
      end
    end

    presences
  end
end
