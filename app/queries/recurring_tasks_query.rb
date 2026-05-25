# frozen_string_literal: true

# Computes recurring task occurrences via a SQL JOIN:
#   tasks → recurrence_rules → calendar_dates → (LEFT JOIN) task_occurrences
#
# Returns an Array of RecurringOccurrence value objects (not AR relations).
# Occurrences whose task_occurrence row has cancelled=true are excluded.
# The due_date field is set to the occurrence date (calendar_dates.date).
#
# Rule types and their SQL conditions:
#   daily          → (cd.date - t.starts_on) % rr.interval = 0
#   monthly        → cd.day_of_month = rr.day_of_month
#   specific_dates → cd.date = ANY(rr.specific_dates)
#   even_odd       → cd.is_even_day matches rr.even_odd
class RecurringTasksQuery
  # @param params [Hash] filter parameters (same keys as TasksQuery)
  # @return [Array<RecurringOccurrence>]
  def call(params = {})
    rows = run_query(params)
    build_occurrences(rows)
  end

  private

  def run_query(params)
    ActiveRecord::Base.connection.execute(build_sql(params))
  end

  # rubocop:disable Metrics/MethodLength
  def build_sql(params)
    conn = ActiveRecord::Base.connection

    extra = []

    if params[:date_from].present?
      extra << "cd.date >= #{conn.quote(params[:date_from].to_s)}"
    end
    if params[:date_to].present?
      extra << "cd.date <= #{conn.quote(params[:date_to].to_s)}"
    end
    if params[:status].present?
      quoted = Array(params[:status]).map { |s| conn.quote(s) }.join(", ")
      extra << "COALESCE(tor.status, t.status) IN (#{quoted})"
    end
    Array(params[:tag_ids]).map(&:to_i).each do |tag_id|
      extra << "EXISTS (SELECT 1 FROM task_tags tt WHERE tt.task_id = t.id AND tt.tag_id = #{tag_id})"
    end

    where_extra = extra.any? ? "\n      AND #{extra.join("\n      AND ")}" : ""

    <<~SQL
      SELECT
        t.id,
        t.title,
        t.description,
        cd.date          AS due_date,
        COALESCE(tor.status, t.status) AS status,
        t.recurring,
        t.starts_on,
        t.ends_on,
        t.created_at,
        t.updated_at
      FROM tasks t
      JOIN recurrence_rules rr ON rr.task_id = t.id
      JOIN calendar_dates cd
        ON cd.date >= t.starts_on
        AND (t.ends_on IS NULL OR cd.date <= t.ends_on)
        AND (
            (rr.rule_type = 'daily'
              AND (cd.date - t.starts_on) % rr.interval = 0)
            OR
            (rr.rule_type = 'monthly'
              AND cd.day_of_month = rr.day_of_month)
            OR
            (rr.rule_type = 'specific_dates'
              AND cd.date = ANY(rr.specific_dates))
            OR
            (rr.rule_type = 'even_odd' AND (
                (rr.even_odd = 'even' AND cd.is_even_day = true)
                OR (rr.even_odd = 'odd'  AND cd.is_even_day = false)
            ))
        )
      LEFT JOIN task_occurrences tor
        ON tor.task_id = t.id AND tor.occurrence_date = cd.date
      WHERE t.recurring = true
        AND COALESCE(tor.cancelled, false) = false
        #{where_extra}
      ORDER BY cd.date ASC, t.created_at ASC
    SQL
  end
  # rubocop:enable Metrics/MethodLength

  def build_occurrences(rows)
    rows_arr = rows.to_a
    return [] if rows_arr.empty?

    task_ids      = rows_arr.map { |r| r["id"] }.uniq
    tags_by_task  = load_tags(task_ids)
    rules_by_task = load_rules(task_ids)

    rows_arr.map do |row|
      # The pg adapter auto-casts columns: date→Date, timestamp→Time, bool→true/false.
      # Integer PK is returned as Integer by pg.
      RecurringOccurrence.new(
        id:              row["id"],
        title:           row["title"],
        description:     row["description"],
        due_date:        row["due_date"],
        status:          row["status"],
        recurring:       row["recurring"],
        starts_on:       row["starts_on"],
        ends_on:         row["ends_on"],
        created_at:      row["created_at"],
        updated_at:      row["updated_at"],
        tags:            tags_by_task[row["id"]] || [],
        recurrence_rule: rules_by_task[row["id"]]
      )
    end
  end

  def load_tags(task_ids)
    TaskTag.includes(:tag)
           .where(task_id: task_ids)
           .group_by(&:task_id)
           .transform_values { |tt| tt.map(&:tag) }
  end

  def load_rules(task_ids)
    RecurrenceRule.where(task_id: task_ids).index_by(&:task_id)
  end
end
