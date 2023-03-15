require "solid_queue/version"
require "solid_queue/engine"

require "active_job/queue_adapters/solid_queue_adapter"

require "solid_queue/app_executor"
require "solid_queue/configuration"
require "solid_queue/runner"
require "solid_queue/runner/process_registration"
require "solid_queue/dispatcher"
require "solid_queue/scheduler"
require "solid_queue/supervisor"

module SolidQueue
  mattr_accessor :logger, default: ActiveSupport::Logger.new($stdout)
  mattr_accessor :app_executor

  mattr_accessor :process_heartbeat_interval, default: 60.seconds
  mattr_accessor :process_alive_threshold, default: 5.minutes

  mattr_accessor :execution_limit_per_dispatch_run, default: 0
end
