# Based on example from: http://kevinquillen.com/programming/2014/06/26/more-ruby-scraping-madness
#
# https://github.com/httprb/http
require "http"
require "nokogiri"

# Use xpath to extract each specific element we want. 
#

def scrape(page,xpath)
	page.xpath(xpath).map do |item|
		if item['class'] == "list_captions"
			next
		end
	
		image = item.at_xpath('./a/div/div/*[@class="hide product_image"]/@data-src') # ..//image_container/product_image_wrap
		image = image.to_s.gsub('&dc=1&sr.fs=20000','')
		yajproxy = "https://buyee.jp#{item.at_xpath('.//a/@href')}"
		yajproxy = yajproxy.split("?")[0]
		title = item.at_xpath('.//a/div/*[@class="product_title"]/text()').to_s.strip
		price = item.at_xpath('.//a/div/*[@class="product_price"]/text()').to_s.strip

		puts "<a href=\"#{yajproxy}\"><img src=\"#{image}\"></img></a><br>"
		puts "#{title}<br>"
		puts "#{price}<br>"
		puts "<br>"
	end
end

# Search for AAAAAAAAAAAAAAA in Arcade Games Category
# https://buyee.jp/item/search/query/AAAAAAAAAAAAAAA/category/2084047781
#

def hunt(category,terms)

	puts "<meta charset=\"utf-8\"/>"
	
	endpoint = "https://buyee.jp/item/search/query/#{terms}/category/#{category}"
	puts "Hitting Endpoint: #{endpoint}<br>"
	body = HTTP.get(endpoint).to_s

	page = Nokogiri::HTML(body, nil, 'utf-8');
	numpages = page.at_xpath('//*[@id="content_inner"]/form/nav[2]/div/a[7]').to_s
	begin
		numpages = numpages.split(",")[1].split(":")[1] # Get the element associated with the "≫" button
	rescue
	#	puts "No results, or only one page"
	end

	xpath = '//*[@id="content_inner"]/form/ul/li' # Snag each "product_whole" class

	# Scrap the first result page
	scrape(page,xpath)

	# Scrape the rest of the result pages
	shufflepoints = (2..numpages.to_i).to_a.shuffle
	shufflepoints.each { |num|
		target = endpoint + "?translationType=2&page=#{num}&vic=search_other"
		puts "Hitting: #{target}<br>"

		body = HTTP.get(target).to_s
		page = Nokogiri::HTML(body, nil, 'utf-8');
		xpath = '//*[@id="content_inner"]/form/ul/li' # Snag each "product_whole" class
		scrape(page,xpath)

	}
end

# Check ARGV for terms, if not, just use "セガ", which is Sega in Japanese
if ARGV.empty?
	terms = "セガ"
 	puts "Using #{terms} as default search, since no arguments provided"
else	
 	terms = ARGV[0]
end

# Arcade Games Category - "https://buyee.jp/item/search/category/2084047781"
# Box & Control Panel - "https://buyee.jp/item/search/category/2084047783"
# Base - https://buyee.jp/item/search/category/2084047782
#search =  [2084047781,2084047783,2084047782].shuffle # Feel free to search more than one category! 
search = [2084047781]
search.each{|cat|
	hunt(cat,terms)
}
