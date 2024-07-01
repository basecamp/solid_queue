# frozen_string_literal: true

class SolidQueue::Process < SolidQueue::Record
  include Prunable

  belongs_to :supervisor, class_name: "SolidQueue::Process", optional: true
  has_many :claimed_executions

  store :metadata, coder: JSON

  after_destroy -> { claimed_executions.release_all }

  def self.register(**attributes)
    SolidQueue.instrument :register_process, **attributes do
      create!(attributes.merge(last_heartbeat_at: Time.current))
    end
  rescue Exception => error
    SolidQueue.instrument :register_process, **attributes.merge(error: error)
    raise
  end

  def heartbeat
    touch(:last_heartbeat_at)
  end

  def deregister(pruned: false)
    SolidQueue.instrument :deregister_process, process: self, pruned: pruned, claimed_size: claimed_executions.size do |payload|
      destroy!
    rescue Exception => error
      payload[:error] = error
      raise
    end
  end
end
