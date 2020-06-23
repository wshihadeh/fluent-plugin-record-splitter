require 'fluent/version'
major, minor, patch = Fluent::VERSION.split('.').map(&:to_i)
if major > 0 || (major == 0 && minor >= 14)
  require 'fluent/test/driver/output'
  require 'fluent/test/helpers'
  include Fluent::Test::Helpers

  class OutputTestDriver < Fluent::Test::Driver::Output
    def initialize(klass, tag)
      super(klass)
      @tag = tag
    end

    def configure(conf, use_v1)
      super(conf, syntax: use_v1 ? :v1 : :v0)
    end

    def run(&block)
      super(default_tag: @tag, &block)
    end

    def emit(record, time)
      feed(time, record)
    end

    def emits
      events
    end
  end

  def create_driver(conf, use_v1, default_tag: @tag)
    OutputTestDriver.new(Fluent::Plugin::RecordSplitterOutput, default_tag).configure(conf, use_v1)
  end
else
  def event_time(str)
    Time.parse(str)
  end

  def create_driver(conf, use_v1, default_tag: @tag)
    Fluent::Test::OutputTestDriver.new(Fluent::RecordSplitterOutput, default_tag).configure(conf, use_v1)
  end
end
