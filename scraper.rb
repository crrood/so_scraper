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
if ARGV.length != 1
	puts "please enter connectifier password as argument"
	exit
else
	password = ARGV[0]
end

# load connectifier extension
caps = Selenium::WebDriver::Remote::Capabilities.chrome("chromeOptions" => 
	{ "args" => [ "load-extension=C:/Users/RockIT/AppData/Local/Google/Chrome/User Data/Default/Extensions/mbbpjgnlpelaafnnigciegfpelchjldl/0.6.5_0"]})
$driver = Selenium::WebDriver.for :chrome, desired_capabilities: caps

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
find_element_by_css("#password").send_keys(password)
find_element_by_css(".fa-sign-in").click

# wait to let the login info sink in
sleep(3)

# ...and we're in!

(BEGIN_INDEX..END_INDEX).each do |i|
	
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
			puts "valid location"
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
			linkedin_url = linkedin_link.attribute("href")
			puts "linkedin_url: " + linkedin_url
		else
			raise "no linkedin"
		end
		
		# 3. must have email or phone number
		contact_info_present = false
		if email_link = find_element_by_css("a.email")
			email_address = email_link.text
			puts "email: " + email_address
			contact_info_present = true
		end
		
		if phone_show_btn = find_element_by_css("img.show-button")
			phone_show_btn.click
			phone_number = find_element_by_css("a.phone").text
			puts phone_number
			contact_info_present = true
		end
		
		if !contact_info_present
			raise "no contact info"
		end
		
	rescue Exception => e
		puts $driver.current_url.match(/[^\/]*$/)[0] + ": " + e.to_s
	end
	
	# download contact info

	# navigate to linkedin profile
	# load recruiter version
	# download linkedin profile

end