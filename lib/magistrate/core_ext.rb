class Hash
  def symbolize_keys!
      keys.each do |key|
      self[(key.to_sym rescue key) || key] = delete(key)
    end
    self
  end
  
  def recursive_symbolize_keys!
    symbolize_keys!
    values.select { |v| v.is_a?(Hash) }.each { |h| h.recursive_symbolize_keys! }
  end
end