class AddStatusCheckConstraints < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :tasks, "status IN ('pending', 'in_progress', 'completed', 'cancelled')",
                         name: "chk_tasks_status"

    add_check_constraint :task_occurrences, "status IS NULL OR status IN ('pending', 'in_progress', 'completed', 'cancelled')",
                         name: "chk_task_occurrences_status"
  end
end
