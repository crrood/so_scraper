require "selenium-webdriver"

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

BEGIN_INDEX = 89484
END_INDEX = 89493

# get connectifier password at program call
if ARGV.length != 2
	puts "please enter connectifier and linkedin passwords as argument"
	exit
else
	cf_password = ARGV[0]
	li_password = ARGV[1]
end

# load connectifier extension
caps = Selenium::WebDriver::Remote::Capabilities.chrome("chromeOptions" => 
	{ "args" => [ "load-extension=C:/Users/RockIT/AppData/Local/Google/Chrome/User Data/Default/Extensions/mbbpjgnlpelaafnnigciegfpelchjldl/0.6.5_0"]})
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

# wait to let the login info sink in
sleep(3)

# ...and we're in!

(BEGIN_INDEX..END_INDEX).each do |i|

	candidate_info = {}
	
	# conditions:
	# 1. must be in San Francisco or CA
	# 2. must have linkedin
	# 3. must have email or phone number
	begin
		# load the next user profile
		$driver.navigate.to "http://stackoverflow.com/users/" + i.to_s
		
		# make sure they exist
		if find_element_by_css "img[alt='page not found']"
			raise "no user present"
		end
		
		# 1. must be in San Francisco or CA
		location_element = find_element_by_css "td.adr"
		if location_element.text.match(/San Francisco/i) || location_element.text.match(/CA/) || location_element.text.match(/California/i)
			candidate_info["location"] = location_element.text
		else
			raise "out of area"
		end

		# wait for connectifier to load and switch to its frame
		wait_for_element_by_css "div#c-side-close-div"
		$driver.switch_to.frame(find_element_by_css("iframe"))
		
		# wait for connectifier content to load
		wait_for_element_by_css "a#add-note"
		
		# 2. must have linkedin
		if linkedin_link = find_element_by_css("a[title='LinkedIn profile']")
			candidate_info["linkedin_url"] = linkedin_link.attribute("href")
		else
			raise "no linkedin"
		end
		
		# 3. must have email or phone number
		contact_info_present = false
		if email_link = find_element_by_css("a.email")
			candidate_info["email"] = email_link.text
			contact_info_present = true
		end
		
		if phone_show_btn = find_element_by_css("img.show-button")
			phone_show_btn.click
			candidate_info["phone"] = find_element_by_css("a.phone").text
			contact_info_present = true
		end
		
		if !contact_info_present
			raise "no contact info"
		end
		
		# get first and last name
		name_array = find_element_by_css("span.personName").text.split
		candidate_info["first_name"] = name_array[0]
		if name_array.length > 1
			candidate_info["last_name"] = name_array[1]
		end

		# load linkedin profile
		$driver.navigate.to candidate_info["linkedin_url"]
		wait_for_element_by_css "a.button-secondary"

		# load in recruiter
		find_element_by_css("a.button-secondary").click

		# wait for the body to load and pull it
		wait_for_element_by_css "div.content"
		candidate_info["resume_text"] = find_element_by_css("div.content").text

		# NEXT STEP
		# put into Compas-recognized .csv format

	rescue Exception => e
		puts $driver.current_url.match(/[^\/]*$/)[0] + ": " + e.to_s
	end

end