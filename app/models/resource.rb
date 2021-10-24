class Resource

	# Adds a warning message to the specified resource

	def warning(message)
		@warnings = Array.new unless @warnings.present?
		@warnings.append(message)
	end

	#-----------------------------------------------------------------------------

	# Adds an error message to the specified resource

	def error(message)
		@errors = Array.new unless @errors.present?
		@errors.append(message)
	end

	#-----------------------------------------------------------------------------

  # Helper method: converting coding to string
  def coding_to_string(coding = [])
    begin
      string_array = coding.map do |e|
        e.display.present? ? text = e.display : text = e.code
        text
      end
      string = string_array.join(',')
    rescue => exception
      string = '&lt;missing&gt;'
    end
    string
  end

	#-----------------------------------------------------------------------------
end