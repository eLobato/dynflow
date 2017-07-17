require 'test_helper'
require 'active_support'
require 'mocha/mini_test'
require 'logging'
require_relative '../lib/dynflow/rails'

class DaemonTest < ActiveSupport::TestCase
  setup do
    @dynflow_memory_watcher = mock('memory_watcher')
    @daemons = mock('daemons')
    @daemon = ::Dynflow::Rails::Daemon.new(
      @dynflow_memory_watcher,
      @daemons
    )
    @world_class = mock('dummy world factory')
    @dummy_world = ::Dynflow::Testing::DummyWorld.new
    @dummy_world.stubs(:auto_execute)
    @dummy_world.stubs(:terminated).returns(Concurrent.event)
    @world_class.stubs(:new).returns(@dummy_world)
    @dynflow = ::Dynflow::Rails.new(
      @world_class,
      ::Dynflow::Rails::Configuration.new
    )
    File.stubs(:expand_path).with('./config/environment.rb', Dir.pwd).
      returns('support/rails/environment.rb')
    ::Rails.stubs(:application).returns(OpenStruct.new(:dynflow => @dynflow))
    ::Rails.stubs(:root).returns('support/rails')
    ::Rails.stubs(:logger).returns(Logging.logger(STDOUT))
    #::Rails.application.stubs(:dynflow).returns(@dynflow)
    @dynflow.require!
  end

  test 'run command creates a watcher if memory_limit option specified' do
    current_folder = File.expand_path('../', __FILE__)

    @dynflow_memory_watcher.expects(:new).with do |_world, memory_limit, _watcher_options|
      memory_limit == 1000
    end
    @daemon.stubs(:sleep).returns(true) # don't pause the execution

    @daemon.run(current_folder, memory_limit: 1000)
    # initialization should be performed inside the foreman environment,
    # which is mocked here
    @dynflow.initialize!
  end

  test 'run command sets parameters to watcher' do
    current_folder = File.expand_path('../', __FILE__)

    @dynflow_memory_watcher.expects(:new).with do |_world, memory_limit, watcher_options|
      memory_limit == 1000 &&
        watcher_options[:polling_interval] == 100 &&
        watcher_options[:initial_wait] == 200
    end
    @daemon.stubs(:sleep).returns(true) # don't pause the execution

    @daemon.run(
      current_folder,
      memory_limit: 1000,
      memory_polling_interval: 100,
      memory_init_delay: 200
    )
    # initialization should be performed inside the foreman environment,
    # which is mocked here
    @dynflow.initialize!
  end

  test 'run_background command executes run with all params set as a daemon' do
    @daemon.expects(:run).twice.with do |_folder, options|
      options[:memory_limit] == 1000 &&
        options[:memory_init_delay] == 100 &&
        options[:memory_polling_interval] == 200
    end
    @daemons.expects(:run_proc).twice.yields

    @daemon.run_background(
      'start',
      executors_count: 2,
      memory_limit: 1000,
      memory_init_delay: 100,
      memory_polling_interval: 200
    )
  end

  test 'default options read values from ENV' do
    ENV['EXECUTORS_COUNT'] = '2'
    ENV['EXECUTOR_MEMORY_LIMIT'] = '1gb'
    ENV['EXECUTOR_MEMORY_MONITOR_DELAY'] = '3'
    ENV['EXECUTOR_MEMORY_MONITOR_INTERVAL'] = '4'

    actual = @daemon.send(:default_options)

    assert_equal 2, actual[:executors_count]
    assert_equal 1.gigabytes, actual[:memory_limit]
    assert_equal 3, actual[:memory_init_delay]
    assert_equal 4, actual[:memory_polling_interval]
  end
end