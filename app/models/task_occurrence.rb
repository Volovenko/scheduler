# frozen_string_literal: true

# == Schema Information
#
# Table name: task_occurrences
#
#  id              :bigint           not null, primary key
#  cancelled       :boolean          default(FALSE), not null
#  description     :text
#  occurrence_date :date             not null
#  status          :string
#  title           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  task_id         :bigint           not null
#
# Indexes
#
#  index_task_occurrences_on_task_id                      (task_id)
#  index_task_occurrences_on_task_id_and_occurrence_date  (task_id,occurrence_date) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (task_id => tasks.id)
#
class TaskOccurrence < ApplicationRecord
  belongs_to :task

  validates :occurrence_date, presence: true
  validates :task_id, uniqueness: { scope: :occurrence_date }
  validates :status, inclusion: { in: Task::STATUSES }, allow_nil: true
end
