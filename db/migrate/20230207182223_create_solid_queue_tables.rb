class CreateSolidQueueTables < ActiveRecord::Migration[7.0]
  def change
    create_table :solid_queue_jobs do |t|
      t.string :queue_name, null: false
      t.text :arguments

      t.string :active_job_id

      t.integer :priority, default: 0, null: false

      t.datetime :scheduled_at
      t.datetime :finished_at

      t.timestamps

      t.index :active_job_id, name: "index_solid_queue_jobs_on_job_id"
      t.index [ :queue_name, :scheduled_at, :finished_at ], name: "index_solid_queue_jobs_for_alerting"
    end

    create_table :solid_queue_scheduled_executions do |t|
      t.references :job, index: { unique: true }
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.datetime :scheduled_at, null: false

      t.datetime :created_at, null: false

      t.index [ :scheduled_at, :priority ], name: "index_solid_queue_scheduled_executions"
    end

    create_table :solid_queue_ready_executions do |t|
      t.references :job, index: { unique: true }
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false

      t.datetime :created_at, null: false

      t.index [ :priority, :queue_name ], name: "index_solid_queue_ready_executions"
    end

    create_table :solid_queue_claimed_executions do |t|
      t.references :job, index: { unique: true }
      t.string :claimed_by

      t.datetime :created_at, null: false
    end

    create_table :solid_queue_failed_executions do |t|
      t.references :job, index: { unique: true }
      t.text :error

      t.datetime :created_at, null: false
    end

    create_table :solid_queue_processes do |t|
      t.string :name, null: false, index: { unique: true }

      t.datetime :created_at, null: false
      t.datetime :last_heartbeat_at, null: false, index: true
    end
  end
end
