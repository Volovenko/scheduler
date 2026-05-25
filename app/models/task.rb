# frozen_string_literal: true

# == Schema Information
#
# Table name: tasks
#
#  id          :bigint           not null, primary key
#  description :text
#  due_date    :date
#  ends_on     :date
#  recurring   :boolean          default(FALSE), not null
#  starts_on   :date
#  status      :string           default("pending"), not null
#  title       :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_tasks_on_due_date  (due_date)
#  index_tasks_on_status    (status)
#
class Task < ApplicationRecord
  STATUSES = %w[pending in_progress completed cancelled].freeze

  has_many :task_tags, dependent: :destroy
  has_many :tags, through: :task_tags
  has_one  :recurrence_rule, dependent: :destroy
  has_many :task_occurrences, dependent: :destroy

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :status, inclusion: { in: STATUSES }
  validates :due_date, presence: true, unless: :recurring?
  validates :starts_on, presence: true, if: :recurring?
  validate :ends_on_after_starts_on, if: -> { recurring? && ends_on.present? }

  # Scopes
  scope :by_status, ->(statuses) { where(status: statuses) }
  scope :by_date_range, ->(from, to) { where(due_date: from..to) }
  scope :one_time, -> { where(recurring: false) }
  scope :recurring, -> { where(recurring: true) }

  private

  def ends_on_after_starts_on
    return if ends_on > starts_on

    errors.add(:ends_on, :must_be_after_starts_on, message: "must be after starts_on")
  end
end
