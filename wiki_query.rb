require 'csv'
require 'httparty' 

# VARIABLES

base_url = 'http://en.wikipedia.org/w/api.php?action=query&prop=info&inprop=url&titles=Barack%20obama&redirects&format=json'
i = 0
no_page_iterator = 0

# PROGRAM

CSV.foreach('test.csv') { |csv|
	# READ CSV, CALL API

	row = csv
	start_time = Time.now
	puts "Start Time:\t#{start_time}\n"
	api_call = HTTParty.get(base_url.gsub(/Barack%20obama/, row[3].to_s))
	end_time = Time.now
	puts "End Time:\t#{end_time}\n"
	time_interval = end_time - start_time
	puts "Time Interval:\t#{time_interval}\n"
	api_call_pages = api_call["query"]["pages"]

	# IF THERE ARE NO PAGES

	if api_call_pages.keys == ["-1"]
		if no_page_iterator < 1
			CSV.open('missing.csv', mode = "w") { |missing|
				missing << row
				no_page_iterator += 1
			}
			next
		else
			CSV.open('missing.csv', mode = "a+") { |missing|
				missing << row
			}
			next
		end
	end

	# IF NORMAL

	row[10] = api_call_pages.values.first.values[0]
	row[11] = api_call_pages.values.first.values[9]
	row[12] = api_call_pages.values.first.values[2]

	# WRITE IN-PLACE

	if i < 1
		CSV.open('test.csv', mode = "w") { |file|
			file << row
			i += 1
		}
	else
		CSV.open('test.csv', mode = "a+") { |file|
			file << row
		}
	end

	# SLEEP

	if time_interval > 1
		sleep_time = 1
	else
		sleep_time = 1 - (time_interval)
	end
	puts "Sleep Time:\t#{sleep_time}\n"
	sleep sleep_time
}

