create_table :men, :force => true do |t|
  t.string  :name
end

create_table :faces, :force => true do |t|
  t.string  :description
  t.integer :man_id
end

create_table :interests, :force => true do |t|
  t.string :topic
  t.integer :man_id
  t.integer :zine_id
end

create_table :zines, :force => true do |t|
  t.string :title
end
