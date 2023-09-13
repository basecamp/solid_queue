module SolidQueue
  class Queue
    attr_accessor :name

    class << self
      def all
        SolidQueue::Job.select(:queue_name).distinct.collect do |job|
          new(job.queue_name)
        end
      end

      def find_by_name(name)
        new(name)
      end
    end

    def initialize(name)
      @name = name
    end

    def paused?
      false
    end

    def pause
    end

    def resume
    end

    def clear
      Job.where(queue_name: name).each(&:discard)
    end

    def size
      @size ||= ReadyExecution.queued_as(name).count
    end

    def ==(queue)
      name == queue.name
    end
    alias_method :eql?, :==

    def hash
      name.hash
    end
  end
end
