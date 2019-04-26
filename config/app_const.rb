# frozen_string_literal: true

# A class for defining global constants in a central place.
class AppConst
  # Helper to create hash of label sizes from a 2D array.
  def self.make_label_size_hash(array)
    Hash[array.map { |w, h| ["#{w}x#{h}", { 'width': w, 'height': h }] }].freeze
  end

  # Client-specific code
  CLIENT_CODE = ENV.fetch('CLIENT_CODE')

  # Constants for roles:
  ROLE_IMPLEMENTATION_OWNER = 'IMPLEMENTATION_OWNER'
  ROLE_CUSTOMER = 'CUSTOMER'
  ROLE_SUPPLIER = 'SUPPLIER'
  ROLE_TRANSPORTER = 'TRANSPORTER'

  # Menu
  FUNCTIONAL_AREA_RMD = 'RMD'

  # Logging
  FIELDS_TO_EXCLUDE_FROM_DIFF = %w[label_json png_image].freeze

  # MesServer
  LABEL_SERVER_URI = ENV.fetch('LABEL_SERVER_URI')
  POST_FORM_BOUNDARY = 'AaB03x'

  # Labels
  SHARED_CONFIG_HOST_PORT = ENV.fetch('SHARED_CONFIG_HOST_PORT')
  LABEL_VARIABLE_SETS = ENV.fetch('LABEL_VARIABLE_SETS').strip.split(',')
  LABEL_PUBLISH_NOTIFY_URLS = ENV.fetch('LABEL_PUBLISH_NOTIFY_URLS', '').split(',')

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
  EMAIL_GROUP_LABEL_APPROVERS = 'label_approvers'
  EMAIL_GROUP_LABEL_PUBLISHERS = 'label_publishers'
  USER_EMAIL_GROUPS = [EMAIL_GROUP_LABEL_APPROVERS, EMAIL_GROUP_LABEL_PUBLISHERS].freeze
end
