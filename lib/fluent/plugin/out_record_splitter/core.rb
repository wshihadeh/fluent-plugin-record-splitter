module Fluent
  module RecordSplitterOutputCore
    def initialize
      super
    end

    def self.included(klass)
      klass.config_param :tag, :string, default: nil, desc: 'The output tag name.'
      klass.config_param :input_key, :string, default: nil, desc: 'The Target key to be splited.'
      klass.config_param :remove_input_key, :bool, default: false
      klass.config_param :output_key, :string, default: nil, desc: 'The generateed splitted key.'
      klass.config_param :split_stratgey, :string, default: 'lines', desc: 'the strategy used to splited the message should be either lines or regex'
      klass.config_param :append_new_line, :bool, default: false
      klass.config_param :remove_new_line, :bool, default: false
      klass.config_param :split_regex, :string, default: '/.+\n/', desc: 'Regex to split lines'
      klass.config_param :shared_keys, :array, default: [], desc: 'List of keys to be shared between all generated records.'
      klass.config_param :remove_keys, :array, default: [], desc: 'List of keys to be removed from all generated records.'
    end

    def configure(conf)
      super

      regex = /^\/.+\/$/

      if @tag.nil?
        raise Fluent::ConfigError, "out_record_splitter: `tag` must be specified"
      end

      if @input_key.nil?
        raise Fluent::ConfigError, "out_record_splitter: `input_key` must be specified"
      end

      if @output_key.nil?
        @output_key = @input_key
      end

      if !@shared_keys.empty? && !@remove_keys.empty?
        raise Fluent::ConfigError, 'Cannot set both shared_keys and remove_keys.'
      end

      if regex.match(@split_regex.to_s)
        @split_regex = Regexp.new(@split_regex[1..-2])
      end
    end

    def process(tag, es)
      es.each do |time, record|
        common_keys = if !@shared_keys.empty?
      	                record.select { |key, _value| @shared_keys.include?(key) }
      	              elsif !@remove_keys.empty?
      	                record.reject { |key, _value| @remove_keys.include?(key) }
      	              else
      	              	record.dup
      	              end

        if @remove_input_key && @output_key != @input_key
      	  common_keys.delete(@input_key)
        end

        next unless record.key?(@input_key)
        message = record[@input_key]
        lines = split_lines message

      	lines.each do |l|
          keys = common_keys.merge(@output_key => l)
          router.emit(@tag, time, keys)
        end
      end
    end

    def split_lines(message)
      message = "#{message}\n" if @append_new_line

      messages = if @split_stratgey == 'lines'
        	       message.to_s.lines
                 else
      	           message.scan(@split_regex)
                 end
      messages = messages.map{|m| m.gsub("\n",'') } if @remove_new_line
      messages
    end
  end
end
