# frozen_string_literal: true

module SolidQueue
  class Worker < Processes::Base
    include Processes::Poller

    attr_accessor :queues, :pool

    def initialize(**options)
      options = options.dup.with_defaults(SolidQueue::Configuration::WORKER_DEFAULTS)

      @polling_interval = options[:polling_interval]
      @queues = Array(options[:queues])
      @pool = Pool.new(options[:threads], on_idle: -> { wake_up })
    end

    def metadata
      super.merge(queues: queues.join(","), thread_pool_size: pool.size)
    end

    private
      def poll
        claim_executions.then do |executions|
          executions.each do |execution|
            pool.post(execution)
          end

          executions.size
        end
      end

      def claim_executions
        with_polling_volume do
          SolidQueue::ReadyExecution.claim(queues, pool.idle_threads, process.id)
        end
      end

      def shutdown
        pool.shutdown
        pool.wait_for_termination(SolidQueue.shutdown_timeout)

        super
      end

      def all_work_completed?
        SolidQueue::ReadyExecution.aggregated_count_across(queues).zero?
      end

      def set_procline
        procline "waiting for jobs in #{queues.join(",")}"
      end
  end
end
