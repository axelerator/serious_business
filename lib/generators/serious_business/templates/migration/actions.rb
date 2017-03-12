class CreateSeriousBusiness < <%= migration_class_name %>
  def change
    create_table :serious_actions do |t|
      t.string :type, null: false
      t.integer :actor_id
      t.timestamps null: false
    end

    create_table :serious_affecteds do |t|
      t.references :serious_action, foreign_key: true, null: false
      t.integer :affected_id, null: false
      t.string :affected_type
    end

  end
end
