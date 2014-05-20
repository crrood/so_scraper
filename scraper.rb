require "selenium-webdriver"

# INTERNAL METHODS
def wait_for_element_by_css(target_css)
	wait = Selenium::WebDriver::Wait.new(:timeout => 2) # seconds
	wait.until { find_element_by_css(target_css) }
end

def find_element_by_css(target_css)
	begin
		$driver.find_element(:css => target_css)
	rescue
		false
	end
end

def find_elements_by_css(target_css)
	begin
		$driver.find_elements(:css => target_css)
	rescue
		false
	end
end

# CONSTANTS
START_INDEX = 1
ITERATIONS = 1

# MAIN PROGRAM
# get connectifier password at program call
if ARGV.length != 2
	puts "please enter connectifier and linkedin passwords as argument"
	exit
else
	cf_password = ARGV[0]
	li_password = ARGV[1]
end

# load connectifier extension
# path needs to be modified to current user
USER_NAME = "Colin Rood"
caps = Selenium::WebDriver::Remote::Capabilities.chrome("chromeOptions" => 
	{ "args" => [ "load-extension=C:/Users/" + USER_NAME + "/AppData/Local/Google/Chrome/User Data/Default/Extensions/mbbpjgnlpelaafnnigciegfpelchjldl/0.6.5_0"]})
$driver = Selenium::WebDriver.for :chrome, desired_capabilities: caps

# first things first, sign into linkedin
$driver.navigate.to "http://www.linkedin.com"
wait_for_element_by_css "input[name='session_key']"
find_element_by_css("input#session_key-login").send_keys("colin@rockitrecruiting.com")
find_element_by_css("input#session_password-login").send_keys(li_password)
find_element_by_css("input#signin").click
sleep(2)

# for some reason, must reload page to sign in to CF
$driver.navigate.to "http://stackoverflow.com/users/1"
$driver.navigate.refresh

# wait for panel to load and switch focus
wait_for_element_by_css "#c-side-close-div"
$driver.switch_to.frame(find_element_by_css("iframe"))

# enter email
find_element_by_css("#email").send_keys("colin@rockitrecruiting.com")
find_element_by_css(".fa-sign-in").click
wait_for_element_by_css "#password"

# submit password
find_element_by_css("#password").send_keys(cf_password)
find_element_by_css(".fa-sign-in").click
sleep(3)

# ...and we're in!

# open and prep a File for output
output_csv = File.new("output.csv", "w+")
output_csv.write("FirstName,LastName,Email,Email2,WorkPhone,HomePhone,MobilePhone,OtherPhone,Fax,Country,Address1,Address2,City,State,Zip,LinkedInUrl,ResumeText\n")

# open the list of qualified Id's
input_csv = File.new("qualified_ids.csv", "r")

# skip to starting id
# to allow data to be taken in multiple runs
START_INDEX.times do
	input_csv.gets
end

ITERATIONS.times do

	candidate_info = {}
	
	# conditions:
	# 1. must be in San Francisco or CA
	# 2. must have linkedin
	# 3. must have email or phone number
	begin
		# load the next user profile
		so_id = input_csv.gets
		$driver.navigate.to "http://stackoverflow.com/users/" + so_id
		
		# make sure they exist
		if find_element_by_css "img[alt='page not found']"
			raise "no user present"
		end
		
		# 1. must be in CA
		location_element = find_element_by_css "td.adr"
		if location_element.text.match(/San Francisco/i) || location_element.text.match(/CA/) || location_element.text.match(/California/i)
			candidate_info["location"] = location_element.text.gsub(",", "")
		else
			raise "out of area"
		end

		# wait for connectifier to load and switch to its frame
		wait_for_element_by_css "div#c-side-close-div"
		$driver.switch_to.frame(find_element_by_css("iframe"))
		
		# wait for connectifier content to load
		wait_for_element_by_css "a#add-note"

		# get first and last name
		name_array = find_element_by_css("span.personName").text.split
		candidate_info["first_name"] = name_array[0]
		if name_array.length > 1
			candidate_info["last_name"] = name_array[1]
		end
		
		# 2. must have linkedin
		if linkedin_link = find_element_by_css("a[title='LinkedIn profile']")
			candidate_info["linkedin_url"] = linkedin_link.attribute("href")
		else
			raise "no linkedin"
		end

		# reveal their contact info
		if show_btns = find_elements_by_css("img.show-button")
			show_btns.map { |btn| btn.click }
		else
			raise "no contact info"
		end
		
		# 3. must have email (phone number optional)
		if email_list = find_elements_by_css("a.email")
			
			# check for personal (not company) address
			personal_addresses = email_list.select {|e| e.text =~ /gmail|yahoo|hotmail/}
			candidate_info["email2"] = ""

			if (personal_addresses.length == 0)

				# company address is better than nothing
				candidate_info["email"] = email_list[0].text
				
				# ...and two company addresses are better than one!
				if (email_list.length > 1)
					candidate_info["email2"] = email_list[1].text
				end

			elsif (personal_addresses.length == 1)
				# just one personal address
				candidate_info["email"] = personal_addresses[0].text
			else
				# two personal adresses
				candidate_info["email"] = personal_addresses[0].text
				candidate_info["email2"] = personal_addresses[1].text
			end

		else
			raise "no email address"
		end
		
		# check for phone number
		if phone_show_btn = find_element_by_css("img.show-button")
			phone_show_btn.click
			sleep(1)
			candidate_info["phone"] = find_element_by_css("a.phone").text
		else
			# for easier serialization on output to .csv format
			candidate_info["phone"] = ""
		end

		# load linkedin profile
		$driver.navigate.to candidate_info["linkedin_url"]
		wait_for_element_by_css "a.button-secondary"

		# load in recruiter
		find_element_by_css("a.button-secondary").click

		# wait for the body to load and pull it
		wait_for_element_by_css "div.content"
		candidate_info["resume_text"] = '"' + find_element_by_css("div.content").text + '"'

		# output in Compas-recognized .csv format
		output_csv.write(candidate_info["first_name"] + "," +
			candidate_info["last_name"] + "," +
			candidate_info["email"] + "," +
			candidate_info["email2"] + ",,," +
			candidate_info["phone"] + ",,,,,," +
			candidate_info["location"] + ",,," +
			candidate_info["linkedin_url"] + "," +
			candidate_info["resume_text"] + "\n")

	rescue Exception => e
		if(candidate_info["first_name"] != nil)
			# output name and error
			puts candidate_info["first_name"] + ": " + e.to_s
		else
			# lift name from URL and output with error
			puts $driver.current_url.match(/[^\/]*$/)[0] + ": " + e.to_s
		end
	end

	puts "final index: " + (START_INDEX + ITERATIONS).to_s
	puts "final id: " + so_id.to_s

end