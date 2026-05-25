# frozen_string_literal: true

# Returns a paginated, sorted list of one-time tasks and recurring occurrences
# via a single UNION ALL query with SQL-level LIMIT/OFFSET.
class TasksQuery
  PER_PAGE = 25

  # @param params [Hash] filter and pagination parameters
  # @return [Hash] { items: Array, total_count: Integer, page: Integer, per_page: Integer }
  def call(params = {})
    page   = [ (params[:page] || 1).to_i, 1 ].max
    offset = (page - 1) * PER_PAGE

    filters = sanitize_filters(params)

    total_count = count_records(filters)
    rows        = fetch_page(filters, offset)

    { items: build_items(rows), total_count: total_count, page: page, per_page: PER_PAGE }
  end

  private

  # -- Sanitization (single place for all user input) ----------------------

  # @param params [Hash] raw controller parameters
  # @return [Hash] quoted/cast filter values ready for SQL interpolation
  def sanitize_filters(params)
    conn = ActiveRecord::Base.connection
    {
      date_from: params[:date_from].present? ? conn.quote(params[:date_from].to_s) : nil,
      date_to:   params[:date_to].present?   ? conn.quote(params[:date_to].to_s)   : nil,
      statuses:  params[:status].present?    ? Array(params[:status]).map { |s| conn.quote(s) } : nil,
      tag_ids:   Array(params[:tag_ids]).map(&:to_i).presence
    }
  end

  # -- SQL execution -------------------------------------------------------

  # @param filters [Hash] sanitized filter values from {#sanitize_filters}
  # @return [Integer] total number of matching rows (one-time + recurring)
  def count_records(filters)
    sql = "SELECT COUNT(*) FROM (#{build_union(filters)}) AS combined"
    ActiveRecord::Base.connection.select_value(sql).to_i
  end

  # @param filters [Hash] sanitized filter values
  # @param offset [Integer] SQL OFFSET for pagination
  # @return [Array<Hash>] raw rows from the UNION ALL query
  def fetch_page(filters, offset)
    sql = <<~SQL
      #{build_union(filters)}
      ORDER BY due_date ASC, created_at ASC
      LIMIT #{PER_PAGE} OFFSET #{offset}
    SQL
    ActiveRecord::Base.connection.execute(sql).to_a
  end

  # -- UNION ALL -----------------------------------------------------------

  # @param filters [Hash] sanitized filter values
  # @return [String] SQL combining one-time and recurring subqueries via UNION ALL
  def build_union(filters)
    "#{one_time_sql(filters)} UNION ALL #{recurring_sql(filters)}"
  end

  # @param filters [Hash] sanitized filter values
  # @return [String] SELECT for non-recurring tasks with applied filters
  def one_time_sql(filters)
    where = [ "t.recurring = false" ]
    where << "t.due_date >= #{filters[:date_from]}" if filters[:date_from]
    where << "t.due_date <= #{filters[:date_to]}"   if filters[:date_to]
    where << "t.status IN (#{filters[:statuses].join(', ')})" if filters[:statuses]
    append_tag_conditions(where, filters[:tag_ids])

    <<~SQL.squish
      SELECT t.id, t.title, t.description, t.due_date, t.status,
             t.recurring, t.starts_on, t.ends_on, t.created_at, t.updated_at
      FROM tasks t WHERE #{where.join(' AND ')}
    SQL
  end

  # rubocop:disable Metrics/MethodLength

  # @param filters [Hash] sanitized filter values
  # @return [String] SELECT for recurring task occurrences joined with calendar_dates
  def recurring_sql(filters)
    where = [ "t.recurring = true", "COALESCE(tor.cancelled, false) = false" ]
    where << "cd.date >= #{filters[:date_from]}" if filters[:date_from]
    where << "cd.date <= #{filters[:date_to]}"   if filters[:date_to]
    where << "COALESCE(tor.status, t.status) IN (#{filters[:statuses].join(', ')})" if filters[:statuses]
    append_tag_conditions(where, filters[:tag_ids])

    <<~SQL.squish
      SELECT t.id, t.title, t.description, cd.date AS due_date,
             COALESCE(tor.status, t.status) AS status,
             t.recurring, t.starts_on, t.ends_on, t.created_at, t.updated_at
      FROM tasks t
      JOIN recurrence_rules rr ON rr.task_id = t.id
      JOIN calendar_dates cd
        ON cd.date >= t.starts_on
        AND (t.ends_on IS NULL OR cd.date <= t.ends_on)
        AND (
          (rr.rule_type = 'daily' AND (cd.date - t.starts_on) % rr.interval = 0)
          OR (rr.rule_type = 'monthly' AND cd.day_of_month = rr.day_of_month)
          OR (rr.rule_type = 'specific_dates' AND cd.date = ANY(rr.specific_dates))
          OR (rr.rule_type = 'even_odd' AND (
            (rr.even_odd = 'even' AND cd.is_even_day = true)
            OR (rr.even_odd = 'odd' AND cd.is_even_day = false)
          ))
        )
      LEFT JOIN task_occurrences tor
        ON tor.task_id = t.id AND tor.occurrence_date = cd.date
      WHERE #{where.join(' AND ')}
    SQL
  end
  # rubocop:enable Metrics/MethodLength

  # @param where [Array<String>] mutable list of SQL WHERE conditions
  # @param tag_ids [Array<Integer>, nil] tag IDs for AND-filtering
  # @return [void]
  def append_tag_conditions(where, tag_ids)
    return unless tag_ids

    tag_ids.each do |tag_id|
      where << "EXISTS (SELECT 1 FROM task_tags tt WHERE tt.task_id = t.id AND tt.tag_id = #{tag_id})"
    end
  end

  # -- Result building -----------------------------------------------------

  # @param rows [Array<Hash>] raw SQL result rows
  # @return [Array<RecurringOccurrence>] decorated items with preloaded tags and rules
  def build_items(rows)
    return [] if rows.empty?

    task_ids      = rows.map { |r| r["id"] }.uniq
    tags_by_task  = TaskTag.includes(:tag).where(task_id: task_ids)
                          .group_by(&:task_id)
                          .transform_values { |tt| tt.map(&:tag) }
    rules_by_task = RecurrenceRule.where(task_id: task_ids).index_by(&:task_id)

    rows.map do |row|
      RecurringOccurrence.new(
        id: row["id"], title: row["title"], description: row["description"],
        due_date: row["due_date"], status: row["status"], recurring: row["recurring"],
        starts_on: row["starts_on"], ends_on: row["ends_on"],
        created_at: row["created_at"], updated_at: row["updated_at"],
        tags: tags_by_task[row["id"]] || [], recurrence_rule: rules_by_task[row["id"]]
      )
    end
  end
end
