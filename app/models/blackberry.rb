require 'net/http'
require 'uri'

# this class performs push to notify devices to retrieve data, all via BES server PAP push
# set APP_CONFIG['bbserver] in your settings.yml
class Blackberry < Device
  
  def set_ports    
    self.host=APP_CONFIG[:bbserver]  # make sure to set APP_CONFIG[:bbserver] in settings.yml
    self.host||="192.168.1.106"  # this is Lars' MDS server and shouldn't be hit. Change if you don't want to set APP_CONFIG[:bbserver]
    self.serverport="8080"
    self.deviceport||="100"
  end
  
  def push(callback_url,message=nil,vibrate=nil) # notify the BlackBerry device via PAP
    p "Pinging Blackberry device via BES push: " + pin 
    set_ports
    data=build_payload(callback_url,message,vibrate)
    pap_push(data)
  end
  
  def build_payload(callback_url,message,vibrate)
    data="do_sync="+callback_url
    popup||=message # supplied message
    popup||=APP_CONFIG[:sync_popup]
    popup||="You have new data"
    popup=URI.escape(popup)
    (data = data + "&popup="+ popup) if popup
    vibrate=APP_CONFIG[:sync_vibrate]
    (data = data + "&vibrate="+vibrate.to_s) if vibrate
  end
  
  def pap_push(data)
    boundary= "asdlfkjiurwghasf"
    headers={"Content-Type"=>"multipart/related; type=\"application/xml\"; boundary="+boundary,
      "X-Wap-Application-Id"=>"/",
      "X-Rim-Push-Dest-Port"=>self.deviceport}
    #template=loadfile("pap_push.txt")
    @template = "--asdlfkjiurwghasf\nContent-Type: application/xml; charset=UTF-8\n\n<?xml version=\"1.0\"?>\n<!DOCTYPE pap PUBLIC \"-//WAPFORUM//DTD PAP 2.0//EN\"\n\"http://www.wapforum.org/DTD/pap_2.0.dtd\"\n[<?wap-pap-ver supported-versions=\"2.0\"?>]>\n<pap>\n<push-message push-id=\"pushID:--RAND_ID--\" ppg-notify-requested-to=\"http://localhost:7778\">\n\n<address address-value=\"WAPPUSH=--DEVICE_PIN_HEX--%3A100/TYPE=USER@rim.net\"/>\n<quality-of-service delivery-method=\"confirmed\"/>\n</push-message>\n</pap>\n--asdlfkjiurwghasf\nContent-Type: text/plain\n\n--CONTENT----asdlfkjiurwghasf--\n"
    @template.gsub!(/\n/,"\r\n")
    @template.gsub("$(pushid)",push_id)
    @template.gsub("$(notifyURL)",notifyURL)
    @template.gsub("$(pin)",pin)
    @template.gsub("$(headers)","Content-Type: text/plain")
    @template.gsub("$(content)",data)
    http_post(url,template,headers)
  end
  
  def loadfile
    # TODO: write code that loads a file into a string buffer and return that buffer
  end
  
  def http_post(address,data,headers)
    uri=URI.parse(address)
    response=Net::HTTP.start(uri.host) do |http|
      request = Net::HTTP::Post.new(uri.path,headers)
      request.body = data
      response = http.request(request)
    end
  end
  
  def push_id
    rand.to_s
  end
  
  def url  # this is the logic for doing BES server PAP push.  Takes host, serverport, pin and deviceport
    if host and serverport and pin and deviceport
      @url="http://"+ host + "\:" + serverport + "/push?DESTINATION="+ pin + "&PORT=" + deviceport + "&REQUESTURI=" + host
    else
      p "Do not have all values for URL"
      @url=nil
    end
  end
  
  # this will not get called (unless you rename it to ping)
  # it does BlackBerry BES style push as opposed to PAP push (which is implemented above)
  def bes_style_ping(callback_url,message=nil,vibrate=nil) # notify the BlackBerry device via the BES server 
    p "Pinging Blackberry device via BES push: " + pin 
    set_ports
    begin
      data=build_payload(callback_url,message,vibrate)
      headers={"X-RIM-PUSH-ID"=>push_id,"X-RIM-Push-NotifyURL"=>callback_url,"X-RIM-Push-Reliability-Mode"=>"APPLICATION"}
      http_post(url,data,headers)
      p "Result of BlackBerry PAP Push" + response.body[0..255]   # log the results of the push
    rescue
      p "Failed to push to BlackBerry device: "+ url + "=>" + $!
    end
  end
    

end
