# frozen_string_literal: true
module Statussable
  extend ActiveSupport::Concern

  included do
    enum status: { draft: 0, active: 1, archived: 2 }
  end

  def status_to_label
    title = ended_on.present? ? "Per #{I18n.l(ended_on, format: :long)}" : ""
    "<span class=\"label #{color_class_for_status}\" title=\"#{title}\">#{status_i18n}</span>"
  end

  def transmit_status(new_status, old_status = nil)
    return if new_status == old_status

    update(status: self.class.statuses[new_status]) if status != new_status
    unless self.class == Season
      update(ended_on: Time.zone.today) if user_invoked_archivation?(old_status)
      update(ended_on: nil) if unarchived_with_end_date?
    end

    transmit_status_to_children(new_status) if respond_to? :status_children
  end

  def color_class_for_status
    return "label-warning" if draft?
    return "label-success" if active?
    return "label-light-grey" if archived?
  end

  def to_archive
    update(status: self.class.statuses[:archived]) unless archived?
  end

  def deactivate
    to_archive
  end

  def activate
    update(status: :active) unless active?
  end

  private

    def transmit_status_to_children(new_status)
      status_children.each do |child|
        child.transmit_status(new_status) unless child.archived? && child.ended_on.present?
      end
    end

    def user_invoked_archivation?(old_status)
      old_status.present? && archived?
    end

    def unarchived_with_end_date?
      (draft? || active?) && ended_on.present?
    end

    module ClassMethods
    end
end
