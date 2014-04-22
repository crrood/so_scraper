require "selenium-webdriver"

driver = Selenium::WebDriver.for :firefox

(1..3).each do |i|
	
	# load the next user profile
	driver.navigate.to "http://stackoverflow.com/users/" + i.to_s

	# wait for connectifier to load
	# check for email / phone and linkedin (skip if both not present)
	# download contact info

	# navigate to linkedin profile
	# load recruiter version
	# download linkedin profile

end