###
	CanvasDrawing.coffee
	Joshua Marshall Moore
	12/18/2011
###

# MarkMaker is responsible for producing x positions for markers
class MarkMaker
	constructor: (@range, @nowX, @nowT, @minX, @maxX) ->
		# range # The input type=range element
		# nowX # The x-position of the now-marker
		# nowT # The current time, designated by the now-marker
		
		# minX # The first drawable x-position
		# maxX # The last drawable x-position
		
		@timePerPixel = this.scale(this.prescale(@range.value)) # c is the time per pixel
		
		@minT = -1 * ((@timePerPixel*(@nowX - @minX)) - @nowT)
		@maxT = -1 * ((@timePerPixel*(@nowX - @maxX)) - @nowT)
	
	prescale: (val) ->
		if val > 69
			retval = 69
		else
			retval = val
		retval
	
	scale: (rangeValue) ->
		minIn = @range.min
		maxIn = @range.max
		
		msPerSecond = 1000
		msPerYear = 1000*60*60*24*365
		minOut = Math.log( msPerSecond )
		maxOut = Math.log( msPerYear )
		
		scale = (maxOut - minOut) / (maxIn - minIn)
		Math.exp( minOut + scale * (rangeValue - minIn ))
	
		
	###
		converts a given time t into a position x, as long as @minT <= t <= @maxT
	###
	tToX: (t) -> 
		Math.floor(-1 * (((@nowT - t)/@timePerPixel) - @nowX))
		
		
	###
		makeMarks iterates over the range [first(minT), maxT], using the 
		t+=nextIncrement(t) function to create values for which the predicate(t) 
		function decides whether to create a mark or not. 
		
		first(t):
			calculates the first time step from the previously calculated @minT.
		
		nextIncrement(t): 
			give t calculates the next iteration of t.
		
		classifier(t):
			returns a string indicating whether the supplied time is a full hour,
			day, week, or month
		
		The output is an array of {t, x} objects.
	###
	makeMarks: (first, nextIncrement, classifier) ->
		results = new Array()
		
		t = first(@minT)
		while t<=@maxT
			mark = 
				t: t
				x: this.tToX(t)
				class: classifier(t)
			
			results.push(mark)
			
			t = nextIncrement(t)
		
		results
		
		
	rangeTtoRangeX: (dt) ->
		dt / @timePerPixel
		
		
	###
		Given the first and nextIncrement function used in the makeMarkers function, 
		as well as a minimum value for the distance between two marks, this fucntion
		returns true if two markers distance is more or equal to the minimum distance,
		and false otherwise.
	###
	testSettings: (first, nextIncrement, minDistance) ->
		x = this.tToX(first(@minT))
		x2 = this.tToX(nextIncrement(@minT))
		(x2-x) >= minDistance
		
		
class CanvasDrawing
	constructor: (canvasID, rangeID) ->
		@canvas = document.getElementById( canvasID )
		@range = document.getElementById( rangeID );
		
		@context = @canvas.getContext( "2d" )
		@lineY = 5/8 * @canvas.height
		@nowX = 100
		
		# parameters for minute tickmarks
		@firstMinute = (t) ->
			msPerMinute = 1000 * 60
			Math.floor(t / msPerMinute) * msPerMinute
			
		@nextMinute = (currentMinute) ->
			msPerMinute = 1000 * 60
			currentMinute + msPerMinute
		
		# parameters for hour tickmarks
		@firstHour = (t) ->
			msPerHour = 1000*60*60
			Math.floor(t / msPerHour) * msPerHour
			
		@nextHour = (currentHour) ->
			msPerHour = 1000*60*60
			currentHour + msPerHour
			
		# parameters for day tickmarks
		@firstDay = (minT) ->
			msPerHour = 1000*60*60
			
			t = Math.floor(minT/msPerHour) * msPerHour
			d = new Date(t)
			while(d.getHours() isnt 0)
				t += msPerHour
				d.setTime(t)
			t

		@nextDay = (currentDay) ->
			msPerDay = 1000*60*60 * 24
			t = currentDay + msPerDay
	
		# parameters for month tickmarks
		@firstMonth = (minT) ->
			msPerDay = 1000*60*60*24
			t = Math.floor(minT/msPerDay) * msPerDay
			d = new Date(t)
			while d.getDate() isnt 1
				t += msPerDay
				d.setTime(t)
			t
		
		@nextMonth = (currentMonth) ->
			msPerDay = 1000*60*60*24
			t = currentMonth + msPerDay * 27
			d = new Date(t)
			while d.getDate() isnt 1
				t += msPerDay
				d.setTime(t)
			t
	
		@classifier = (t) ->
			msPerMinute = 1000*60
			msPerHour = 1000*60*60
			msPerDay = 1000*60*60 * 24
			
			d = new Date(t)
			c = "minute" 	if t % msPerMinute is 0
			c = "hour" 		if t % msPerHour is 0
			c = "day"		if d.getHours() is 0 and t % msPerHour is 0
			c = "week"		if d.getDay() is 0 and d.getHours() is 0
			c = "month"		if d.getDate() is 1
			c = "year"		if d.getMonth() is 0 and d.getDate() is 1 and d.getHours() is 0 	
			c
			
		this.fitToWindow()
		$(window).resize(this.fitToWindow)
		
	
	getNowX: ->
		@nowX
		
	setNowX: (val) ->
		@nowX = val
		
	getCanvas: ->
		@canvas
		
	drawLine: ->
		@context.moveTo( 0, @lineY )
		@context.lineTo( @canvas.width, @lineY )
		@context.closePath()
		@context.stroke()
		true
		
				
	drawTick: (x, length) ->
		@context.beginPath()
		@context.moveTo( x, @lineY - length/2 )
		@context.lineTo( x, @lineY + length/2 )
		@context.closePath()
		@context.stroke()
		true
	
	
	classToTickmarkLength: (c) ->
		len = 10 if c is "minute"
		len = 15 if c is "hour" 
		len = 20 if c is "day"
		len = 25 if c is "week"
		len = 30 if c is "month"
		len = 35 if c is "year"
		len = 50 if c is "now"
		len
		
	
	monthNtoString: (n) ->
		str = "January" 	if n is 0
		str = "February" 	if n is 1
		str = "March" 		if n is 2
		str = "April" 		if n is 3
		str = "May" 		if n is 4
		str = "June" 		if n is 5
		str = "July " 		if n is 6
		str = "August" 		if n is 7
		str = "September" 	if n is 8
		str = "October" 	if n is 9
		str = "November" 	if n is 10
		str = "December" 	if n is 11
		str
	
	
	labelTickmark: (mark) ->
		@context.font = "10px sans-serif"
		d = new Date(mark.t)
	
		if mark.class is "minute"
			minute = d.getMinutes()
			text = minute.toString()
	
		if mark.class is "hour"
			hour = d.getHours()
			text = hour.toString()
		
		if mark.class is "day" or mark.class is "week"
			text = (d.getMonth() + 1).toString() + "/" + d.getDate().toString()
		
		if mark.class is "month"
			text = this.monthNtoString(d.getMonth())
			
		if mark.class is "year"
			text = d.getFullYear().toString() + "\n" + this.monthNtoString(d.getMonth())
	
		if mark.class is "now"
			text = d.getHours().toString() + ":"
			if d.getMinutes() < 10
				text += "0" + d.getMinutes()
			else text += d.getMinutes()
	
		@context.fillText(text, mark.x, @lineY + this.classToTickmarkLength(mark.class))
	
	draw: =>
		@context.clearRect(0, 0, @canvas.width, @canvas.height)
		this.drawLine()

		now = new Date()
		border = 50
		markMaker = new MarkMaker(@range, @nowX, now.getTime(), border, @canvas.width-border)
		
		minTickmarkDistance = 10
		
		# check whether minute settings yield tickmarks further than 10 pixels apart
		# if so, generate minute tickmarks
		# ditto for other increment tickmarks
		if markMaker.testSettings( @firstMinute, @nextMinute, minTickmarkDistance )
			marks = markMaker.makeMarks( @firstMinute, @nextMinute, @classifier )
			
		else if markMaker.testSettings( @firstHour, @nextHour, minTickmarkDistance )
			marks = markMaker.makeMarks( @firstHour, @nextHour, @classifier )
			
		else if markMaker.testSettings( @firstDay, @nextDay, minTickmarkDistance )
			marks = markMaker.makeMarks( @firstDay, @nextDay, @classifier ) 
		
		else if markMaker.testSettings( @firstMonth, @nextMonth, minTickmarkDistance )
			marks = markMaker.makeMarks( @firstMonth, @nextMonth, @classifier )
		
		else
			marks = []
			
		# draw now mark
		nowMark =
			x: @nowX
			t: now.getTime()
			class: "now"
		
		this.drawTick( nowMark.x, this.classToTickmarkLength(nowMark.class) )
		this.labelTickmark( nowMark )
		
		i = 0
		while i < marks.length
			this.drawTick( marks[i].x, this.classToTickmarkLength(marks[i].class) )
			this.labelTickmark( marks[i] )
			i++
		true
	
		
	fitToWindow: ->
		@canvas.height = $(window).height()
		@canvas.width = $(window).width()
		@lineY = 5/8 * @canvas.height
		true
		
		
	test: ->
		@context.clearRect(0, 0, @canvas.width, @canvas.height)
		markMaker = new MarkMaker(@range, 100, (new Date()).getTime(), 50, @canvas.width - 50)
		marks = markMaker.makeMarks( @firstMonth, @nextMonth, @classifier )
		
		$("#output").text(marks.length)
		
		i = 0
		while i < marks.length
			this.drawTick( marks[i].x, this.classToTickmarkLength(marks[i].class) )
			this.labelTickmark( marks[i] )
			i++
		# alert(markMaker.tToX(markMaker.getMinT()))
		true

class window.Timeline
	constructor: ( canvasID, sliderID ) ->
		@canvasDrawing = new CanvasDrawing( canvasID, sliderID )
	
	start: =>
		interval = setInterval( @canvasDrawing.draw, 60 )