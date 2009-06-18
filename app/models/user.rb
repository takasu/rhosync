require 'digest/sha1'
require 'rubygems'
require 'aasm'
class User < ActiveRecord::Base
  has_many :apps, :through=>:memberships
  has_many :memberships
  has_many :administrations
  has_many :clients
  has_many :synctasks
  has_many :users
  has_many :devices
  has_many :source_notifies
  has_many :sources, :through => :source_notifies
  
  include Authentication
  
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  validates_presence_of     :login
  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message

  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :name, :password, :password_confirmation

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_by_login(login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end
  
  def ping(callback_url,message=nil,vibrate=500)
    @result=""
    devices.each do |device|
      @result=device.ping(callback_url,message,vibrate)
      p "Result of device ping: #{@result}" if @result
    end
    @result
  end 

  # checks for changes from all of the user's devices
  def check_for_changes(source)
    clients.each do |client|
      source.check_for_changes_for_client(client)
    end
  end

  protected
    


end
