class SolidQueue::Process < ActiveRecord::Base
  include Prunable

  serialize :metadata, JSON

  has_many :claimed_executions

  after_destroy -> { claimed_executions.release_all }

  def self.register(metadata)
    create!(metadata: metadata, last_heartbeat_at: Time.current)
  end

  def heartbeat
    touch(:last_heartbeat_at)
  end

  def deregister
    destroy!
  rescue Exception
    SolidQueue.logger.error("[SolidQueue] Error deregistering process #{id} - #{metadata}")
    raise
  end
end
