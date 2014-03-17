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

CSV = require 'csv'

ACC = require './lib/'

TransactionRecord = require('lib/transaction_record').TransactionRecord

exports.main = (opts) ->
  config = require(LIB.Path.create().resolve(opts.config).toString())
  LIB.Path.create(opts.source).read()
    .then(split_lines)
    .then(filter_lines)
    .then(split_fields)
    .then(match_records({matchers: config.matchers}))
    .then(write_records({dest_dir: opts.dest}))
    .then(complete)
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
  promise = new Promise (resolve, reject) ->

    to_array = (arry, count) ->
      resolve(arry.map(TransactionRecord.from_raw_array))
      return

    on_error = (err) ->
      reject(err)
      return

    CSV()
      .on('error', on_error)
      .from.array(lines, {delimiter: '\t'})
      .to.array(to_array)
    return
  return promise


match_records = (opts) ->
  matchers = opts.matchers.map(Matcher.create)

  matcher = (records) ->
    data = records.reduce((data, record) ->
      if match = find_match(record)
        data.known.push(record.update(match.attributes()))
      else
        data.unknown.push(record)

      return data
    , {known: [], unknown: []})
    return data

  find_match = (record) ->
    match = LIB.find matchers, (matcher) ->
      return matcher.match(record)
    return match if match

  return matcher


write_records = (opts) ->
  dest_dir = LIB.Path.create(opts.dest_dir)
  known_path = dest_dir.append('incomplete_transaction_log.csv')
  unknown_path = dest_dir.append('unknown_transactions.csv')

  write = (data) ->
    write_known = ACC.write_csv(known_path)(data.known)
    write_unknown = ACC.write_csv(unknown_path)(data.unknown)

    promise = Promise.all([write_known, write_unknown]).then ->
      return {known: data.known, unknown: data.unknown, unknown_path: unknown_path, known_path: known_path}
    return promise
  return write


complete = (state) ->
    print 'matched records:', state.known.length, 'unknown:', state.unknown.length
    print "You'll need to manually update the unknown records and cancat them with concat_transaction_log.coffee"
    print state.known_path.toString()
    print state.unknown_path.toString()
    return true


class Matcher

  constructor: (spec) ->
    @regex        = spec.regex
    @type         = spec.type
    @vendor       = spec.vendor
    @description  = spec.description
    @category     = spec.category
    @irs_category = spec.irs_category

  match: (record) ->
    unless @regex.test(record.description) then return
    rv = record.update({
      type: @type
      vendor: @vendor
      description: @description
      category: @category
      irs_category: @irs_category
    })
    return rv

  attributes: ->
    attrs =
      vendor: @vendor
      description: @description
      category: @category
      irs_category: @irs_category
    return attrs

  @create = (spec) ->
    return new Matcher(spec)
