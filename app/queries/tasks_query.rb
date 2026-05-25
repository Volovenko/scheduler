# frozen_string_literal: true

# Returns a merged, sorted Array of one-time Task records and recurring
# RecurringOccurrence value objects for use with pagy_array.
#
# One-time tasks are filtered by due_date; recurring occurrences are delegated
# to RecurringTasksQuery which uses a SQL JOIN over calendar_dates.
#
# Both sets share the same filter keys (date_from, date_to, status, tag_ids).
class TasksQuery
  # @param params [Hash] filter parameters
  # @option params [String, Date] :date_from lower bound for due_date (inclusive)
  # @option params [String, Date] :date_to   upper bound for due_date (inclusive)
  # @option params [Array<String>] :status   array of status values to include
  # @option params [Array<Integer>] :tag_ids tasks must have ALL given tags
  # @return [Array<Task, RecurringOccurrence>] sorted by due_date asc, created_at asc
  def call(params = {})
    one_time  = one_time_tasks(params).to_a
    recurring = RecurringTasksQuery.new.call(params)

    (one_time + recurring).sort_by { |t| [t.due_date || Date::INFINITY, t.created_at] }
  end

  private

  def one_time_tasks(params)
    scope = Task.one_time.includes(:tags, :recurrence_rule)
    scope = filter_by_date_from(scope, params[:date_from])
    scope = filter_by_date_to(scope, params[:date_to])
    scope = filter_by_statuses(scope, params[:status])
    scope = filter_by_tag_ids(scope, params[:tag_ids])
    scope
  end

  def filter_by_date_from(scope, date_from)
    return scope if date_from.blank?

    scope.where("due_date >= ?", date_from)
  end

  def filter_by_date_to(scope, date_to)
    return scope if date_to.blank?

    scope.where("due_date <= ?", date_to)
  end

  def filter_by_statuses(scope, statuses)
    return scope if statuses.blank?

    scope.where(status: Array(statuses))
  end

  def filter_by_tag_ids(scope, tag_ids)
    return scope if tag_ids.blank?

    Array(tag_ids).map(&:to_i).each do |tag_id|
      scope = scope.where(id: TaskTag.select(:task_id).where(tag_id: tag_id))
    end
    scope
  end
end
