# frozen_string_literal: true

module Api
  module V1
    module Admin
      class BaseController < ApplicationController
        include Includable
      end
    end
  end
end
