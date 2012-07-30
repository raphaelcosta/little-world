class Friend
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :location, type: Array

  index({ location: "2d" })
  attr_writer :latitude,:longitude

  validates :name ,:presence => true, :uniqueness => true

  validate :check_presence_of_locations
  validate :check_uniqueness_of_location

  before_save :save_location

  def latitude
    @latitude || (self.location[0] if self.location.present?)
  end

  def longitude
    @longitude || (self.location[1]  if self.location.present?)
  end

  def near_friends(options = {})
    options[:limit] = 3
    friends = Friend.near(location: self.location).where(:_id.nin => [self.id])
    friends = friends.max_distance(location: (options[:kms] / 111.12)) if options[:kms]
    friends.limit(options[:limit])
  end

  private

  def initialize_array
    self.location = Array.new if self.location.nil?
  end

  def save_location
    initialize_array
    self.location[0] = @latitude.to_f if @latitude.present?
    self.location[1] = @longitude.to_f if @longitude.present?
  end

  def check_presence_of_locations
    errors.add :latitude , "can't be blank" if !@latitude.present?  || (@latitude.present? && @latitude.to_f == 0)
    errors.add :longitude , "can't be blank" if !@longitude.present? || (@longitude.present? && @longitude.to_f == 0)
  end

  def check_uniqueness_of_location
    if Friend.where(:location => [@latitude.to_f, @longitude.to_f]).ne(:_id => self._id).exists?
      errors.add :latitude , "is already taken"
      errors.add :longitude , "is already taken" 
    end
  end

end
