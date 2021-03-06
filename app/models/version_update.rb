# == Schema Information
#
# Table name: version_updates
#
#  id          :bigint           not null, primary key
#  body        :text
#  for_role    :integer          default("member")
#  name        :string
#  released_at :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class VersionUpdate < ApplicationRecord
  validates :released_at, :name, :body, presence: true

  has_paper_trail

  enum for_role: {member: 0, admin: 1}

  scope :desc, -> { order(released_at: :desc) }
end
