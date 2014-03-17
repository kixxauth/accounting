exports.usage = "bank_statement_to_transaction_log.coffee --config <file_path> --source <file_path> --dest <directory_path>"

exports.options =
  config:
    description: "The path to the configuration file (a CoffeeScript file)"
    required: yes
  source:
    description: "The source file of the bank statement in tab separated values."
    required: yes
  dest:
    description: "The destination directory to output results. (default=cwd)"

exports.help = """
Parse a bank statement data dump of tab separated values into a clean transaction log.
"""

exports.main = (opts) ->
  config = require(LIB.Path.create().resolve(opts.config).toString())
  LIB.Path.create(opts.source).read()
    .then(split_lines)
    .then(filter_lines)
    .then(split_fields)
    .then(match_records({matchers: config.matchers}))
    .catch(LIB.fail);
  return


split_lines = (text) ->
  return text.split('\n')


filter_lines = (lines) ->
  filtered_lines = lines.filter (line) ->
    start_date = /^[\d]{2}\/[\d]{2}\/[\d]{4}/.test(line)
    balance_line = /beginning balance/i.test(line)
    return start_date and not balance_line
  return filtered_lines


split_fields = (lines) ->
  data = lines.map (line) ->
    parts = line.split('\t')
    line_item =
      date: parts[0]
      description: parts[1]
      amount: parts[2]
    return line_item
  return data


match_records = (opts) ->
  matchers = opts.matchers.map(Matcher.create)

  matcher = (records) ->
    data = records.reduce((data, record) ->
      if match = check_match(record)
        data.known.push(match)
      else
        data.unknown.push(record)

      return data
    , {known: [], unknown: []})
    print data.known
    return data

  check_match = (record) ->
    match = LIB.find matchers, (matcher) ->
      return matcher.match(record)

    if match then return match.match(record)
    return

  return matcher


class Matcher
  regex: null
  vendor: null
  description: null
  category: null
  irs_category: null

  constructor: (spec) ->
    @regex = spec.regex
    @vendor = spec.vendor
    @description = spec.description
    @category = spec.category
    @irs_category = spec.irs_category

  match: (record) ->
    unless @regex.test(record.description) then return
    rv =
      date: record.date
      vendor: @vendor
      description: @description
      amount: record.amount
      category: @category
      irs_category: @irs_category
    return rv

  @create = (spec) ->
    return new Matcher(spec)
