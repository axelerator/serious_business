class CreateSeriousBusiness < <%= migration_class_name %>
  def change
    create_table :serious_actions<%= ', id: :uuid' if use_uuid %> do |t|
      t.string :type, null: false
      <% if use_uuid %>
      t.uuid :actor_id
      <% else %>
      t.integer :actor_id
      <% end %>
      t.timestamps null: false
    end

    create_table :serious_affecteds do |t|
      t.references :serious_action, foreign_key: true, null: false
      <% if use_uuid %>
      t.uuid :affected_id, null: false
      <% else %>
      t.integer :affected_id, null: false
      <% end %>
      t.string :affected_type
    end

  end
end
