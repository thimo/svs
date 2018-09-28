# frozen_string_literal: true

class PlayBan < ApplicationRecord
  belongs_to :member
  has_many :comments, as: :commentable, dependent: :destroy

  enum play_ban_type: { contribution: 0 }
end
