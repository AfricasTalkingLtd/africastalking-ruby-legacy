# Africastalking::Ruby

Official AfricasTalking Ruby API wrapper

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'africastalking-ruby'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install africastalking-ruby

## Usage

### Sending a message

```ruby
# Include the helper gateway class
require './AfricasTalkingGateway'

username = "MyAfricasTalkingUsername";
apikey   = "MyAfricasTalkingAPIKey";

# Specify the numbers that you want to send to in a comma-separated list
# Please ensure you include the country code (+254 for Kenya)
to      = "+254711XXXYYY,+254733YYYZZZ";

message = "I'm a lumberjack and it's ok, I sleep all night and I work all day"

gateway = AfricasTalkingGateway.new(username, apikey)

begin
  # Thats it, hit send and we'll take care of the rest.
  reports = gateway.sendMessage(to, message)
  
  reports.each {|x|
    # status is either "Success" or "error message"
    puts 'number=' + x.number + ';status=' + x.status + ';messageId=' + x.messageId + ';cost=' + x.cost
  }
rescue AfricasTalkingGatewayException => ex
  puts 'Encountered an error: ' + ex.message
end
```


### Fetching messages


```ruby
# Be sure to import the helper gateway class
require './AfricasTalkingGateway'

# Specify your login credentials
username = 'MyUsername'
apikey   = 'MyApikey'

# Create a new instance of our awesome gateway class
gateway = AfricasTalkingGateway.new(username, apikey)

begin
  # Our gateway will return 10 messages at a time back to you, starting with
  # what you currently believe is the lastReceivedId. Specify 0 for the first
  # time you access the gateway, and the ID of the last message we sent you
  # on subsequent results
  last_received_id = 0

  while true
    messages = gateway.fetch_messages(last_received_id)
    messages.each {|x|
      puts 'from=' + x.from + 'to=' + x.to + ';text=' + x.text + ';linkId=' + x.linkId + ';date=' + x.date
      last_received_id = x.id
    }
    break if messages.length == 0
  end

rescue AfricasTalkingGatewayException => ex

  puts 'Encountered an error: ' + ex.message

end
```


### Making a call

```ruby
# Include the helper gateway class
require './AfricasTalkingGateway'

# Specify your login credentials
username = "MyAfricasTalking_Username";
apikey   = "MyAfricasTalking_APIKey";

# Specify your Africa's Talking phone number in international format
callFrom = "+254711082XYZ";

# Specify the numbers that you want to call to in a comma-separated list
# Please ensure you include the country code (+254 for Kenya)
callTo   = "+254711XXXYYY,+254733YYYZZZ";

# Create a new instance of our awesome gateway class
gateway  = AfricasTalkingGateway.new(username, apikey)

begin
  # Make the call
  results = gateway.call(callFrom, callTo)
  
  results.each {|result|
      puts ' Status=' + result.status + ';phoneNumber=' + result.phoneNumber
  }
  puts "Calls have been initiated. Time for song and dance!\n";

rescue AfricasTalkingGatewayException => ex
  puts 'Encountered an error: ' + ex.message
end
```

### Sending airtime

```ruby
# Include the helper gateway class
require './AfricasTalkingGateway'

# Specify your login credentials
username = "MyAfricasTalkingUsername";
apikey   = "MyAfricasTalkingAPIKey";

#Create an array to hold all the recipients
recipients = Array.new

#Add the first recipient
recipients[0] = {"phoneNumber" => "+254711XXXYYY", "amount" => "KES XX"}

# Create a new instance of our awesome gateway class
gateway = AfricasTalkingGateway.new(username, apikey)

begin
  results = gateway.sendAirtime(recipients)
  results.each {|x|
    puts 'number=' + x.phoneNumber + '; status=' + x.status + '; requestId=' + x.requestId + '; amount=' + x.amount + "; discount=" + x.discount
    puts 'ErrorMessage=' + x.errorMessage
  }
rescue AfricasTalkingGatewayException => ex
  puts 'Encountered an error: ' + ex.message
end
```

### Checking balance (User-data)

```ruby
# Include the helper gateway class
require 'AfricasTalkingGateway'

# Specify your login credentials
username = "MyAfricasTalking_Username";
apikey   = "MyAfricasTalking_APIKey";


# Create a new instance of our awesome gateway class
gateway = AfricasTalkingGateway.new(username, apikey)

begin
    user = gateway.getUserData()
    puts user['balance']
rescue AfricasTalkingGatewayException => ex
    puts "Encountered an error: " + ex.message
end
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/AfricasTalkingLtd/africastalking-ruby.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
