# frozen_string_literal: true

# A class for defining global constants in a central place.
class AppConst
  def self.development?
    ENV['RACK_ENV'] == 'development'
  end

  def self.test?
    ENV['RACK_ENV'] == 'test'
  end

  # Any value that starts with y, Y, t or T is considered true.
  # All else is false.
  def self.check_true(val)
    val.match?(/^[TtYy]/)
  end

  # Take an environment variable and interpret it
  # as a boolean.
  #
  # If required is true, the variable MUST have a value.
  # If default_true is true, the value will be set to true if the variable has no value.
  def self.make_boolean(key, required: false, default_true: false)
    val = if required
            ENV.fetch(key)
          else
            ENV.fetch(key, default_true ? 't' : 'f')
          end
    check_true(val)
  end

  # Helper to create hash of label sizes from a 2D array.
  def self.make_label_size_hash(array)
    Hash[array.map { |w, h| ["#{w}x#{h}", { 'width': w, 'height': h }] }].freeze
  end

  # Client-specific code
  CLIENT_SET = {
    'srcc' => 'Sundays River Citrus Company',
    'tad' => 'Two A Day',
    'ghs' => 'Goede Hoop Sitrus',
    'kr' => 'Kromco'
  }.freeze
  CLIENT_CODE = ENV.fetch('CLIENT_CODE')
  raise 'CLIENT_CODE must be lowercase.' unless CLIENT_CODE == CLIENT_CODE.downcase
  raise "Unknown CLIENT_CODE - #{CLIENT_CODE}" unless CLIENT_SET.keys.include?(CLIENT_CODE)

  SHOW_DB_NAME = ENV.fetch('DATABASE_URL').rpartition('@').last
  URL_BASE = ENV.fetch('URL_BASE')
  URL_BASE_IP = ENV.fetch('URL_BASE_IP')
  APP_CAPTION = ENV.fetch('APP_CAPTION')

  NEW_FEATURE_LBL_PREPROCESS = make_boolean('NEW_FEATURE_LBL_PREPROCESS')
  if NEW_FEATURE_LBL_PREPROCESS
    puts '>>> NB. MesServer version MUST be GREATER than or equal to 3.57d.............'
  else
    puts '>>> NB. MesServer version MUST be LESS than or equal to 3.55.............'
  end

  # General
  DEFAULT_KEY = 'DEFAULT'

  # Constants for roles:
  ROLE_IMPLEMENTATION_OWNER = 'IMPLEMENTATION_OWNER'
  ROLE_CUSTOMER = 'CUSTOMER'
  ROLE_SUPPLIER = 'SUPPLIER'
  ROLE_TRANSPORTER = 'TRANSPORTER'

  # Routes that do not require login:
  BYPASS_LOGIN_ROUTES = [].freeze

  # Menu
  FUNCTIONAL_AREA_RMD = 'RMD'

  # Logging
  FIELDS_TO_EXCLUDE_FROM_DIFF = %w[label_json png_image].freeze

  # MesServer
  LABEL_SERVER_URI = ENV.fetch('LABEL_SERVER_URI')
  raise 'LABEL_SERVER_URI must end with a "/"' unless LABEL_SERVER_URI.end_with?('/')

  POST_FORM_BOUNDARY = 'AaB03x'

  # Labels
  SHARED_CONFIG_HOST_PORT = ENV.fetch('SHARED_CONFIG_HOST_PORT')
  LABEL_VARIABLE_SETS = ENV.fetch('LABEL_VARIABLE_SETS').strip.split(',')
  LABEL_PUBLISH_NOTIFY_URLS = ENV.fetch('LABEL_PUBLISH_NOTIFY_URLS', '').split(',')
  BATCH_PRINT_MAX_LABELS = ENV.fetch('BATCH_PRINT_MAX_LABELS', 20).to_i
  PREVIEW_PRINTER_TYPE = ENV.fetch('PREVIEW_PRINTER_TYPE', 'zebra')

  # Label sizes. The arrays contain width then height.
  DEFAULT_LABEL_DIMENSION = ENV.fetch('DEFAULT_LABEL_DIMENSION', '84x64')
  LABEL_SIZES = if ENV['LABEL_SIZES']
                  AppConst.make_label_size_hash(ENV['LABEL_SIZES'].split(';').map { |s| s.split(',') })
                else
                  AppConst.make_label_size_hash(
                    [
                      [84,   64], [84,  100], [97,   78], [78,   97], [77,  130], [100,  70],
                      [100,  84], [100, 100], [105, 250], [130, 100], [145,  50], [100, 150]
                    ]
                  )
                end

  # Printers
  PRINTER_USE_INDUSTRIAL = 'INDUSTRIAL'
  PRINTER_USE_OFFICE = 'OFFICE'

  # PRINT_APP_LOCATION = 'Location'
  # PRINT_APP_MR_SKU_BARCODE = 'Material Resource SKU Barcode'

  # PRINTER_APPLICATIONS = [
  #   PRINT_APP_LOCATION,
  #   PRINT_APP_MR_SKU_BARCODE
  # ].freeze

  # These will need to be configured per installation...
  BARCODE_PRINT_RULES = {
    # location: { format: 'LC%d', fields: [:id] },
    # sku: { format: 'SK%d', fields: [:sku_number] }
  }.freeze

  BARCODE_SCAN_RULES = [
    # { regex: '^LC(\\d+)$', type: 'location', field: 'id' },
    # { regex: '^(\\D\\D\\D)$', type: 'location', field: 'legacy_barcode' },
    # { regex: '^(\\D\\D\\D)$', type: 'dummy', field: 'code' },
    # { regex: '^SK(\\d+)', type: 'sku', field: 'sku_number' }
  ].freeze

  # Que
  QUEUE_NAME = ENV.fetch('QUEUE_NAME', 'default')

  # Mail
  ERROR_MAIL_RECIPIENTS = ENV.fetch('ERROR_MAIL_RECIPIENTS')
  ERROR_MAIL_PREFIX = ENV.fetch('ERROR_MAIL_PREFIX')
  SYSTEM_MAIL_SENDER = ENV.fetch('SYSTEM_MAIL_SENDER')
  EMAIL_REQUIRES_REPLY_TO = make_boolean('EMAIL_REQUIRES_REPLY_TO')
  EMAIL_GROUP_LABEL_APPROVERS = 'label_approvers'
  EMAIL_GROUP_LABEL_PUBLISHERS = 'label_publishers'
  USER_EMAIL_GROUPS = [EMAIL_GROUP_LABEL_APPROVERS, EMAIL_GROUP_LABEL_PUBLISHERS].freeze

  # CLM_BUTTON_CAPTION_FORMAT
  #
  # This string provides a format for captions to display on buttons
  # of robots that print carton labels.
  # The string can contain any text and fruitspec tokens that are
  # delimited by $: and $. e.g. 'Count: $:actual_count_for_pack$'
  #
  # The possible fruitspec tokens are:
  # HBL: 'COUNT: $:actual_count_for_pack$'
  # UM : 'SIZE: $:size_reference$'
  # SR : '$:size_ref_or_count$ $:product_chars$ $:target_market_group_name$'
  # * actual_count_for_pack
  # * basic_pack_code
  # * commodity_code
  # * grade_code
  # * mark_code
  # * marketing_variety_code
  # * org_code
  # * product_chars
  # * size_count_value
  # * size_reference
  # * size_ref_or_count
  # * standard_pack_code
  # * target_market_group_name
  CLM_BUTTON_CAPTION_FORMAT = ENV['CLM_BUTTON_CAPTION_FORMAT']

  # pi Robots can display 6 lines of text, while T2n robots can only display 4.
  # If all robots on site are homogenous, set the value here.
  # Else it will be looked up from the module name.
  ROBOT_DISPLAY_LINES = ENV.fetch('ROBOT_DISPLAY_LINES', 0).to_i
  ROBOT_MSG_SEP = '###'

  # Max number of passenger instances - used for designating high, busy or over usage
  MAX_PASSENGER_INSTANCES = ENV.fetch('MAX_PASSENGER_INSTANCES', 30).to_i
  # Lowest state for passenger usage to send emails. Can be INFO, BUSY or HIGH.
  PASSENGER_USAGE_LEVEL = ENV.fetch('PASSENGER_USAGE_LEVEL', 'INFO')

  BIG_ZERO = BigDecimal('0')
  # The maximum size of an integer in PostgreSQL
  MAX_DB_INT = 2_147_483_647

  # ISO 2-character country codes
  ISO_COUNTRY_CODES = %w[
    AF AL DZ AS AD AO AI AQ AG AR AM AW AU AT AZ BS BH BD BB BY BE BZ BJ
    BM BT BO BQ BA BW BV BR IO BN BG BF BI CV KH CM CA KY CF TD CL CN CX
    CC CO KM CD CG CK CR HR CU CW CY CZ CI DK DJ DM DO EC EG SV GQ ER EE
    SZ ET FK FO FJ FI FR GF PF TF GA GM GE DE GH GI GR GL GD GP GU GT GG
    GN GW GY HT HM VA HN HK HU IS IN ID IR IQ IE IM IL IT JM JP JE JO KZ
    KE KI KP KR KW KG LA LV LB LS LR LY LI LT LU MO MG MW MY MV ML MT MH
    MQ MR MU YT MX FM MD MC MN ME MS MA MZ MM NA NR NP NL NC NZ NI NE NG
    NU NF MP NO OM PK PW PS PA PG PY PE PH PN PL PT PR QA MK RO RU RW RE
    BL SH KN LC MF PM VC WS SM ST SA SN RS SC SL SG SX SK SI SB SO ZA GS
    SS ES LK SD SR SJ SE CH SY TW TJ TZ TH TL TG TK TO TT TN TR TM TC TV
    UG UA AE GB UM US UY UZ VU VE VN VG VI WF EH YE ZM ZW AX
  ].freeze
end
