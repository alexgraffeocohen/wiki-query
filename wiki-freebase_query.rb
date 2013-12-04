# CREATE A GUIDE STATING THE INPUT AND THE OUTPUT

require 'csv'
require 'httparty'

# VARIABLES

base_wiki_url = 'http://en.wikipedia.org/w/api.php?action=query&prop=info&inprop=url&titles=wiki-title&redirects&format=json'
base_freebase_url = 'https://www.googleapis.com/freebase/v1/mqlread?query={"mid":null,"id":null,"key":{"namespace":"/wikipedia/en_id","value":"wiki-id","limit":1}}'
loop_count = 0              # counts how many rows have been examined
no_page_count = 0           # counts how many rows are missing wiki pages
multi_page_count = 0        # counts how many rows have multiple wiki pages
missing_freebase_count = 0  # counts how many rows are missing freebase entries
clean_count = 0             # counts how many rows have no issues

# The script will add the below array as a header row to missing_wiki.csv, multiple_wiki.csv, and missing_freebcase.csv.
$header = ["Concept","Type","Relation","Link","Link Type","concept_id","concept_type_id","relation_id","link_id","link_type_id","Wikipedia Id","Wikipedia URL","Wikipedia Title","Wikidata ID","Freebase ID"]

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE    # necessary to force freebase query

# METHODS

def wiki_missing_pages       # writes rows that return no wiki entries to missing.csv
	CSV.open('missing_wiki.csv', mode = "a+", options = { headers: $header, write_headers: true }) { |missing_wiki|
		missing_wiki << $row
	}
	puts "No entry found! Logged to missing_wiki.csv."
	rest
end

def wiki_multiple_pages      # writes rows that return multiple wiki entries to multiple.csv
	CSV.open('multiple_wiki.csv', mode = "a+", options = { headers: $header, write_headers: true }) { |multiple_wiki|
		multiple_wiki << $row
	}
	puts "Multiple entries found! Logged to multiple_wiki.csv."
	rest
end

def freebase_missing_pages   # writes rows that return no freebase entries to missing_freebase.csv
	CSV.open('missing_freebase.csv', mode = "a+", options = { headers: $header, write_headers: true }) {|missing_freebase|
		missing_freebase << $row
	}
	puts "Missing freebase entry! Logged to missing_freebase.csv"
	rest
end

def rest            # inserts sleep interval
	puts "Sleeping..."
	sleep 1
	puts "-----------"
end

# SCRIPT

CSV.foreach('test.csv', options = { headers: true }) { |csv|      # replace 'test.csv' with input file
	$row = csv
	nyt_wiki_title = $row[3]
	
	#WIKIPEDIA API CALL

	wiki_call = HTTParty.get(URI.encode(base_wiki_url.gsub(/wiki-title/, nyt_wiki_title.to_s)))
	puts "Made Wikipedia query for #{$row[3]}..."
	wiki_call_pages = wiki_call["query"]["pages"]

	if wiki_call_pages.keys == ["-1"]   # execute if row does not return a wiki entry
		wiki_missing_pages
		no_page_count += 1
		loop_count += 1
		next
	end
	

	if wiki_call_pages.keys[1] != nil   # execute if row returns multiple wiki entries
		wiki_multiple_pages
		multi_page_count += 1
		loop_count += 1
		next
	end

	wiki_id = $row[10] = wiki_call_pages.values.first.values[0] 
	wiki_url = $row[11] = wiki_call_pages.values.first.values[9]
	wiki_title = $row[12] = wiki_call_pages.values.first.values[2]

	# FREEBASE API CALL

	freebase_call = HTTParty.get(URI.encode(base_freebase_url.gsub(/wiki-id/, wiki_id.to_s)))
	puts "Made Freebase query for Wiki ID##{$row[10]}..."

	if freebase_call["result"] == nil   # execute if row does not return a freebase entry
		freebase_missing_pages
		missing_freebase_count +=1
		loop_count += 1
		next
	end

	freebase_id = $row[14] = freebase_call["result"]["id"]
	freebase_mid = $row[15] = freebase_call["result"]["mid"]

	# WRITE OUT TO NORMAL.CSV

	CSV.open('normal.csv', mode = "a+", options = { headers: $header, write_headers: true }) { |file|
			file << $row
		}
	loop_count += 1
	clean_count += 1
	rest
}

puts "Done! Completed #{loop_count} rows. #{clean_count} were clean. #{no_page_count} logged to missing.csv. #{multi_page_count} logged to multiple.csv. #{missing_freebase_count} logged to missing_freebase.csv."