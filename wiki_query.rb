# CREATE A GUIDE STATING THE INPUT AND THE OUTPUT

require 'csv'
require 'httparty'

# VARIABLES

base_wiki_url = 'http://en.wikipedia.org/w/api.php?action=query&prop=info&inprop=url&titles=wikititle&redirects&format=json'
base_freebase_url = 'https://www.googleapis.com/freebase/v1/mqlread?query={"mid":null,"id":null,"key":{"namespace":"/wikipedia/en_id","value":"wikikey","limit":1}}'
loop_count = 0              # counts how many rows have been examined
no_page_count = 0           # counts how many rows are missing wiki pages
multi_page_count = 0        # counts how many rows have multiple wiki pages
missing_freebase_count = 0  # counts how many rows are missing freebase entries
clean_count = 0             # counts how many rows have no issues

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE    # necessary to force freebase query

# SCRIPT

CSV.foreach('test.csv') { |csv|
	row = csv
	nyt_wiki_title = row[3]
	
	#WIKIPEDIA API

	wiki_call = HTTParty.get(URI.encode(base_wiki_url.gsub(/wikititle/, nyt_wiki_title.to_s)))
	puts "Made Wikipedia query for #{row[3]}..."
	wiki_call_pages = wiki_call["query"]["pages"]

	# break this into a method and put a comment on the method

	if wiki_call_pages.keys == ["-1"]
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

	# break this into a method and put a comment on the method

	if wiki_call_pages.keys[1] != nil
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

	wiki_key = row[10] = wiki_call_pages.values.first.values[0] 
	wiki_url = row[11] = wiki_call_pages.values.first.values[9]
	wiki_title = row[12] = wiki_call_pages.values.first.values[2]

	# FREEBASE API

	freebase_call = HTTParty.get(URI.encode(base_freebase_url.gsub(/wikikey/, wiki_key.to_s)))
	puts "Made Freebase query for Wiki ID##{row[10]}..."

	if freebase_call["result"] == nil
		
		# break this into a method and put a comment on the method

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

	freebase_id = row[14] = freebase_call["result"]["id"]
	freebase_mid = row[15] = freebase_call["result"]["mid"]

	# WRITE OUT TO NORMAL.CSV

	CSV.open('normal.csv', mode = "a+") { |file|
			file << row
		}
	loop_count += 1
	clean_count += 1

	puts "Sleeping..."
	sleep 1
	puts "-----------"
}

puts "Done! Completed #{loop_count} rows. #{clean_count} were clean. #{no_page_count} logged to missing.csv. #{multi_page_count} logged to multiple.csv. #{missing_freebase_count} logged to missing_freebase.csv."

