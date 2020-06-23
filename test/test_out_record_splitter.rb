require_relative 'helper'
require 'time'
require 'fluent/plugin/out_record_splitter'

Fluent::Test.setup

class RecordSplitterOutpuTest < Test::Unit::TestCase
  def emit(config, use_v1, msgs = [''])
    d = create_driver(config, use_v1)
    d.run do
      records = msgs.map do |msg|
        next msg if msg.is_a?(Hash)
        {'message' => msg }
      end
      records.each do |record|
        d.emit(record, @time)
      end
    end

    @instance = d.instance
    d.emits
  end

  setup do
   @tag = 'splitter.log'
   @time = event_time("2020-06-24 03:02:01")
   Timecop.freeze(@time)
  end

  teardown do
    Timecop.return
  end

  [true, false].each do |use_v1|
    sub_test_case 'configure' do
      test 'missing input key' do
        assert_raise(Fluent::ConfigError) do
          create_driver(%[
            tag test.tag
          ], use_v1)
        end
      end

      test 'missing input tag' do
        assert_raise(Fluent::ConfigError) do
          create_driver(%[
            input_key x
          ], use_v1)
        end
      end

      test 'config conflict' do
        assert_raise(Fluent::ConfigError) do
          create_driver(%[
            input_key x
            tag test.tag
            shared_keys x
            remove_keys y
          ], use_v1)
        end
      end

      test 'typical usage' do
        assert_nothing_raised do
          create_driver(%[
            tag test.tag
            input_key log
          ], use_v1)
        end
      end
    end

    sub_test_case 'test split lines' do

      test 'Split message on new line' do
        config = <<EOC
          tag test.tag
          input_key message
EOC
        msgs = ["0\n1\n2\n3"]
        emits = emit(config, use_v1, msgs)
        emits.each_with_index do |(tag, _time, record), i|
          assert_equal('test.tag', tag)
          assert_equal(record['message'].gsub("\n",''), i.to_s)
        end
      end

      test 'Wrong input key' do
        config = <<EOC
          tag test.tag
          input_key wrong
EOC
        msgs = ["0\n1\n2\n3"]
        emits = emit(config, use_v1, msgs)
        assert_equal(emits.count, 0)
      end

      test 'copy to a new key' do
        config = <<EOC
          tag test.tag
          input_key message
          output_key log
EOC
        msgs = ["0\n1\n2\n3"]
        emits = emit(config, use_v1, msgs)
        emits.each_with_index do |(tag, _time, record), i|
          assert_equal('test.tag', tag)
          assert_equal(record['log'].gsub("\n",''), i.to_s)
          assert_equal(record['message'], "0\n1\n2\n3")
        end
      end

      test 'remove input key' do
        config = <<EOC
          tag test.tag
          input_key message
          output_key log
          remove_input_key true
EOC
        msgs = ["0\n1\n2\n3"]
        emits = emit(config, use_v1, msgs)
        assert_equal(emits.count, 4)
        emits.each_with_index do |(tag, _time, record), i|
          assert_equal('test.tag', tag)
          assert_equal(record['log'].gsub("\n",''), i.to_s)
          assert_equal(record['message'], nil)
        end
      end

      test 'remove new line' do
        config = <<EOC
          tag test.tag
          input_key message
          output_key log
          remove_input_key true
          remove_new_line true
EOC
        msgs = ["0\n1\n2\n3"]
        emits = emit(config, use_v1, msgs)
        assert_equal(emits.count, 4)
        emits.each_with_index do |(tag, _time, record), i|
          assert_equal('test.tag', tag)
          assert_equal(record['log'], i.to_s)
          assert_equal(record['message'], nil)
        end
      end

      test 'remove input key with append_new_line' do
        config = <<EOC
          tag test.tag
          input_key message
          output_key log
          remove_input_key true
          append_new_line true
EOC
        msgs = ["0\n1\n2\n3"]
        emits = emit(config, use_v1, msgs)
        assert_equal(emits.count, 4)
        emits.each_with_index do |(tag, _time, record), i|
          assert_equal('test.tag', tag)
          assert_equal(record['log'].gsub("\n",''), i.to_s)
          assert_equal(record['message'], nil)
        end
      end

      test 'keep shared keys' do
        config = <<EOC
          tag test.tag
          input_key message
          output_key log
          shared_keys ["ckey", "bkey"]
EOC
        msgs = [{ 'message' =>  "0\n1\n2\n3", 'akey' =>  1, 'bkey' => 2, 'ckey' => 3, 'dkey' => 4 }]
        emits = emit(config, use_v1, msgs)
        assert_equal(emits.count, 4)
        emits.each_with_index do |(tag, _time, record), i|
          assert_equal('test.tag', tag)
          assert_equal(record['log'].gsub("\n",''), i.to_s)
          assert_equal(record['ckey'], 3)
          assert_equal(record['bkey'], 2)
          assert_equal(record['message'], nil)
          assert_equal(record['akey'], nil)
        end
      end

      test 'remove keys' do
        config = <<EOC
          tag test.tag
          input_key message
          output_key log
          remove_keys ["ckey", "bkey"]
EOC
        msgs = [{ 'message' =>  "0\n1\n2\n3", 'akey' =>  1, 'bkey' => 2, 'ckey' => 3, 'dkey' => 4 }]
        emits = emit(config, use_v1, msgs)
        assert_equal(emits.count, 4)
        emits.each_with_index do |(tag, _time, record), i|
          assert_equal('test.tag', tag)
          assert_equal(record['log'].gsub("\n",''), i.to_s)
          assert_equal(record['ckey'], nil)
          assert_equal(record['bkey'], nil)
          assert_equal(record['message'], "0\n1\n2\n3")
          assert_equal(record['akey'], 1)
        end
      end
    end

    sub_test_case 'test split lines with regex' do

      test 'Split message on new line' do
        config = <<EOC
          tag test.tag
          input_key message
          split_stratgey regex
EOC
        msgs = ["0\n1\n2\n3\n"]
        emits = emit(config, use_v1, msgs)
        assert_equal(emits.count, 4)
        emits.each_with_index do |(tag, _time, record), i|
          assert_equal('test.tag', tag)
          assert_equal(record['message'].gsub("\n",''), i.to_s)
        end
      end

      test 'Split message with append_new_line' do
        config = <<EOC
          tag test.tag
          input_key message
          split_stratgey regex
          append_new_line true
EOC
        msgs = ["0\n1\n2\n3"]
        emits = emit(config, use_v1, msgs)
        assert_equal(emits.count, 4)
        emits.each_with_index do |(tag, _time, record), i|
          assert_equal('test.tag', tag)
          assert_equal(record['message'].gsub("\n",''), i.to_s)
        end
      end

      test 'Split message with remove_new_line true' do
        config = <<EOC
          tag test.tag
          input_key message
          split_stratgey regex
          append_new_line true
          remove_new_line true

EOC
        msgs = ["0\n1\n2\n3"]
        emits = emit(config, use_v1, msgs)
        assert_equal(emits.count, 4)
        emits.each_with_index do |(tag, _time, record), i|
          assert_equal('test.tag', tag)
          assert_equal(record['message'], i.to_s)
        end
      end

      test 'Split message with custom regex and append_new_line' do
        config = <<EOC
          tag test.tag
          input_key message
          split_stratgey regex
          split_regex /\\d+\\s<\\d+>.+\\n/
          append_new_line true
EOC
        msgs = ["83 <40>1 2012-11-30T06:45:29+00:00 start app\n90 <40>1 2012-11-30T06:45:26+00:00 host app web.3 - Starting process"]
        emits = emit(config, use_v1, msgs)
        assert_equal(emits.count, 2)
        assert_equal(emits.first[2]['message'], "83 <40>1 2012-11-30T06:45:29+00:00 start app\n")
        assert_equal(emits.last[2]['message'], "90 <40>1 2012-11-30T06:45:26+00:00 host app web.3 - Starting process\n")
      end

      test 'Split message with custom regex' do
        config = <<EOC
          tag test.tag
          input_key message
          split_stratgey regex
          split_regex /\\d+\\s<\\d+>.+/
EOC
        msgs = ["83 <40>1 2012-11-30T06:45:29+00:00 start app\n90 <40>1 2012-11-30T06:45:26+00:00 host app web.3 - Starting process"]
        emits = emit(config, use_v1, msgs)
        assert_equal(emits.count, 2)
        assert_equal(emits.first[2]['message'], "83 <40>1 2012-11-30T06:45:29+00:00 start app")
        assert_equal(emits.last[2]['message'], "90 <40>1 2012-11-30T06:45:26+00:00 host app web.3 - Starting process")
      end
    end
  end
end
