define (require, exports, module) ->
	'use strict';
	
	# Load Brackets modules
	InlineWidget = brackets.getModule("editor/InlineWidget").InlineWidget

	ColorEditor = require('ColorEditor')

	# Load tempalte
	InlineEditorTemplate = require("text!InlineColorEditorTemplate.html")

	class InlineColorEditor extends InlineWidget

		parentClass: InlineWidget::
		$wrapperDiv: null

		constructor: (@color, @pos) ->
			@initialColorString = @color
			InlineWidget.call(@)

		setColor: (colorLabel) =>
			if(colorLabel != @initialColorString)
				end = { line: @pos.line, ch: @pos.ch + @color.length }
				@editor.document.replaceRange(colorLabel, @pos, end)
				@editor._codeMirror.setSelection(@pos, { line: @pos.line, ch: @pos.ch + colorLabel.length })
				@color = colorLabel

		load: (hostEditor) ->
			self = @
			@editor = hostEditor
			@parentClass.load.call(@, hostEditor)

			selectedColors = @editor._codeMirror.getValue().match(/#[a-f0-9]{6}|#[a-f0-9]{3}|rgb\( ?\b([0-9]{1,2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])\b ?, ?\b([0-9]{1,2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])\b ?, ?\b([0-9]{1,2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])\b ?\)|rgba\( ?\b([0-9]{1,2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])\b ?, ?\b([0-9]{1,2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])\b ?, ?\b([0-9]{1,2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])\b ?, ?\b(1|0|0\.[0-9]{1,3}) ?\)|hsl\( ?\b([0-9]{1,2}|[12][0-9]{2}|3[0-5][0-9]|360)\b ?, ?\b([0-9]{1,2}|100)\b% ?, ?\b([0-9]{1,2}|100)\b% ?\)|hsla\( ?\b([0-9]{1,2}|[12][0-9]{2}|3[0-5][0-9]|360)\b ?, ?\b([0-9]{1,2}|100)\b% ?, ?\b([0-9]{1,2}|100)\b% ?, ?\b(1|0|0\.[0-9]{1,3}) ?\)/gi)
			selectedColors = @usedColors(selectedColors, 12)


			@$wrapperDiv = $(InlineEditorTemplate)
			@colorEditor = new ColorEditor(@$wrapperDiv, @color, @setColor, selectedColors)

			@$htmlContent.append(@$wrapperDiv)
			
			# @$wrapperDiv.on("mousedown", @onWrapperClick.bind(@));


	 	# Close the color picker when clicking on the wrapper outside the picker
		# onWrapperClick: (event) ->
		# 	if (event.target == @$wrapperDiv[0])
		# 		@close()
		# 	else
		# 		event.preventDefault()

		close: () ->
			if (@closed)
				return
			@closed = true
			@hostEditor.removeInlineWidget(@)
			if (@onClose)
				@onClose(@)
		
		onAdded: () ->
			window.setTimeout(@._sizeEditorToContent.bind(@));
			console.log @colorEditor.focus()
		
		_sizeEditorToContent: () ->
			@hostEditor.setInlineWidgetHeight(@, @$wrapperDiv.outerHeight(), true)


		usedColors: (originalArray, length = 10) ->
			compressed = []
			copyArray = originalArray.slice(0)
			for originalColor in originalArray
				colorCount = 0
				for copyColor, i in copyArray
					if originalColor and copyColor and originalColor.toLowerCase() is copyColor.toLowerCase()
						colorCount++
						delete copyArray[i]
				if colorCount > 0
					a = {}
					a.value = originalColor
					a.count = colorCount;
					compressed.push(a)

			compressed.sort (a,b) ->
				if a.count is b.count then return 0
				if a.count > b.count then return -1
				if a.count < b.count then return 1

			return compressed.slice(0, length)

	module.exports = InlineColorEditor
