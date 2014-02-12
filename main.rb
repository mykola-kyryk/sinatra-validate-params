require 'validate_params'

Sinatra::Application.reset!

class Main < Sinatra::Base
  set :show_exceptions => false

  helpers ValidateParams

  register Sinatra::Reloader
  also_reload './validate_params.rb'

  error ParameterValidationError do
    code = env['sinatra.error'].code
    body = env['sinatra.error'].body

    [code, {:errors => body}.to_json]
  end

  get '/user' do
    validate_params do
      param :login_id, :required => true, :minlength => 3, :maxlength => 5
    end

    'hello world2'
  end

end
