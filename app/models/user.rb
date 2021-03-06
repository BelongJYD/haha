class User
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include ActiveModel::SecurePassword
  field :name
  #field :email
  field :password_digest
  field :access_token
  field :locale, :default => I18n.locale.to_s
 
  has_secure_password

  validates :name, :presence => true, :uniqueness => {:case_sensitive => false}
  validates :name, :format => {:with => /\A\w+\z/, :message => 'only A-Z, a-z, _ allowed'}, :length => {:in => 3..20}
  #validates :email, :format => {:with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/}
  validates :password, :password_confirmation, :presence => true, :on => :create
  validates :password, :length => {:minimum => 6, :allow_nil => true}
  validates :current_password, :current_password => {:fields => [:name, :password_digest]}, :on => :update
  

  attr_accessor :current_password
  #attr_accessible :name, :email, :password, :password_confirmation, :current_password


  has_many :board, :dependent => :destroy
  has_many :chart, :dependent => :destroy
  #embeds_one :profile

  #before_create :build_profile, :set_access_token
  before_create :set_access_token
  #after_create :create_first_board
  def to_param
    name
  end


  def remember_token
    [id, Digest::SHA512.hexdigest(password_digest)].join('$')
  end

  def self.find_by_remember_token(token)
    user = first :conditions => {:_id => token.split('$').first}
    (user && user.remember_token == token) ? user : nil
  end

  def screen_name
    (profile.name.blank? || profile.name == name) ? name : "#{name}(#{profile.name})"
  end

  def set_access_token
    self.access_token ||= generate_token
  end

  def generate_token
    SecureRandom.hex(32)
  end

  def reset_access_token
    update_attribute :access_token, generate_token
  end

  def self.find_by_access_token(token)
    first :conditions => {:access_token => token} if token.present?
  end

  def admin?
    APP_CONFIG['admin_emails'].include?(self.email)
  end

end
