require 'sinatra'
require 'sinatra/partial'
require 'sinatra/reloader' if development?

configure do
  redisUri = ENV["REDISTOGO_URL"] || 'redis://localhost:6379'
  uri = URI.parse(redisUri) 
  $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
end

twitter_client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV['twitter_consumer_key']
  config.consumer_secret     = ENV['twitter_consumer_secret']
  config.access_token        = ENV['twitter_access_token']
  config.access_token_secret = ENV['twitter_access_token_secret']
end

twitter_people = [
	"bbc",
	"theatlantic",
	"columbiapsych",
	"livescience",
	"zuckermanbrain",
	"newyorker",
	"novapbs",
	"nytimes",
	"sciam",
	"washingtonpost"
]

twitter_terms = [
	"neuroscience",
	"neuron",
	"neurons",
	"brain"
]

get '/' do
    erb :main, :layout => :main_layout, :locals => {

    }
end

get '/twitter/' do
	content_type :json

	tweets = []

	twitter_people.each do |person|
		puts "checking twitter of: #{person}"

		search_results = twitter_client.user_timeline(person, {:count => 10})

		search_results.each do |tweet|
			t_id = tweet.id

			# t = $redis.get("syntweet:#{t_id}")
			# if !t
				t_text = tweet.text
				t_name = tweet.user.screen_name

				if twitter_terms.any? { |word| t_text.include?(word) }
					tweet_obj = { :text => t_text, :name => t_name, :type => "tweet" }
					tweets.push( tweet_obj )

					# $redis.set("syntweet:#{t_id}", tweet_object.to_json)

					puts "found tweet... stored."

					if tweet.entities? and tweet.urls?
						puts "checking for linked URLs..."
						tweet.urls.each do |url|
							begin
							  page = MetaInspector.new(url.expanded_url, faraday_options: { ssl: { verify: false } })
							rescue Faraday::RedirectLimitReached
							else
								if page.meta['og:description']
									tweet_obj = { :text => page.meta['og:description'], :name => t_name, :type => "meta" }
									tweets.push( tweet_obj )
									puts "found og:description... stored."
								elsif page.meta['description']
									tweet_obj = { :text => page.meta['description'], :name => t_name, :type => "meta" }
									tweets.push( tweet_obj )
									puts "found description... stored."
								end
							end
						end
					elsif tweet.media?
						puts "checking for images..."
						tweet.media.each do |media|
							if media.to_hash[:type] == "photo"
								tweet_obj = { :text => media.media_url, :name => t_name, :type => "image" }
								tweets.push( tweet_obj )
								puts "found image url... stored."
							end
						end
					end
				end
				
			# end
		end

		sleep 0.250
	end

	twitter_terms.each do |term|
		twitter_client.search(term, lang: "en", result_type: "recent").take(4).collect do |tweet|
			t_id = tweet.id
			t_text = tweet.text
			t_name = tweet.user.screen_name

			tweet_obj = { :text => t_text, :name => t_name, :type => "random" }
			tweets.push( tweet_obj )
		end
	end

	data = { :result => "success", :tweets => tweets }.to_json

	File.open("public/snapshot.json","w") do |f|
  		f.write(data)
	end
  	
  	return data
end


