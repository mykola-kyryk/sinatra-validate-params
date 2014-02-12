module ValidateParams

  class ParameterValidationError < StandardError
    attr_reader :code, :body

    def initialize(options={})
      @code = options[:code]
      @body = options[:body]
    end
  end

  class BaseParameterValidator

    attr_reader :attr, :value, :options, :error_code, :error_message, :error_params

    def initialize(attr, value, options={})
      @attr           = attr
      @value          = value
      @options        = options
      @error_code     = ''
      @error_message  = ''
      @error_params   = {}

      setup(attr, value, options)
    end

    def valid?
      false
    end

    def setup(attr, value, options)
    end
  end

  class RequiredParameterValidator < BaseParameterValidator
    def setup(attr, value, options)
      @error_code     = "#{attr}_is_required"
      @error_message  = "#{attr} is required."
    end

    def valid?
      !(value.nil? || value.to_s == '')
    end
  end

  class MaxlengthParameterValidator < BaseParameterValidator
    def setup(attr, value, options)
      @error_code     = "#{attr}_is_too_long"
      @error_message  = "#{attr} can not be longer than #{options} characters."
      @error_params   = {:max_length => options}
    end

    def valid?
      value.to_s.length <= options
    end
  end

  class MinlengthParameterValidator < BaseParameterValidator
    def setup(attr, value, options)
      @error_code     = "#{attr}_is_too_short"
      @error_message  = "#{attr} can not be shorter than #{options} characters."
      @error_params   = {:min_length => options}
    end

    def valid?
      value.to_s.length >= options
    end
  end

  def validate_params(options={}, &block)
    @validate_params_errors = {}

    yield if block_given?

    code = options[:response_code] || 400

    unless params_valid?
      raise ParameterValidationError.new(:code => code, :body => @validate_params_errors)
    end
  end

  def params_valid?
    @validate_params_errors.empty?
  end

  def param(attr, options={})
    options.each do |validator_name, validation_param|
      validator = find_validator(validator_name).new(attr, params[attr], validation_param)
      unless validator.valid?
        add_error(attr, validator.error_code, validator.error_message, validator.error_params)
      end
    end
  end

  def find_validator(validator_name)
    ValidateParams.const_get "#{validator_name.to_s.capitalize}ParameterValidator"
  end

  def add_error(attr, error_code, error_message, error_params)
    @validate_params_errors ||= {}
    @validate_params_errors[attr] ||= []
    @validate_params_errors[attr] << {
        :error_code     => error_code,
        :error_message  => error_message,
        :error_params   => error_params,
    }
  end

end