# frozen_string_literal: true

require "intesis_box/client"
require "intesis_box/discovery"

module IntesisBox
  class << self
    attr_accessor :logger
  end
end
