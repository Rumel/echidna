# frozen_string_literal: true

module Echidna
  class Playlist
    attr_accessor :id, :title, :order

    def initialize(h = {})
      h.each { |k, v| public_send("#{k}=", v) }
    end
  end
end
