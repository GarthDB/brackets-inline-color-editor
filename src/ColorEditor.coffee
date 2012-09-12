define ['helper/tinycolor-min'], (tinycolorMin) ->
	'use strict'

	class ColorEditor

		defaultColor: 'rgba(0,0,0,1)'
		hsv: tinycolor('rgba(0,0,0,1)').toHsv()

		constructor: (@element, color, @callback = null, @swatches = null) ->
			@color = tinycolor(color)
			@$element = $(@element)
			@$colorValue = @$element.find('.color_value')
			@$rgbaButton = @$element.find('.rgba')
			@$hexButton = @$element.find('.hex')
			@$hslButton = @$element.find('.hsla')
			@$currentColor = @$element.find('.current_color')
			@$lastColor = @$element.find('.last_color')
			@$selection = @$element.find('.color_selection_field')
			@$selectionBase = @$element.find('.color_selection_field .selector_base')
			@$hueBase = @$element.find('.hue_slider .selector_base')
			@$opacityGradient = @$element.find('.opacity_gradient')
			@$hueSlider = @$element.find('.hue_slider')
			@$opacitySlider = @$element.find('.opacity_slider')
			@$hueSelector = @$element.find('.hue_slider .selector_base')
			@$opacitySlider = @$element.find('.opacity_slider')
			@$opacitySelector = @$element.find('.opacity_slider .selector_base')

			@addFieldListeners()
			@synchronize()


		addFieldListeners: () ->
			@bindColorFormatToRadioButton('rgba')
			@bindColorFormatToRadioButton('hex')
			@bindColorFormatToRadioButton('hsl')
			@$colorValue.change(@colorSetter)
			@bindOriginalColorButton()
			@bindColorSwatches()
			@registerDragHandler('.color_selection_field', @handleSelectionFieldDrag)
			@registerDragHandler('.hue_slider', @handleHueDrag)
			@registerDragHandler('.opacity_slider', @handleOpacityDrag)

		synchronize: ->
			colorValue = @getColor()
			colorObject = tinycolor(colorValue)
			hueColor = 'hsl(' + this.hsv.h + ', 100%, 50%)'

			@updateColorTypeRadioButtons(colorObject.format)

			# Synchronize our color value input field.
			@$colorValue.attr('value', colorValue)

			# Control and gradient color updates
			@$currentColor.css('background-color', colorValue)
			@$selection.css('background-color', hueColor)
			@$hueBase.css('background-color', hueColor)
			@$selectionBase.css('background-color', colorObject.toHexString())
			@$opacityGradient.css('background-image', '-webkit-gradient(linear, 0% 0%, 0% 100%, from(' + hueColor + '), to(transparent))')

			# Slider positions
			@$hueSelector.css('bottom', (this.hsv.h / 360 * 100) + "%")
			@$opacitySelector.css('bottom', (this.hsv.a * 100) + "%")
			@$selectionBase.css({left: (this.hsv.s * 100) + '%', bottom: (this.hsv.v * 100) + '%'})

		colorSetter: ->
			newValue = $.trim(this.$colorValue.val())
			newColor = tinycolor(newValue)
			if (!newColor.ok)
				newValue = this.getColor()
				newColor = tinycolor(newValue)
			@commitColor(newValue, true)
			@hsv = newColor.toHsv()
			@synchronize() #todo - see if this is needed

		getColor: ->
			return (@color || this.defaultColor)

		updateColorTypeRadioButtons: (format) ->
			switch (format)
				when 'rgb'
					this.$rgbaButton.attr('checked', true)
				when 'hex', 'name'
					this.$hexButton.attr('checked', true)
				when 'hsl'
					this.$hslButton.attr('checked', true)
				# when 'hsv'
				# // hsv found, currently unsupported.

		bindColorFormatToRadioButton: (buttonClass, propertyName, value) ->
			handler = (event) ->
				newFormat = event.currentTarget.value;
				newColor = @getColor();
				colorObject = tinycolor(newColor);
				switch newFormat
					when 'hsla'
						newColor = colorObject.toHslString()
					when 'rgba'
						newColor = colorObject.toRgbString()
					when 'hex'
						newColor = colorObject.toHexString()
						@hsv.a = 1
						@synchronize()
				@commitColor(newColor, false)

			@$element.find('.' + buttonClass).click(handler)
			
		bindOriginalColorButton: ->
			@$lastColor.click (event) ->
				@commitColor(@.lastColor, true)

		bindColorSwatches: ->
			handler = (event) ->
				$swatch = $(event.currentTarget)
				#  We set the inline style on the swatch when we add colors to the well but the class
				# has a gray background so we don't want to allow the user to pick one of the 'empty'
				# items so check for a style attribute which should only have a background-color property
				# and use that to determine if it's an empty well or not.
				# Todo - this is a bit of an unintuitive way to check if empty.  Element should have a class set for empty.
				if ($swatch.attr('style').length > 0)
					color = $swatch.css('background-color')
				if (color.length > 0)
					hsvColor = tinycolor(color).toHsv()
					@setColorAsHsv(hsvColor, true)
			@$element.find('.color_swatch').click handler

		addSwatches: () ->
			for value, index in @swatches
				self.$el.find('#swatch_' + index).children('.color_swatch').css('background-color', value)

		setColorAsHsv: (hsv, commitHsv) ->
			hsv.h = @hsv.h
			hsv.a = @hsv.a
			newColor = tinycolor(hsv)
			oldColor = tinycolor(this.getColor())
			oldFormat = oldColor.format
			colorVal
			switch oldFormat
				when 'hsl'
					colorVal = newColor.toHslString()
				when 'rgb'
					colorVal = newColor.toRgbString()
				when 'hex', 'name' # Handle case of alpha < 1 for hex format, we need to fall back to RGB
					colorVal = if @hsv.a < 1 then newColor.toRgbString() else newColor.toHexString()

			@commitColor(colorVal, commitHsv)

		commitColor: (colorVal, resetHsv) ->
			@$colorValue.val(colorVal)
			if resetHsv
				colorObj = tinycolor(colorVal)
				@hsv = colorObj.toHsv()
			@synchronize()


		handleSelectionFieldDrag: (event) ->
			yOffset = event.clientY - @$selection.offset().top
			xOffset = event.clientX - @$selection.offset().left
			height = @$selection.height()
			width = @$selection.width()
			xOffset = Math.min(width, Math.max(0, xOffset));
			yOffset = Math.min(height, Math.max(0, yOffset))
			hsv = {}
			hsv.s = xOffset / width
			hsv.v = 1 - yOffset / height
			@setColorAsHsv(hsv)

		handleHueDrag: (event) =>
			offset = event.clientY - @$hueSlider.offset().top;
			height = @$hueSlider.height();
			offset = Math.min(height, Math.max(0, offset));
			@hsv.h = (1 - offset / height) * 360;
			@setColorAsHsv(@hsv)

		handleOpacityDrag: (event) =>
			offset = event.clientY - @$opacitySlider.offset().top
			height = @$opacitySlider.height()
			offset = Math.min(height, Math.max(0, offset))
			@hsv.a = (1 - offset / height)
			@setColorAsHsv(@hsv)
        
		registerDragHandler: (selector, handler) =>
			@$element.find(selector).on "mousedown.colorpopoverview", (event) =>
				handler.call @, event
				$(window).on("mousemove.colorpopoverview", (event) =>
					handler.call @, event
				).on "mouseup.colorpopoverview", ->
					$(window).off "mouseup.colorpopoverview"
					$(window).off "mousemove.colorpopoverview"























