module ValidateParams

  class ParameterValidationError < StandardError
    attr_reader :validator

    def initialize(validator)
      @validator = validator
    end
  end

  class BaseParameterValidator

    attr_reader :attr, :value, :options, :scope
    attr_accessor :error_code, :error_message, :error_params

    def initialize(attr, value, options, scope)
      @attr           = attr
      @value          = value
      @options        = options
      @scope          = scope

      @error_code     = ''
      @error_message  = ''
      @error_params   = {}

      setup(attr, value, options)
    end

    def valid?
      if options.is_a?(Hash) && ( options[:if] || options[:unless] )
        condition = options[:if] || options[:unless]

        should_validate = if condition.is_a? Symbol
          scope.public_send condition
        else
          condition.call(attr, value)
        end

        should_validate = !should_validate if options[:unless]
      else
        should_validate = true
      end

      if should_validate
        validate
      else
        true
      end
    end

    def validate
      true
    end

    def setup(attr, value, options)
    end
  end

  class TypeParameterValidator < BaseParameterValidator
    def setup(attr, value, options)
      self.error_code     = "#{attr}_type_is_wrong"
      self.error_message  = "#{attr} type should be #{options}."
      self.error_params   = { :type => options }
    end

    def validate
      case options
      when :string
        is_string?
      when :integer
        is_integer?
      when :boolean
        is_boolean?
      when :date
        is_date?
      else
        true
      end
    end

    def is_date?
      value =~ /\A([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?\Z/
    end

    def is_string?
      true
    end

    def is_integer?
      value.to_i.to_s == value
    end

    def is_boolean?
      value =~ /\Atrue|false\Z/i
    end
  end

  class RequiredParameterValidator < BaseParameterValidator
    def setup(attr, value, options)
      self.error_code     = "#{attr}_is_required"
      self.error_message  = "#{attr} is required."
    end

    def validate
      !(value.nil? || value.to_s == '')
    end
  end

  class MaxlengthParameterValidator < BaseParameterValidator
    def setup(attr, value, options)
      self.error_code     = "#{attr}_is_too_long"
      self.error_message  = "#{attr} can not be longer than #{options} characters."
      self.error_params   = {:max_length => options}
    end

    def validate
      value.to_s.length <= options
    end
  end

  class MinlengthParameterValidator < BaseParameterValidator
    def setup(attr, value, options)
      self.error_code     = "#{attr}_is_too_short"
      self.error_message  = "#{attr} can not be shorter than #{options} characters."
      self.error_params   = {:min_length => options}
    end

    def validate
      value.to_s.length >= options
    end
  end

  class ParamsValidationService

    attr_accessor :errors, :http_response_code

    def initialize(options = {})
      @errors = {}
      @http_response_code = options.fetch(:http_response_code, 400)
    end

    def valid?
      self.errors.empty?
    end

    def add_error(attr, error_hash = {})
      self.errors ||= {}
      self.errors[attr] ||= []
      self.errors[attr] << {
          :error_code     => error_hash.fetch(:error_code, ''),
          :error_message  => error_hash.fetch(:error_message, ''),
          :error_params   => error_hash.fetch(:error_params, ''),
      }
    end
  end

  def validate_params(options={}, &block)
    @validation_service = options.fetch(:validation_service, ParamsValidationService).new(options)

    yield if block_given?

    unless @validation_service.valid?
      raise ParameterValidationError.new(@validation_service)
    end
  end

  def param(attr, options={})
    options.each do |validator_name, validation_param|
      validator = find_validator(validator_name).new(attr, params[attr], validation_param, self)
      unless validator.valid?
        @validation_service.add_error(attr, {
            :error_code     => validator.error_code,
            :error_message  => validator.error_message,
            :error_params   => validator.error_params,
        })
      end
    end
  end

  def find_validator(validator_name)
    ValidateParams.const_get "#{validator_name.to_s.capitalize}ParameterValidator"
  end

end
