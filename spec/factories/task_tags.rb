# == Schema Information
#
# Table name: task_tags
#
#  id      :bigint           not null, primary key
#  tag_id  :bigint           not null
#  task_id :bigint           not null
#
# Indexes
#
#  index_task_tags_on_tag_id              (tag_id)
#  index_task_tags_on_task_id             (task_id)
#  index_task_tags_on_task_id_and_tag_id  (task_id,tag_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (tag_id => tags.id)
#  fk_rails_...  (task_id => tasks.id)
#
FactoryBot.define do
  factory :task_tag do
    task
    tag
  end
end
