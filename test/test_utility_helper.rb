require File.join(File.expand_path('./../', __FILE__), 'test_helper')

class TestUtilityFunctions < Minitest::Test

  def test_newline_and_spaces
    assert_equal "\n    ", UtilityFunctions.newline_and_spaces(4)
  end

  def test_comma_newline_and_spaces
    assert_equal ",\n    ", UtilityFunctions.comma_newline_and_spaces(4)
  end

  def test_ip_from_uri
    assert_equal '192.168.0.1', UtilityFunctions.ip_from_uri('192.168.0.1')
    assert_equal '192.168.0.1', UtilityFunctions.ip_from_uri('http://192.168.0.1:8080/')
    assert_equal '192.168.0.1', UtilityFunctions.ip_from_uri('file://192.168.0.1:8080/abd.txt')
  end

  def test_weeks_ago
    anchor = Time.local(2010, 10, 22)
    expect = Time.local(2010, 10, 1)
    assert_equal expect, UtilityFunctions.weeks_ago(anchor, 3)

    anchor = Date.new(2010, 10, 22)
    expect = Date.new(2010, 10, 1)
    assert_equal expect, UtilityFunctions.weeks_ago(anchor, 3)

    anchor = DateTime.new(2010, 10, 22, 5, 5,5)
    expect = DateTime.new(2010, 10, 1, 5, 5,5)
    assert_equal expect, UtilityFunctions.weeks_ago(anchor, 3)

    assert_raises(ArgumentError) { UtilityFunctions.weeks_ago(123, 3) }
  end

  def test_weeks_since
    anchor = Time.local(2010, 10, 22)
    expect = Time.local(2010, 11, 12)
    assert_equal expect, UtilityFunctions.weeks_since(anchor, 3)

    anchor = Date.new(2010, 10, 22)
    expect = Date.new(2010, 11, 12)
    assert_equal expect, UtilityFunctions.weeks_since(anchor, 3)

    anchor = DateTime.new(2010, 10, 22, 5, 5,5)
    expect = DateTime.new(2010, 11, 12, 5, 5,5)
    assert_equal expect, UtilityFunctions.weeks_since(anchor, 3)

    assert_raises(ArgumentError) { UtilityFunctions.weeks_since(123, 3) }
  end

  def test_days_ago
    anchor = Time.local(2010, 10, 22)
    expect = Time.local(2010, 10, 19)
    assert_equal expect, UtilityFunctions.days_ago(anchor, 3)

    anchor = Date.new(2010, 10, 22)
    expect = Date.new(2010, 10, 19)
    assert_equal expect, UtilityFunctions.days_ago(anchor, 3)

    anchor = DateTime.new(2010, 10, 22, 5, 5,5)
    expect = DateTime.new(2010, 10, 19, 5, 5,5)
    assert_equal expect, UtilityFunctions.days_ago(anchor, 3)

    assert_raises(ArgumentError) { UtilityFunctions.days_ago(123, 3) }
  end

  def test_days_since
    anchor = Time.local(2010, 10, 22)
    expect = Time.local(2010, 10, 25)
    assert_equal expect, UtilityFunctions.days_since(anchor, 3)

    anchor = Date.new(2010, 10, 22)
    expect = Date.new(2010, 10, 25)
    assert_equal expect, UtilityFunctions.days_since(anchor, 3)

    anchor = DateTime.new(2010, 10, 22, 5, 5,5)
    expect = DateTime.new(2010, 10, 25, 5, 5,5)
    assert_equal expect, UtilityFunctions.days_since(anchor, 3)

    assert_raises(ArgumentError) { UtilityFunctions.days_since(123, 3) }
  end

  def test_scientific_notation_to_s
    [
      [1,1],
      ['123', '123'],
      ['1.0e2', '100.0'],
      ['X1.0e2', 'X1.0e2'],
      ['1.0e2X', '1.0e2X'],
      [true, true],
      ['false', 'false'],
      ['L123', 'L123']
    ].each do |val, expect|
      assert_equal expect, UtilityFunctions.scientific_notation_to_s(val)
    end
  end

  def test_text_tables
    recs = [
      {id: 1, str: 'String', long_str: 'str', date: Date.parse('2020-01-01'), time: Time.parse('2020-01-01 01:01:01'),
       bool: true, number: 8123.45, int: 123456 }
    ]
    items = [
      { recs: [], heads: {}, times: [], numbers: [], rjust: [], expect: '' },
      { recs: recs, heads: {}, times: [], numbers: [], rjust: [], expect: <<STR
+----+--------+----------+------------+---------------------------+------+---------+--------+
| Id | Str    | Long str | Date       | Time                      | Bool | Number  | Int    |
+----+--------+----------+------------+---------------------------+------+---------+--------+
| 1  | String | str      | 2020-01-01 | 2020-01-01 01:01:01 +0200 | true | 8123.45 | 123456 |
+----+--------+----------+------------+---------------------------+------+---------+--------+
STR
      },
      { recs: recs, heads: { str: 'STRING', int: 'INTEGER' }, times: [:time], numbers: [:number], rjust: [:id, :int], expect: <<STR
+----+--------+----------+------------+---------------------+------+----------+---------+
| Id | STRING | Long str | Date       | Time                | Bool | Number   | INTEGER |
+----+--------+----------+------------+---------------------+------+----------+---------+
|  1 | String | str      | 2020-01-01 | 2020-01-01 01:01:01 | true | 8,123.45 |  123456 |
+----+--------+----------+------------+---------------------+------+----------+---------+
STR
      }
    ]

    items.each do |item|
      assert_equal item[:expect].chomp,
                   UtilityFunctions.make_text_table(item[:recs],
                                                    heads: item[:heads],
                                                    times: item[:times],
                                                    numbers: item[:numbers],
                                                    rjust: item[:rjust]).join("\n")
    end
  end
end
