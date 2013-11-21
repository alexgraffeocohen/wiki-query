require 'csv'
require 'httparty'
require 'uri' 

# VARIABLES

base_url = 'http://en.wikipedia.org/w/api.php?action=query&prop=info&inprop=url&titles=Barack%20obama&redirects&format=json'
i = 0
no_page_iterator = 0
no_page_count = 0
multi_page_iterator = 0
multi_page_count = 0
loop_count = 0

# PROGRAM

CSV.foreach('test.csv', { encoding: "UTF-8"}) { |csv|

	# READ CSV, CALL API

	row = csv
	break if row[0] == ";" #END OF CSV FILE
	start_time = Time.now
	api_call = HTTParty.get(URI.encode(base_url.gsub(/Barack%20obama/, row[3].to_s)))
	end_time = Time.now
	puts "Made query"
	time_interval = end_time - start_time
	api_call_pages = api_call["query"]["pages"]

	# IF THERE ARE NO PAGES

	if api_call_pages.keys == ["-1"]
		if no_page_iterator < 1
			CSV.open('missing.csv', mode = "w") { |missing|
				missing << row
			}
			no_page_iterator += 1
			no_page_count += 1
			next
		else
			CSV.open('missing.csv', mode = "a+") { |missing|
				missing << row
			}
			no_page_count += 1
			next
		end
	end

	# IF THERE ARE MULTIPLE PAGES

	if api_call_pages.keys[1] != nil
		if multi_page_iterator < 1
			CSV.open('multiple.csv', mode = "w") { |missing|
				missing << row
			}
			multi_page_iterator += 1
			multi_page_count += 1
			next
		else
			CSV.open('multiple.csv', mode = "a+") { |missing|
				missing << row
			}
			multi_page_count += 1
			next
		end
	end

	# IF NORMAL

	row[10] = api_call_pages.values.first.values[0]
	row[11] = api_call_pages.values.first.values[9]
	row[12] = api_call_pages.values.first.values[2]
	print row

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
	loop_count += 1
}

puts "Done! Completed #{loop_count} queries. #{no_page_count} were logged to missing.csv. #{multi_page_count} were logged to multiple.csv."

