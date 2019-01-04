Mail.defaults do
  if ENV['RACK_ENV'] == 'test'
    delivery_method :test
  elsif ENV['RACK_ENV'] == 'development'
    delivery_method :logger
  else
    delivery_method :smtp,
                    address: 'smtp.dsl.telkomsa.net',
                    port: 25
  end

  # Test/dev:
  # delivery_method :logger

  # Example SMTP delivery:
  # delivery_method :smtp,
  #                 address: 'smtp.dsl.telkomsa.net',
  #                 port: 25

  # Example Gmail delivery:
  # delivery_method :smtp,
  #                 address: 'smtp.gmail.com',
  #                 port: 587,
  #                 user_name: ENV['GMAIL_SMTP_USER'],
  #                 password: ENV['GMAIL_SMTP_PASSWORD'],
  #                 authentication: :plain,
  #                 enable_starttls_auto: true

  # Office365 delivery:
  # See https://github.com/mikel/mail/wiki/Sending-email-via-Office365

  # Exim delivery:
  # delivery_method :exim,
  #                 location: '/usr/bin/exim'
end
