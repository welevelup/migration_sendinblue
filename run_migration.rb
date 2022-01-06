#!/usr/bin/ruby -w

require 'net/http'
require 'uri'
require 'json'
require "rack-timeout"

# Call as early as possible so rack-timeout runs before all other middleware.
# Setting service_timeout or `RACK_TIMEOUT_SERVICE_TIMEOUT` environment
# variable is recommended. If omitted, defaults to 15 seconds.
use Rack::Timeout, service_timeout: 15

require File.join(File.dirname(__FILE__), 'migration.rb')

puts "Welcome to the Migration !"

migrate = Migrate.new()

index=0

List.all.each do |list|
  index=index+1

  puts "////////////////////////////////////// #{index}"

  #crear lista
  puts "creando #{list.name}"
  list_id = migrate.creating_or_finding_list(list.name)

  data_list = []

  n=0
  non=0

  list.members.each do |m|
      if n < 150
        n=n+1
          data_list << m.email
      else
        #add contact to the list
        puts "addind #{data_list.count} to the list"

          to_create = migrate.sending_to_list(data_list, list_id)
            to_create.each do |m_to_create|
              member = list.members.find_by_email(m_to_create)
              Migrate.create_contact(member)
              non_list << m_to_create
              non = non+1
            end
        n=0
        data_list = []

        if non.count == 150
          #add contact to the Non list
          puts "addind #{non_list.count} to the NON list"
          migrate.sending_to_list(non_list, 68)
          non = 0
        end
      end
  end
end