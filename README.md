# fluent-plugin-record-splitter

A Fluentd plugin to split fluentd events into multiple records

## Requirements

Fluentd >= v0.12

## Install

Use RubyGems:

```
gem install fluent-plugin-record-splitter
```

## Configuration

- tag: The output tag for the generated records.
- input_key: The target key to be splited.
- output_key: The generateed splitted key (if not specified input_key will be used).
- split_stratgey: The strategy used to splited the message should be either lines or regex.
- split_regex: Regex to split lines.
- shared_keys: List of keys to be shared between all generated records.
- remove_keys: List of keys to be removed from all generated records.
- append_new_line: Append a new line to the end of the input event.
- remove_new_line: Remove the new line form the end of the generated events.
- remove_input_key: Remove the key spcified by `input_key` from the generated events.


## Configuration Examples

```
<match pattern>
  @type record_splitter
  tag splitted.log
  input_key message
  split_stratgey lines
  append_new_line true
  remove_new_line true
  shared_keys ["akey"]
</match>
```

If following record is passed:

```
{'akey':'c', 'abkey':'cc', 'message': 'line one\nlines2' }
```

then you got new records like below:

```
{'akey':'c', 'message': 'line one' }
{'akey':'c', 'message': 'lines2' }
```

another configuration

```
<match pattern>
  @type record_splitter
  tag splitted.log
  input_key message
  split_stratgey regex
  split_regex /\d+\s<\d+>.+/
  remove_keys ["akey"]
</match>
```

If following record is passed:

```
{'dkey':'c', 'akey':'c', 'abkey':'cc', 'message': '83 <40>1 2012-11-30T06:45:29+00:00 start app\n90 <40>1 2012-11-30T06:45:26+00:00 host app web.3 - Starting process' }
```

then you got new records like below:

```
{'dkey':'c', 'abkey':'cc', 'message': '83 <40>1 2012-11-30T06:45:29+00:00 start app' }
{'dkey':'c', 'abkey':'cc', 'message': '90 <40>1 2012-11-30T06:45:26+00:00 host app web.3 - Starting process' }
```

## ChangeLog

See [CHANGELOG.md](CHANGELOG.md) for details.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new [Pull Request](../../pull/new/master)

## Copyright

Copyright (c) 2015 Naotoshi Seo. See [LICENSE](LICENSE) for details.
