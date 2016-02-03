require 'rubygems'
require 'net/http'
require 'uri'
require 'json'

module AfricasTalkingGateway

class AfricasTalkingGatewayException < Exception
end

class SMSMessages
	attr_accessor :id, :text, :from, :to, :linkId, :date

	def initialize(id_, text_, from_, to_, linkId_, date_)
		@id     = id_
		@text   = text_
		@from   = from_
		@to     = to_
		@linkId = linkId_
		@date   = date_
	end
end

class StatusReport
	attr_accessor :number, :status, :cost, :messageId

	def initialize(number_, status_, cost_,messageId_)
		@number = number_
		@status = status_
		@cost   = cost_
		@messageId = messageId_
	end
end

class PremiumSubscriptionNumbers
	attr_accessor :phoneNumber, :id

	def initialize(number_, id_)
		@phoneNumber = number_
		@id     = id_
	end
end

class AirtimeResult
	attr_accessor :amount, :phoneNumber, :requestId, :status, :errorMessage, :discount

	def initialize(status_, number_, amount_, requestId_, errorMessage_, discount_)
		@status       = status_
		@phoneNumber  = number_
		@amount       = amount_
		@requestId    = requestId_
		@errorMessage = errorMessage_
		@discount     = discount_
	end
end

class CallResponse
	attr_accessor :phoneNumber, :status

	def initialize(status_, number_)
		@status      = status_
		@phoneNumber = number_
	end
end

class QueuedCalls
	attr_accessor :numCalls, :phoneNumber, :queueName
	
	def initialize(number_, numCalls_, queueName_)
		@phoneNumber = number_
		@numCalls    = numCalls_
		@queueName   = queueName_
	end
end

class AfricasTalkingGateway

	SMS_URL          = 'https://api.africastalking.com/version1/messaging'
	VOICE_URL        = 'https://voice.africastalking.com'
	SUBSCRIPTION_URL = 'https://api.africastalking.com/version1/subscription'
	USERDATA_URL     = 'https://api.africastalking.com/version1/user'
	AIRTIME_URL      = 'https://api.africastalking.com/version1/airtime'

	HTTP_CREATED     = 201
	HTTP_OK          = 200

	#Set debug flag to to true to view response body
	DEBUG            = false
  

	def initialize(user_name,api_key)
		@user_name    = user_name
		@api_key      = api_key

		@response_code = nil
	end

	def sendMessage(recipients_, message_, from_ = nil, bulkSMSMode_ = 1, enqueue_ = 0, keyword_ = nil, linkId_ = nil, retryDurationInHours_ = nil)
		post_body = {
						'username'    => @user_name, 
						'message'     => message_, 
						'to'          => recipients_, 
						'bulkSMSMode' => bulkSMSMode_ 
					}
		if (from_ != nil)
			post_body['from'] = from_
		end

		if (enqueue_ > 0)
			post_body['enqueue'] = enqueue_
		end

		if (keyword_ != nil)
			post_body['keyword'] = keyword_
		end

		if (linkId_ != nil)
			post_body['linkId'] = linkId_
		end

		if (retryDurationInHours_ != nil)
			post_body['retryDurationInHours'] = retryDurationInHours_
		end

		response = executePost(SMS_URL, post_body)
		if @response_code == HTTP_CREATED
  			reports = JSON.parse(response,:quirks_mode=>true)["SMSMessageData"]["Recipients"].collect { |entry|
    			StatusReport.new entry["number"], entry["status"], entry["cost"], entry["messageId"]
  			}
  		return reports
		else
  			raise AfricasTalkingGatewayAfricasTalkingGatewayException, response
		end
	end

	def fetchMessages(last_received_id_)
		url = "#{SMS_URL}?username=#{@user_name}&lastReceivedId=#{last_received_id_}"
		response = executePost(url)
		if @response_code == HTTP_OK
			messages = JSON.parse(response, :quirky_mode => true)["SMSMessageData"]["Messages"].collect { |msg|
				SMSMessages.new msg["id"], msg["text"], msg["from"], msg["to"], msg["linkId"], msg["date"]
			}
			return messages
		else
			raise AfricasTalkingGatewayException, response
		end
	end

	def createSubcription(phone_number_, short_code_, keyword_)
		if(phone_number_.length == 0 || short_code.length == 0 || keyword_.length == 0)
			raise AfricasTalkingGatewayException, "Please supply phone number, short code and keyword"
		end
		
		post_body = {
						'username'    => @user_name,
						'phoneNumber' => phone_number_,
						'shortCode'   => short_code_,
						'keyword'     => keyword_
					}
		url      = "#{SUBSCRIPTION_URL}/create"
		response = executePost(url, post_body)
		if(@response_code == HTTP_CREATED)
			return JSON.parse(response, :quirky_mode => true)
		else
			raise AfricasTalkingGatewayException, response
		end
	end

	def deleteSubcription(phone_number_, short_code_, keyword_)
		if(phone_number_.length == 0 || short_code.length == 0 || keyword_.length == 0)
			raise AfricasTalkingGatewayException, "Please supply phone number, short code and keyword"
		end
		
		post_body = {
						'username'    => @user_name,
						'phoneNumber' => phone_number_,
						'shortCode'   => short_code_,
						'keyword'     => keyword_
					}
		url = "#{SUBSCRIPTION_URL}/delete"

		response = executePost(url, post_body)

		if(@response_code == HTTP_CREATED)
			return JSON.parse(response, :quirky_mode => true)
		else
			raise AfricasTalkingGatewayException, response
		end
	end

	def fetchPremiumSubscriptions(short_code_, keyword_, last_received_id_ = 0)
		if(short_code_.length == 0 || keyword_.length == 0)
			raise AfricasTalkingGatewayException, "Please supply the short code and keyword"
		end

		url = "#{SUBSCRIPTION_URL}?username=#{@user_name}&shortCode=#{short_code_}&keyword=#{keyword_}&lastReceivedId=#{last_received_id_}"

		response = executePost(url)

		if(@response_code == HTTP_OK)
			subscriptions = JSON.parse(response)['responses'].collect{ |subscriber|
				PremiumSubscriptionNumbers.new subscriber['phoneNumber'], subscriber['id']
			}
			return subscriptions
		else
			raise AfricasTalkingGatewayException, response
		end
	end

	def call(from_, to_)
		post_body = {
						'username' => @user_name, 
						'from'     => from_, 
						'to'       => to_ 
					}
		response = executePost("#{VOICE_URL}/call", post_body)
		if(@response_code == HTTP_OK || @response_code == HTTP_CREATED)
			jObject = JSON.parse(response, :quirky_mode => true)

			if (jObject['errorMessage'] == "None")
				results = jObject['entries'].collect{|result|
					CallResponse.new result['status'], result['phoneNumber']
				}
				return results
			end

			raise AfricasTalkingGatewayException, jObject['errorMessage']
		end

		raise AfricasTalkingGatewayException, response
	end

	def getNumQueuedCalls(phone_number_, queue_name_ = nil)
		post_body = {
						'username'    => @user_name,
						'phoneNumbers' => phone_number_,
					}
		if (queue_name_ != nil)
			post_body['queueName'] = queue_name_
		end
		url = "#{VOICE_URL}/queueStatus"
		response = executePost(url, post_body)

		jsObject = JSON.parse(response, :quirky_mode => true)
		
		if(@response_code == HTTP_OK || @response_code == HTTP_CREATED)
			if (jsObject['errorMessage'] == "None")
				results = jsObject['entries'].collect{|result|
					QueuedCalls.new result['phoneNumber'], result['numCalls'], result['queueName']
				}
				return results
			end

			raise AfricasTalkingGatewayException, jsObject['errorMessage']
		end
		
		raise AfricasTalkingGatewayException, response
	end

	def uploadMediaFile(url_string_)
		post_body = {
						'username' => @user_name,
						'url'      => url_string_
					}
		url      = "#{VOICE_URL}/mediaUpload"
		response = executePost(url, post_body)

		jsObject = JSON.parse(response, :quirky_mode => true)

		raise AfricasTalkingGatewayException, jsObject['errorMessage'] if jsObject['errorMessage'] != "None"
	end

	def sendAirtime(recipients_)
		recipients = recipients_.to_json
		post_body = {
						'username'   => @user_name,
						'recipients' => recipients
					}
		url      = "#{AIRTIME_URL}/send"
		response = executePost(url, post_body)
		if (@response_code == HTTP_CREATED)
			responses = JSON.parse(response)['responses']
			if (responses.length > 0)
				results = responses.collect{ |result|
					AirtimeResult.new result['status'], result['phoneNumber'],result['amount'],result['requestId'], result['errorMessage'], result['discount']
				}
				return results
			else
				raise AfricasTalkingGatewayException, response['errorMessage']
			end
		else
			raise AfricasTalkingGatewayException, response
		end

	end

	def getUserData()
		url      = "#{USERDATA_URL}?username=#{@user_name}"
		response = executePost(url)
		if (@response_code == HTTP_OK)
			result = JSON.parse(response, :quirky_mode =>true)['UserData']
			return result
		else
			raise AfricasTalkingGatewayException, response
		end
	end

	def executePost(url_, data_ = nil)
		uri		 	     = URI.parse(url_)
		http		     = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl     = true

		if(data_ != nil)
		    request = Net::HTTP::Post.new(uri.request_uri)
			request.set_form_data(data_)
		else
		    request = Net::HTTP::Get.new(uri.request_uri)
		end
		request["apikey"] = @api_key
		request["Accept"] = "application/json"

		response          = http.request(request)

		if (DEBUG)
			puts "Full response #{response.body}"
		end

		@response_code = response.code.to_i
		return response.body
	end
end
end
