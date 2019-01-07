# frozen_string_literal: true

# A class for defining global constants in a central place.
class AppConst
  # Constants for roles:
  ROLE_IMPLEMENTATION_OWNER = 'IMPLEMENTATION_OWNER'
  ROLE_CUSTOMER = 'CUSTOMER'
  ROLE_SUPPLIER = 'SUPPLIER'
  ROLE_TRANSPORTER = 'TRANSPORTER'

  # Menu
  FUNCTIONAL_AREA_RMD = 'RMD'

  # MesServer
  LABEL_SERVER_URI = ENV.fetch('LABEL_SERVER_URI')
  POST_FORM_BOUNDARY = 'AaB03x'

  # Labels
  SHARED_CONFIG_HOST_PORT = ENV.fetch('SHARED_CONFIG_HOST_PORT')
  LABEL_VARIABLE_SETS = ENV.fetch('LABEL_VARIABLE_SETS').strip.split(',')

  # Label sizes. The arrays contain width then height.
  LABEL_SIZES = Hash[[
    [84,   64],
    [84,  100],
    [97,   78],
    [78,   97],
    [77,  130],
    [100,  70],
    [100,  84],
    [100, 100],
    [105, 250],
    [130, 100],
    [145,  50]
  ].map { |w, h| ["#{w}x#{h}", { 'width': w, 'height': h }] }].freeze

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
  SYSTEM_MAIL_SENDER = ENV.fetch('SYSTEM_MAIL_SENDER')
end
