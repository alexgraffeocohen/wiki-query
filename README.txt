# WIKI-FREEBASE_QUERY

## Summary

This script queries both Wikipedia and Freebase for additional data on Times tags. It takes a CSV file as input and reads that file line by line. It first looks for a Wiki Title, which it uses to query the Wikipedia API for a Wikpedia ID, official Wikpedia URL, and official Wikipedia Title. The script then uses the Wikipedia ID to query the Freebase API for a Freebase ID and Freebase Mid.

The script can account for the following conditions:
1.  If the Wikipedia API returns no entries, then the row is logged to missing_wiki.csv and the script moves on to the next row.
2. If the Wikipedia API returns multiple entries, then the row is logged to multiple_wiki.csv and the script moves on to the next row.
3. If the Freebase API returns no entires, then the row is logged to missing_freebase.csv and the scripts moves on to the next row.
	
If none of these conditions are true, then the row is logged to normal.csv. Set the filename in Line 55 of the script to 'test.csv' to test out the script. The filename is set that way by default.

## Requirements

The CSV file used as input must be formatted in exactly the same way as the provided test.csv. In other words, it must include the same header as test.csv and elements must be ordered exactly as they are in test.csv. Otherwise, the script will not query the Wikipedia API (or the Freebase API) for the correct entry.

Ruby 1.9.3 is required, since  

## To Run

Change the filename in Line 55 of the script from 'test.csv' to the name of your input file. Make sure that the file is located in the same directory as the script. The script will "sleep" for 1 second after each row has been processed out of politeness. The script is designed so that rows are appended to normal.csv, missing_wiki.csv, multiple_wiki.csv, or missing_freebase.csv without overwriting any of the files should they already exist. Keep that in mind when running the script multiple times, since this behavior could result in unexpected log files.

## Walkthrough
	
	CSV.foreach('input.csv', options = { headers: true }) { |csv|
	# insert your input filename above      
	$row = csv
	# the CSV row has been converted into a Ruby array named $row
	nyt_wiki_title = $row[3]
	
	#WIKIPEDIA API CALL

	wiki_call = HTTParty.get(URI.encode(base_wiki_url.gsub(/wiki-	title/, 	nyt_wiki_title.to_s)))
	# a URI is generated with the nyt_wiki_title provided by $row
	puts "Made Wikipedia query for #{$row[3]}..."
	wiki_call_pages = wiki_call["query"]["pages"]

	if wiki_call_pages.keys == ["-1"]   
	# executed if the API call does not return a wiki entry
		wiki_missing_pages  # method appends row to missing_wiki.csv
		no_page_count += 1
		loop_count += 1
		next  # script goes to the next row in the input CSV file
	end

	if wiki_call_pages.keys[1] != nil   
	# executed if API call returns multiple wiki entries
		wiki_multiple_pages  # method appends row to multiple_wiki.csv
		multi_page_count += 1
		loop_count += 1
		next  # script goes to the next row in the input CSV file
	end

	wiki_id = $row[10] = wiki_call_pages.values.first.values[0] 
	wiki_url = $row[11] = wiki_call_pages.values.first.values[9]
	wiki_title = $row[12] = wiki_call_pages.values.first.values[2]
	
	
	# FREEBASE API CALL

	freebase_call = HTTParty.get(URI.encode(base_freebase_url.gsub(/	wiki-id/, wiki_id.to_s)))
	# a URI is generated with the wiki_id provided by Wikipedia API
	puts "Made Freebase query for Wiki ID##{$row[10]}..."

	if freebase_call["result"] == nil   
	# executed if API call does not return a freebase entry
		freebase_missing_pages
		missing_freebase_count +=1
		loop_count += 1
		next  # script goes to the next row in the input CSV file
	end

	freebase_id = $row[14] = freebase_call["result"]["id"]
	freebase_mid = $row[15] = freebase_call["result"]["mid"]

	# WRITE OUT TO NORMAL.CSV

	CSV.open('normal.csv', mode = "a+", options = { headers: $header, 	write_headers: true }) { |file|
	# script inserts provided array of header labels as a header row in CSV 	file
			file << $row
		}
	loop_count += 1
	clean_count += 1
	rest  # method sleeps program for one second
	}


