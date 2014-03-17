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
MOMENT = require 'moment'
NUMERAL = require 'numeral'

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
      resolve(arry.map(Record.fromArray))
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
  known_path = dest_dir.append('transaction_log.csv')
  unknown_path = dest_dir.append('unknown_transactions.csv')

  write = (data) ->
    promise = LIB.Path.create(dest_dir).append('unknown_transactions.csv')
      .write()

    write_known = write_csv(known_path)(data.known)
    write_unknown = write_csv(unknown_path)(data.unknown)

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


write_csv = (path) ->
  write = (data) ->
    promise = new Promise (resolve, reject) ->
      on_end = (count) -> resolve(path)
      on_error = (err) -> reject(err)
      record_to_a = (rec) -> return rec.to_array()

      CSV().from.array(data.map(record_to_a))
        .to.stream(path.newWriteStream())
        .on('end', on_end)
        .on('error', on_error)
      return
    return promise

  return write


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


class Record

  constructor: (spec) ->
    @date         = Record.parse_date(spec.date)
    @type         = spec.type
    @amount       = Record.parse_amount(spec.amount)
    @vendor       = spec.vendor
    @description  = spec.description
    @category     = spec.category
    @irs_category = spec.irs_category

  update: (attrs) ->
    return Record.create(LIB.extend(@, attrs))

  to_array: ->
    arry = [
      @formatDate()
      @type
      @formatAmount()
      @vendor
      @description
      @category
      @irs_category
    ]
    return arry

  formatAmount: ->
    unless LIB.isNumber(@amount) then return ''
    return NUMERAL(@amount).format('(0,0.00)')

  formatDate: ->
    unless @date then return 'YYYY-MM-DD'
    return MOMENT(@date).format('YYYY-MM-DD')

  @parse_date: (str) ->
    if LIB.isObject(str) then return str
    return MOMENT(str, "MM/DD/YYYY").toDate()

  @parse_amount: (str) ->
    if LIB.isNumber(str) then return str
    return NUMERAL().unformat(str)

  @fromArray = (data) ->
    record = new Record({
      date: data[0]
      description: data[1]
      amount: data[2]
    })
    return record

  @create = (data) ->
    return new Record(data)
