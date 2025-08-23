class String
  def as_hash
    modified_string = self.gsub('=>', ':').gsub('nil', 'null')
    JSON.parse(modified_string)
  rescue
    {}
  end
end
