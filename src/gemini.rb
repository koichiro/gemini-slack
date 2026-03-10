require 'dotenv'
Dotenv.load

module Gemini
  VERSION = "0.1.0"
end

require_relative 'gemini/cli'
