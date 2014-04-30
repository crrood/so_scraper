require "selenium-webdriver"

def wait_for_element_by_css(target_css)
	wait = Selenium::WebDriver::Wait.new(:timeout => 3) # seconds
	wait.until { $driver.find_element(:css => target_css) }
end

# load connectifier extension
caps = Selenium::WebDriver::Remote::Capabilities.chrome("chromeOptions" => 
	{ "args" => [ "load-extension=C:/Users/RockIT/AppData/Local/Google/Chrome/User Data/Default/Extensions/mbbpjgnlpelaafnnigciegfpelchjldl/0.6.5_0"]})
$driver = Selenium::WebDriver.for :chrome, desired_capabilities: caps

# for some reason, must reload page to sign in to CF
$driver.navigate.to "http://stackoverflow.com/users/1"
$driver.navigate.refresh

# wait for panel to load and switch focus
wait_for_element_by_css "#c-side"
$driver.switch_to.frame($driver.find_element(:css => "iframe"))

# enter email
$driver.find_element(:id => "email").send_keys("colin@rockitrecruiting.com")
$driver.find_element(:class => "fa-sign-in").click
wait_for_element_by_css "#password"

# get password from console
print "Connectifier password: "
password = gets

# submit password
$driver.find_element(:id => "password").send_keys(password)
$driver.find_element(:class => "fa-sign-in").click

# wait to let the login info sink in
sleep(3)

# ...and we're in!

(1..3).each do |i|
	
	# load the next user profile
	$driver.navigate.to "http://stackoverflow.com/users/" + i.to_s

	# wait for connectifier to load
	wait_for_element_by_css "div#c-side"
	$driver.switch_to.frame($driver.find_element(:css => "iframe"))

	# need to find a better element to wait for..
	wait_for_element_by_css "span.personName"

	# check for email / phone and linkedin (skip if both not present)
	# download contact info

	# navigate to linkedin profile
	# load recruiter version
	# download linkedin profile

end