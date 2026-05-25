# Системные теги — создаются один раз, защищены от изменения и удаления через API.
Tag::SYSTEM_NAMES.each do |name|
  Tag.find_or_create_by!(name: name) { |t| t.system = true }
end

puts "System tags seeded: #{Tag::SYSTEM_NAMES.join(', ')}"
