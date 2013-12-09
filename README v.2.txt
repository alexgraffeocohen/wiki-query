# WIKI-FREEBASE_QUERY

## Summary

This script queries both Wikipedia and Freebase for additional data on Times tags. It takes a CSV file as input and reads that file line by line. It first looks for a Wiki Title in index position [3] and uses it to query the Wikipedia API for a Wikpedia ID, official Wikpedia URL, and official Wikipedia Title. The script then uses the Wikipedia ID drawn from the Wiki API to query the Freebase API for a Freebase ID and Freebase Mid.

All functionality is defined in class methods within a Querier class:
- self.log_missing_wiki: writes rows that return no wiki entries to missing_wiki.csv
- self.log_multiple_wiki: writes rows that return multiple wiki entries to multiple_wiki.csv
- self.log_missing_freebase: writes rows that return no freebase entries to missing_freebase.csv
- self.log_clean_rows: writes rows that return all requested data to clean.csv
- self.rest: inserts sleep interval after API calls
- self.make_query: uses above methods to make queries, fill in data, and log each row in the CSV file

Set the filename in Line 103 of self.make_query to 'test.csv' to test out the script with the included test file. The filename is set to 'test.csv' by default.

## Requirements

The CSV file used as input must be formatted in exactly the same way as the provided test.csv file. In other words, it must include the same header as test.csv and elements must be ordered exactly as they are in test.csv. Otherwise, the script will not query the Wikipedia API (or the Freebase API) for the correct entry and the output files will not be generated properly.

Ruby 1.9.3 is required, since that's what the httparty gem requires.

## To Run

Change the filename in Line 103 of self.make_query from 'test.csv' to the name of your input file. Make sure that the file is located in the same directory as the script. The script will execute self.rest after each API call, regardless of the status of the row. The script is designed so that rows are appended to clean.csv, missing_wiki.csv, multiple_wiki.csv, or missing_freebase.csv without overwriting any of the files should they already exist. Keep that in mind when running the script multiple times, since this behavior could result in log files that you don't expect.

## Script Walkthrough
	
	CSV.foreach('input.csv', options = { headers: true }) do |csv|
	
	# insert your input filename above      
	@@row = csv
	# the CSV row has been converted into a Ruby array named @@row
	nyt_wiki_title = @@row[3]
	
	#WIKIPEDIA API CALL
	
	base_wiki_url = 'http://en.wikipedia.org/w/api.php?	action=query&prop=info&inprop=url&titles=wiki-	title&redirects&format=json'
	wiki_call = HTTParty.get(URI.encode(base_wiki_url.gsub(/wiki-	title/, 	nyt_wiki_title.to_s)))
	# a URI is generated with the nyt_wiki_title provided by @@row
	puts "Made Wikipedia query for #{@@row[3]}..."
	wiki_call_pages = wiki_call["query"]["pages"]

	if wiki_call_pages.keys == ["-1"]   
	# executed if the API call does not return a wiki entry
		Querier.log_missing_wiki
		# method appends row to missing_wiki.csv
		next  # script goes to the next row in the input CSV file
	end

	if wiki_call_pages.keys[1] != nil   
	# executed if API call returns multiple wiki entries
		Querier.log_multiple_wiki  
		# method appends row to multiple_wiki.csv
		next 
	end

	wiki_id = @@row[10] = wiki_call_pages.values.first.values[0] 
	wiki_url = @@row[11] = wiki_call_pages.values.first.values[9]
	wiki_title = @@row[12] = wiki_call_pages.values.first.values[2]
	
	# FREEBASE API CALL
	base_freebase_url = 'https://www.googleapis.com/freebase/v1/	mqlread?query={"mid":null,"id":null,"key":{"namespace":"/wikipedia/	en_id","value":"wiki-id","limit":1}}'
	freebase_call = HTTParty.get(URI.encode(base_freebase_url.gsub(/	wiki-id/, wiki_id.to_s)))
	# a URI is generated with the wiki_id provided by Wikipedia API
	puts "Made Freebase query for Wiki ID##{@@row[10]}..."

	if freebase_call["result"] == nil   
	# executed if API call does not return a freebase entry
		Querier.log_missing_freebase
		# method appends row to missing_freebase.csv
		next 
	end

	freebase_id = @@row[14] = freebase_call["result"]["id"]
	freebase_mid = @@row[15] = freebase_call["result"]["mid"]

	# IFF ALL DATA FOUND, WRITE OUT TO clean.csv

	Querier.log_clean_rows
	# method appends row to clean.csv
		
	end


