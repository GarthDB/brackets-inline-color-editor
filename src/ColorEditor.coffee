define ['helper/tinycolor-min'], (tinycolorMin) ->
	'use strict'

	class ColorEditor

		defaultColor: 'rgba(0,0,0,1)'
		hsv: tinycolor('rgba(0,0,0,1)').toHsv()

		constructor: (@element, color, @callback = null, @swatches = null) ->
			@color = tinycolor(color)
			@lastColor = color
			@$element = $(@element)
			@$colorValue = @$element.find('.color_value')
			@$buttonList = @$element.find('ul.button-bar')
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
			@$swatches = @$element.find('.swatches')

			@addFieldListeners()
			@addSwatches()

			@$lastColor.css('background-color', @lastColor)
			@commitColor color

		addFieldListeners: () ->
			@bindColorFormatToRadioButton('rgba')
			@bindColorFormatToRadioButton('hex')
			@bindColorFormatToRadioButton('hsla')
			@$colorValue.change(@colorSetter)
			@bindOriginalColorButton()
			@bindColorSwatches()
			@registerDragHandler('.color_selection_field', @handleSelectionFieldDrag)
			@registerDragHandler('.hue_slider', @handleHueDrag)
			@registerDragHandler('.opacity_slider', @handleOpacityDrag)
			@registerFocusHandler(@$selection.find('.selector_base'), @handleSelectionFocus)
			@registerFocusHandler(@$hueSlider.find('.selector_base'), @handleHueFocus)
			@registerFocusHandler(@$opacitySlider.find('.selector_base'), @handleOpacityFocus)

		synchronize: ->
			colorValue = @getColor().toString()
			colorObject = tinycolor(colorValue)
			hueColor = 'hsl(' + @hsv.h + ', 100%, 50%)'

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
			@$hueSelector.css('bottom', (@hsv.h / 360 * 100) + "%")
			@$opacitySelector.css('bottom', (@hsv.a * 100) + "%")
			if !isNaN(@hsv.s)
				@hsv.s = (@hsv.s*100) + '%'
			if !isNaN(@hsv.v)
				@hsv.v = (@hsv.v*100) + '%'
			@$selectionBase.css({left: @hsv.s, bottom: @hsv.v})

		colorSetter: ->
			newValue = $.trim(@$colorValue.val())
			newColor = tinycolor(newValue)
			if (!newColor.ok)
				newValue = @getColor()
				newColor = tinycolor(newValue)
			@commitColor(newValue, true)
			@hsv = newColor.toHsv()
			@synchronize() #todo - see if this is needed

		getColor: ->
			return (@color || @defaultColor)

		updateColorTypeRadioButtons: (format) ->
			@$buttonList.find('li').removeClass('selected')
			@$buttonList.find('.'+format).parent().addClass('selected')
			switch (format)
				when 'rgb'
					@$buttonList.find('.rgba').parent().addClass('selected')
				when 'hex', 'name'
					@$buttonList.find('.hex').parent().addClass('selected')
				when 'hsl'
					@$buttonList.find('.hsla').parent().addClass('selected')
				# when 'hsv'
				# // hsv found, currently unsupported.

		bindColorFormatToRadioButton: (buttonClass, propertyName, value) ->
			handler = (event) =>
				newFormat = $(event.currentTarget).html().toLowerCase()
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
			@$lastColor.click (event) =>
				@commitColor(@lastColor, true)

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
			for swatch, index in @swatches
				@$swatches.append("<li><div class=\"swatch\" style=\"background-color: #{swatch.value};\"></div> <span class=\"value\">#{swatch.value}</span></li>")
			@$swatches.find('li').click (event) =>
				@commitColor $(event.currentTarget).find('.value').html()


		setColorAsHsv: (hsv, commitHsv) ->
			newHsv = @hsv
			for k, v of hsv
				newHsv[k] = v
			newColor = tinycolor(newHsv)
			oldColor = tinycolor(@getColor())
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

		commitColor: (colorVal, resetHsv = true) ->
			@callback colorVal
			@color = colorVal
			@$colorValue.val(colorVal)
			if resetHsv
				colorObj = tinycolor(colorVal)
				@hsv = colorObj.toHsv()
				@color = colorObj
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
			@setColorAsHsv(hsv, false)
			if !@$selection.find('.selector_base').is(":focus")
				@$selection.find('.selector_base').focus()


		handleHueDrag: (event) =>
			offset = event.clientY - @$hueSlider.offset().top;
			height = @$hueSlider.height();
			offset = Math.min(height, Math.max(0, offset));
			hsv = {}
			hsv.h = (1 - offset / height) * 360;
			@setColorAsHsv(hsv, false)
			if !@$hueSlider.find('.selector_base').is(":focus")
				@$hueSlider.find('.selector_base').focus()

		handleOpacityDrag: (event) =>
			offset = event.clientY - @$opacitySlider.offset().top
			height = @$opacitySlider.height()
			offset = Math.min(height, Math.max(0, offset))
			hsv = {}
			hsv.a = (1 - offset / height)
			@setColorAsHsv(hsv, false)
			if !@$opacitySlider.find('.selector_base').is(":focus")
				@$opacitySlider.find('.selector_base').focus()

		registerDragHandler: (selector, handler) =>
			@$element.find(selector).on "mousedown.coloreditorview", (event) =>
				handler.call @, event
				$(window).on("mousemove.coloreditorview", (event) =>
					handler.call @, event
				).on "mouseup.coloreditorview", ->
					$(window).off "mouseup.coloreditorview"
					$(window).off "mousemove.coloreditorview"


		handleSelectionFocus: (event) =>
			switch event.keyCode
				when 37 #left
					hsv = {}
					sat = $.trim(@hsv.s.replace('%', ''))
					if sat > 0
						hsv.s = if (sat - 1) <= 0 then 0 else (sat - 1)
						@setColorAsHsv(hsv)
					return false
				when 39 #right
					hsv = {}
					sat = $.trim(@hsv.s.replace('%', ''))
					if sat < 100
						hsv.s = if (Number(sat) + 1) >= 100 then 100 else (Number(sat) + 1)
						@setColorAsHsv(hsv)
					return false
				when 40 #down
					hsv = {}
					value = $.trim(@hsv.v.replace('%', ''))
					if value > 0
						hsv.v = if (value - 1) <= 0 then 0 else (value - 1)
						@setColorAsHsv(hsv)
					return false
				when 38 #up
					hsv = {}
					value = $.trim(@hsv.v.replace('%', ''))
					if value < 100
						hsv.v = if (Number(value) + 1) >= 100 then 100 else (Number(value) + 1)
						@setColorAsHsv(hsv)
					return false

		handleHueFocus: (event) =>
			step = 3.6
			switch event.keyCode
				when 40 #down
					hsv = {}
					hue = Number(@hsv.h)
					if hue > 0
						hsv.h = if (hue - step) <= 0 then 360 - step else (hue - step)
						@setColorAsHsv(hsv)
					return false
				when 38 #up
					hsv = {}
					hue = Number(@hsv.h)
					if hue < 360
						hsv.h = if (hue + step) >= 360 then step else (hue + step)
						@setColorAsHsv(hsv)
					return false

		handleOpacityFocus: (event) =>
			step = 0.01
			switch event.keyCode
				when 40 #down
					hsv = {}
					alpha = @hsv.a
					if alpha > 0
						hsv.a = if (alpha - step) <= 0 then 0 else (alpha - step)
						@setColorAsHsv(hsv)
					return false
				when 38 #up
					hsv = {}
					alpha = @hsv.a
					if alpha < 100
						hsv.v = if (alpha + step) >= 1 then 1 else (alpha + step)
						@setColorAsHsv(hsv)

		registerFocusHandler: (element, handler) =>
			element.focus (event) ->
				element.bind 'keydown', handler
			element.blur (event) ->
				element.unbind 'keydown', handler


















