require 'validate_params'

Sinatra::Application.reset!

class Main < Sinatra::Base
  set :show_exceptions => false

  helpers ValidateParams

  register Sinatra::Reloader
  also_reload './validate_params.rb'

  error ParameterValidationError do
    validator = env['sinatra.error'].validator

    [validator.http_response_code, {:errors => validator.errors}.to_json]
  end

  get '/user' do
    validate_params :response_code => 400 do
      param :login_id, :type => :string, :required => true, :minlength => 3, :maxlength => 5

      param :time_npw, :type => :date, :required => true

      param :count, :type => :integer, :required => { :if => Proc.new { |attr, value| params[:login_id].to_s.length > 3 } }
    end

    'hello world2'
  end

  def custom_validator
    false
  end

end
