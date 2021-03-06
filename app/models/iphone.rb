# == Schema Information
# Schema version: 20090624184104
#
# Table name: devices
#
#  id           :integer(4)    not null, primary key
#  created_at   :datetime      
#  updated_at   :datetime      
#  device_type  :string(255)   
#  carrier      :string(255)   
#  manufacturer :string(255)   
#  model        :string(255)   
#  user_id      :integer(4)    
#  pin          :string(255)   
#  host         :string(255)   
#  serverport   :string(255)   
#  deviceport   :string(255)   
#

require 'socket'
require 'openssl'

class Iphone < Client
  
  def ping(callback_url,message=nil,vibrate=nil,badge=nil,sound=nil)  # do an iPhone-based push to the specified 
    @cert = File.read("config/apple_push_cert.pem") if File.exists?("config/apple_push_cert.pem")
  	@passphrase = APP_CONFIG[:iphonepassphrase]
  	@host = APP_CONFIG[:iphoneserver]
  	@port = APP_CONFIG[:iphoneport] 
    @message = message if message
    @payload = {"do_sync" => callback_url.split(',')} if callback_url
    @vibrate = vibrate if vibrate
    @badge = badge if badge
    @sound = sound if sound and not sound.blank?
    begin
      ssl_ctx = OpenSSL::SSL::SSLContext.new
  		ssl_ctx.key = OpenSSL::PKey::RSA.new(@cert, @passphrase)
  		ssl_ctx.cert = OpenSSL::X509::Certificate.new(@cert)

  		socket = TCPSocket.new(@host, @port)
  		ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_ctx)
  		ssl_socket.sync = true
  		ssl_socket.connect

  		ssl_socket.write(self.apn_message)
  		ssl_socket.close
  		socket.close
		rescue SocketError => error
  		raise "Error while sending ping: #{error}"
		end
  end
	
	protected

	def apn_message
		data = {}
		data['aps'] = {}
		data['aps']['alert'] = @message if @message 
		data['aps']['badge'] = @badge if @badge
		data['aps']['sound'] = @sound if @sound and @sound.is_a? String
		data['aps']['vibrate'] = @vibrate if @vibrate
		data['do_sync'] = @payload['do_sync'] if @payload
		json = data.to_json
		logger.debug "Ping message to iPhone: #{json}"
		"\0\0 #{[self.pin.delete(' ')].pack('H*')}\0#{json.length.chr}#{json}"
	end
end
