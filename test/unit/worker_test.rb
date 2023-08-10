require "test_helper"
require "active_support/testing/method_call_assertions"

class WorkerTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::MethodCallAssertions

  setup do
    @worker = SolidQueue::Worker.new(queue_name: "background", pool_size: 3, polling_interval: 10)
  end

  teardown do
    @worker.stop if @worker.running?
    JobBuffer.clear
  end

  test "errors on claiming executions are reported via Rails error subscriber regardless of on_thread_error setting" do
    original_on_thread_error, SolidQueue.on_thread_error = SolidQueue.on_thread_error, nil

    subscriber = ErrorBuffer.new
    Rails.error.subscribe(subscriber)

    SolidQueue::ClaimedExecution.any_instance.expects(:update!).raises(RuntimeError.new("everything is broken"))

    AddToBufferJob.perform_later "hey!"

    @worker.start(mode: :async)

    wait_for_jobs_to_finish_for(0.5.second)
    @worker.wake_up

    assert_equal 1, subscriber.errors.count
    assert_equal "everything is broken", subscriber.messages.first
  ensure
    Rails.error.unsubscribe(subscriber) if Rails.error.respond_to?(:unsubscribe)
    SolidQueue.on_thread_error = original_on_thread_error
  end

  test "claim and process more enqueued jobs than the pool size allows to process at once" do
    5.times do |i|
      StoreResultJob.perform_later(:paused, pause: 1.second)
    end

    3.times do |i|
      StoreResultJob.perform_later(:immediate)
    end

    @worker.start(mode: :async)

    wait_for_jobs_to_finish_for(2.3.seconds) # 3 jobs of 1 second in parallel + 2 jobs 1 second in parallel + 3 immediate jobs
    @worker.wake_up

    assert_equal 5, JobResult.where(queue_name: :background, status: "completed", value: :paused).count
    assert_equal 3, JobResult.where(queue_name: :background, status: "completed", value: :immediate).count
  end
end
