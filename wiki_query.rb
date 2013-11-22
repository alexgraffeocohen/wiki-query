require 'csv'
require 'httparty'
require 'uri' 

# VARIABLES

base_wiki_url = 'http://en.wikipedia.org/w/api.php?action=query&prop=info&inprop=url&titles=Barack%20obama&redirects&format=json'
base_freebase_url = 'https://www.googleapis.com/freebase/v1/mqlread?query={"mid":null,"id":null,"key":{"namespace":"/wikipedia/en_id","value":"wikikey","limit":1}}'
i = 0
no_page_iterator = 0
no_page_count = 0
multi_page_iterator = 0
multi_page_count = 0
loop_count = 0
missing_freebase_iterator = 0
missing_freebase_count = 0
clean_count = 0
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

# SCRIPT

CSV.foreach('test.csv') { |csv|
	row = csv

	#WIKIPEDIA API

	wiki_call = HTTParty.get(URI.encode(base_wiki_url.gsub(/Barack%20obama/, row[3].to_s)))
	puts "Made Wikipedia query for #{row[3]}..."
	wiki_call_pages = wiki_call["query"]["pages"]

	if wiki_call_pages.keys == ["-1"]
		if no_page_iterator < 1
			CSV.open('missing.csv', mode = "w") { |missing|
				missing << row
			}
			no_page_iterator += 1
			no_page_count += 1
			puts "No entry found! Logged to missing.csv."
			puts "Sleeping..."
			sleep 1
			loop_count += 1
			puts "-----------"
			next
		else
			CSV.open('missing.csv', mode = "a+") { |missing|
				missing << row
			}
			no_page_count += 1
			puts "No entry found! Logged to missing.csv."
			puts "Sleeping..."
			sleep 1
			loop_count += 1
			puts "-----------"
			next
		end
	end

	if wiki_call_pages.keys[1] != nil
		if multi_page_iterator < 1
			CSV.open('multiple.csv', mode = "w") { |multiple|
				multiple << row
			}
			multi_page_iterator += 1
			multi_page_count += 1
			puts "Multiple entries found! Logged to multiple.csv."
			puts "Sleeping..."
			sleep 1
			loop_count += 1
			puts "-----------"
			next
		else
			CSV.open('multiple.csv', mode = "a+") { |multiple|
				multiple << row
			}
			multi_page_count += 1
			puts "Multiple entries found! Logged to multiple.csv."
			puts "Sleeping..."
			sleep 1
			loop_count += 1
			puts "-----------"
			next
		end
	end

	row[10] = wiki_call_pages.values.first.values[0]
	row[11] = wiki_call_pages.values.first.values[9]
	row[12] = wiki_call_pages.values.first.values[2]

	# FREEBASE API

	freebase_call = HTTParty.get(URI.encode(base_freebase_url.gsub(/wikikey/, row[10].to_s)))
	puts "Made Freebase query for Wiki ID##{row[10]}..."

	if freebase_call["result"] == nil
		if missing_freebase_iterator < 1
			CSV.open('missing_freebase.csv', mode = "w") { |missing|
				missing << row
			}
			missing_freebase_iterator += 1
			missing_freebase_count += 1
			puts "Missing freebase entry! Logged to missing_freebase.csv"
			puts "Sleeping..."
			sleep 1
			loop_count += 1
			puts "-----------"
			next
		else
			CSV.open('missing_freebase.csv', mode = "a+") {|missing|
				missing << row
			}
			missing_freebase_count +=1
			puts "Missing freebase entry! Logged to missing_freebase.csv"
			puts "Sleeping..."
			sleep 1
			loop_count += 1
			puts "-----------"
			next
		end
	end

	row[14] = freebase_call["result"]["id"]
	row[15] = freebase_call["result"]["mid"]

	# WRITE OUT TO NORMAL.CSV

	if i < 1
		CSV.open('normal.csv', mode = "w") { |file|
			file << row
			i += 1
		}
	else
		CSV.open('normal.csv', mode = "a+") { |file|
			file << row
		}
	end

	puts "Sleeping..."
	sleep 1
	loop_count += 1
	clean_count += 1
	puts "-----------"
}

puts "Done! Completed #{loop_count} rows. #{clean_count} were clean. #{no_page_count} logged to missing.csv. #{multi_page_count} logged to multiple.csv. #{missing_freebase_count} logged to missing_freebase.csv."

