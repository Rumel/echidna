# frozen_string_literal: true

class Channel
  attr_accessor :id, :filter, :max_results, :name, :playlist_id

  def initialize(h = {})
    h.each { |k, v| public_send("#{k}=", v) }
  end

  def max_results
    @max_results || 25
  end
end
