# frozen_string_literal: true

module SolidQueue
  module ProcessRegistration
    extend ActiveSupport::Concern

    included do
      include ActiveSupport::Callbacks
      define_callbacks :start, :run, :shutdown

      set_callback :start, :before, :register
      set_callback :start, :before, :launch_heartbeat

      set_callback :run, :after, -> { stop unless registered? }

      set_callback :shutdown, :before, :stop_heartbeat
      set_callback :shutdown, :after, :deregister

      attr_reader :supervisor
    end

    def inspect
      metadata.inspect
    end
    alias to_s inspect

    def supervised_by(process)
      @supervisor = process
    end

    private
      attr_accessor :process

      def register
        @process = SolidQueue::Process.register \
          kind: self.class.name.demodulize,
          pid: process_pid,
          supervisor: supervisor,
          hostname: hostname,
          metadata: metadata
      end

      def deregister
        process.deregister
      end

      def registered?
        process.persisted?
      end

      def launch_heartbeat
        @heartbeat_task = Concurrent::TimerTask.new(execution_interval: SolidQueue.process_heartbeat_interval) { heartbeat }
        @heartbeat_task.execute
      end

      def stop_heartbeat
        @heartbeat_task.shutdown
      end

      def heartbeat
        process.heartbeat
      end

      def hostname
        @hostname ||= Socket.gethostname
      end

      def process_pid
        @pid ||= ::Process.pid
      end

      def metadata
        {}
      end
  end
end
