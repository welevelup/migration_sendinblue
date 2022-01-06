require 'net/http'
require 'uri'
require 'json'
require "rack-timeout"

# Call as early as possible so rack-timeout runs before all other middleware.
# Setting service_timeout or `RACK_TIMEOUT_SERVICE_TIMEOUT` environment
# variable is recommended. If omitted, defaults to 15 seconds.
use Rack::Timeout, service_timeout: 15


class Migrate
	def self.last_method(data_list, list, list_id, non_list_id, bad_emails)

		puts "Adding #{data_list.count} to #{list.name}"
	        to_create = create_data_list(data_list, list_id, bad_emails)

		if to_create.count != 0
			puts "to_create #{to_create.count}"
	    	non_list = create_contacts(to_create, list)

	    	if non_list != 0
		    	puts "Adding #{non_list.count} to NON list"
			    create_data_list(non_list, non_list_id, bad_emails)

			    puts "Adding #{non_list.count} to #{list.name}"
			    create_data_list(non_list, list_id, bad_emails)
			end
		end
	end

	def self.create_contacts(to_create, list)
	    non_list =[]

	    to_create.each do |m_to_create|
	    	m = list.members.find_by_email(m_to_create)
	    	if m
		    	url= "https://api.sendinblue.com/v3/contacts"
				uri = URI.parse(url)
				request = Net::HTTP::Post.new(uri)
				request.content_type = "application/json"
				request["Accept"] = "application/json"
				request["Api-Key"] = "HERE GOES THE API KEY FROM SENDINBLUE"
				request.body = JSON.dump({
							    "email": "#{m.email}",
							    "attributes": {
							      "NOMBRE":"#{m.first_name == nil ? "": m.first_name }",
							      "APELLIDOS":"#{m.last_name == nil ? "": m.last_name }",
							      "CONTACT": "#{m.contact == nil ? "" : m.contact }",
							      "SKYPE": "#{ (m.meta !=nil && m.meta.skype !=nil )? m.meta.skype : "" }",
							      "TWITTER":"#{(m.meta !=nil && m.meta.twitter !=nil) ? m.meta.twitter : ""}",
							      "Fecha de adicion": "#{m.created_at == nil ? "": m.created_at }",
							      "Ultima modificacion": "#{m.updated_at == nil ? "": m.updated_at }",
							      "JOINED_AT": "#{m.joined_at == nil ? "": m.joined_at }",
							      "ACTION_HISTORY": "#{m.action_history == nil ? "": m.action_history }",
							      "POINT_PERSON_ID": "#{m.point_person_id == nil ? "": m.point_person_id }",
							      "ROLE_ID": "#{m.role_id == nil ? "": m.role_id }",
							      "LAST_DONATED": "#{m.last_donated == nil ? "": m.last_donated }",
							      "DONATIONS_COUNT": "#{m.donations_count == nil ? "": m.donations_count }",
							      "AVERAGE_DONATION": "#{m.average_donation == nil ? "": m.average_donation }",
							      "HIGHEST_DONATION": "#{m.highest_donation == nil ? "": m.highest_donation }",
							      "MOSAIC_GROUP": "#{m.mosaic_group == nil ? "": m.mosaic_group }",
							      "MOSAIC_CODE": "#{m.mosaic_code == nil ? "": m.mosaic_code }",
							      "ENTRY_POINT": "#{m.entry_point == nil ? "": m.entry_point }",
							      "LATITUDE": "#{m.latitude == nil ? "": m.latitude }",
							      "LONGITUDE": "#{m.longitude == nil ? "": m.longitude }",
							      "TITLE": "#{m.title == nil ? "": m.title }",
							      "GENDER": "#{m.gender == nil ? "": m.gender }",
							      "DONATION_PREFERENCE": "#{m.donation_preference == nil ? "": m.donation_preference }"
							    }
			                            })

				req_options = {
				use_ssl: uri.scheme == "https",
				}

				response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
				http.request(request)
				end

		    	non_list << m.email
		    end
	    end
		
		return non_list
	end

	def self.create_data_list(data_list, list_id, bad_emails)
		url= "https://api.sendinblue.com/v3/contacts/lists/#{list_id}/contacts/add"
		uri = URI.parse(url)
		request = Net::HTTP::Post.new(uri)
		request.content_type = "application/json"
		request["Accept"] = "application/json"
		request["Api-Key"] = "HERE GOES THE API KEY FROM SENDINBLUE"
		request.body = JSON.dump({"emails": data_list })


		req_options = {
		use_ssl: uri.scheme == "https",
		}

		response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
		http.request(request)
		end
		
		if JSON.parse(response.body).has_value?("invalid_parameter")
			puts "ups we have a bad email or the email is already in the list"
			failures =[]

			data_list.each do |a|
				#puts a
				url= "https://api.sendinblue.com/v3/contacts/lists/#{list_id}/contacts/add"
				uri = URI.parse(url)
				request = Net::HTTP::Post.new(uri)
				request.content_type = "application/json"
				request["Accept"] = "application/json"
				request["Api-Key"] = "HERE GOES THE API KEY FROM SENDINBLUE"
				request.body = JSON.dump({"emails": [a] })

				req_options = {
				use_ssl: uri.scheme == "https",
				}

				response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
				http.request(request)
				end

				if JSON.parse(response.body).has_value?("Contact email addresses are invalid/ not in valid format") 
					puts "It was a Bad ass, adding #{a} to bademails"
					bad_emails << a
				elsif JSON.parse(response.body).has_value?("Contact already in list and/or does not exist")
				else
					failures << JSON.parse(response.body).contacts["failure"]
				end
			end

			return failures
		else
			return JSON.parse(response.body).contacts["failure"]
		end
	end

	def self.get_all_list
		lists =[]
		n=0
		# x is the number of pages in the list section. This means, it will check each page of lists. You will need to check your account for this number
		while n < x 
			url ="https://api.sendinblue.com/v3/contacts/lists?limit=50&offset=#{n}&sort=desc"
			uri = URI.parse(url)
			request = Net::HTTP::Get.new(uri)
			request["Accept"] = "application/json"
			request["Api-Key"] = "HERE GOES THE API KEY FROM SENDINBLUE"

			req_options = {
			  use_ssl: uri.scheme == "https",
			}

			response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
			  http.request(request)
			end
			lists << JSON.parse(response.body).lists
		 n=n+1
		end
		new_list =lists.flatten
		return new_list.uniq
	end

	def self.delete(id)
		uri = URI.parse("https://api.sendinblue.com/v3/contacts/lists/#{id}")
		request = Net::HTTP::Delete.new(uri)
		request["Accept"] = "application/json"
		request["Api-Key"] = "HERE GOES THE API KEY FROM SENDINBLUE"

		req_options = {
		  use_ssl: uri.scheme == "https",
		}

		response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
		  http.request(request)
		end
	end

	def self.create_list(list_name)
		url= "https://api.sendinblue.com/v3/contacts/lists"
		uri = URI.parse(url)
		request = Net::HTTP::Post.new(uri)
		request.content_type = "application/json"
		request["Accept"] = "application/json"
		request["Api-Key"] = "HERE GOES THE API KEY FROM SENDINBLUE"
		request.body = JSON.dump({
		                         "name" => "#{list_name}",
		                         "folderId" => 1
		                       })

		req_options = {
		use_ssl: uri.scheme == "https",
		}

		response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
		http.request(request)
		end
		
		return JSON.parse(response.body).id
	end
end

#puts "get all list"
list_ids = Migrate.get_all_list

#non_list_id = Migrate.create_list("Non list")
non_list_id = 187

bad_emails =[]

List.all.each_with_index do |list, index|
	
	puts "//#{index}//---------------------------------------------"
	puts list.name

	list_from_sending = list_ids.select{|x| x["name"] === list.name}
	puts "list_from_sending #{list_from_sending.count}"

	if list_from_sending.count > 0
		list_from_sending.each do |sending|
			members = list.members.count
			suscribers = sending.uniqueSubscribers
			
			puts "list.members.count #{members} // #{suscribers}"
			if suscribers.between?(members-40, members) 
				puts "Skyping_______" 
			end 
			next if suscribers.between?(members-40, members)
            
            puts "Deleting and stating again ..." 
			Migrate.delete(sending.id)
		end
		next if ((list_from_sending.first).uniqueSubscribers).between?(list.members.count-40, list.members.count)
	end
	
	puts "__________Creando #{list.name} ___________"

	list_id = Migrate.create_list(list.name)

	data_list = []
	n=1
	r=0
	final = list.members.count

	list.members.each do |member|
		r = r + 1
	    if n < 150
	       	data_list << member.email
	       	n = n + 1
	    else
            data_list << member.email

		    Migrate.last_method(data_list, list, list_id, non_list_id, bad_emails)

			n=1
		    data_list = []
		end

		if final === r
            
            Migrate.last_method(data_list, list, list_id, non_list_id, bad_emails)
            
	       n=0
	       data_list = []
		end
	end
end

puts "and the list of bad email is: #{bad_emails}"
