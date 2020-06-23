require_relative 'core'

module Fluent
  class Plugin::RecordSplitterOutput < Plugin::Output
    Fluent::Plugin.register_output('record_splitter', self)

    helpers :event_emitter
    include ::Fluent::RecordSplitterOutputCore

    def initialize
      super
    end

    def configure(conf)
      super
    end

    def multi_workers_ready?
      true
    end

    def process(tag, es)
      super
    end
  end
end
