
# MarkMaker is responsible for producing x positions for markers
class MarkMaker
	constructor: (range, nowX, nowT, minX, maxX) ->
		# alert("nowX: #{nowX}\nnowT: #{nowT}\nminX: #{minX}\nmaxX: #{maxX}")
		@range = range # The input type=range element
		@nowX = nowX # The x-position of the now-marker
		@nowT = nowT # The current time, designated by the now-marker
		
		@minX = minX # The first drawable x-position
		@maxX = maxX # The last drawable x-position
		
		@timePerPixel = @range.value*30*1000 # c is the time per pixel
		
		@minT = -1 * ((@timePerPixel*(@nowX - @minX)) - @nowT)
		@maxT = -1 * ((@timePerPixel*(@nowX - @maxX)) - @nowT)
		
		
	###
		converts a given time t into a position x, as long as @minT <= t <= @maxT
	###
	tToX: (t) -> 
		-1 * (((@nowT - t)/@timePerPixel) - @nowX)
		
		
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
		
		
class window.CanvasDrawing
	constructor: (canvasID, rangeID) ->
		@canvas = document.getElementById( canvasID )
		@range = document.getElementById( rangeID );
		
		@context = @canvas.getContext( "2d" )
		@lineY = 5/8 * @canvas.height
		
		# parameters for hour tickmarks
		@firstHour = (r) ->
			msPerHour = 1000*60*60
			Math.floor(r / msPerHour) * msPerHour
			
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
	
	
		@classifier = (t) ->
			msPerMinute = 1000*60
			msPerHour = 1000*60*60
			msPerDay = 1000*60*60 * 24
			
			d = new Date(t)
			c = "hour" 	if t % msPerHour is 0
			c = "day"	if d.getHours() is 0
			c = "week"	if d.getDay() is 0 and d.getHours() is 0 	
			c = "month"	if d.getDate() is 0 and d.getHours() is 0
			c = "year"	if d.getMonth() is 0 and d.getDate() is 0 and d.getHours() is 0 	
			c
			
		this.fitToWindow()
		$(window).resize(this.fitToWindow)
		
		
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
		len = 10 if c is "hour" 
		len = 15 if c is "day"
		len = 20 if c is "week"
		len = 25 if c is "month"
		len
	
	
	labelTickmark: (mark) ->
		@context.font = "10px sans-serif"
		d = new Date(mark.t)
		if mark.class is "hour"
			hour = d.getHours()
			text = hour.toString()
		
		if mark.class is "day" or mark.class is "week"
			text = (d.getMonth() + 1).toString() + "/" + d.getDate().toString()
		
		@context.fillText(text, mark.x, @lineY + this.classToTickmarkLength(mark.class))

	
	draw: ->
		@context.clearRect(0, 0, @canvas.width, @canvas.height)
		this.drawLine()

		now = new Date()
		border = 50
		markMaker = new MarkMaker(@range, 100, now.getTime(), border, @canvas.width-border)
		
		# check whether to generate hour or day tickmarks
		if markMaker.testSettings( @firstHour, @nextHour, 10 )
			# then generate appropriate tickmarks
			marks = markMaker.makeMarks( @firstHour, @nextHour, @classifier )
		else
			marks = markMaker.makeMarks( @firstDay, @nextDay, @classifier ) 
		
		i = 0
		while i < marks.length
			this.drawTick(Math.floor(marks[i].x), this.classToTickmarkLength(marks[i].class))
			this.labelTickmark(marks[i])
			i++
		true
		
		
	fitToWindow: ->
		@canvas.height = $(window).height()
		@canvas.width = $(window).width()
		@lineY = 5/8 * @canvas.height
		true
