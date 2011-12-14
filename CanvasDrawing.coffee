
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
		# alert("nowX: #{@nowX}\nminX: #{@minX}\nnowT: @{@nowT}")
		
		@minT = -1 * ((@timePerPixel*(@nowX - @minX)) - @nowT)
		@maxT = -1 * ((@timePerPixel*(@nowX - @maxX)) - @nowT)
	
		# alert("minT: #{@minT}\nnowT: #{@nowT}\nmaxT: #{@maxT}")
		
		
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
		loop
			# loop escape 
			if t > @maxT
				break
		
			# loop body
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
		(x-x2) >= minDistance
		
		
class window.CanvasDrawing
	constructor: (canvasID, rangeID) ->
		@canvas = document.getElementById( canvasID )
		@range = document.getElementById( rangeID );
		
		@context = @canvas.getContext( "2d" )
		@lineY = 5/8 * @canvas.height
		
		# parameters for hour tickmarks
		@firstHour = (minT) ->
			msPerHour = 1000*60*60
			Math.floor(minT / msPerHour) * msPerHour
			
		@nextHour = (currentHour) ->
			msPerHour = 1000*60*60
			currentHour + msPerHour
			
		# parameters for day tickmarks
		@firstDay = (minT) ->
			msPerDay = 1000*60*60 * 24
			Math.floor(minT / msPerDay) * msPerHour
			
		@nextDay = (currentDay) ->
			msPerDay = 1000*60*60 * 24
			currentDay + msPerDay
	
		@classifier = (t) ->
			msPerHour = 1000*60*60
			msPerDay = 1000*60*60 * 24
			if t % msPerHour is 0
				c = "hour"
			c = "day" if t % msPerDay is 0
			c = "week" if (new Date(t)).getDay() is 0 and t % msPerDay is 0
			c = "month" if (new Date(t)).getDate() is 0 and t % msPerDay is 0
			c
		
	drawLine: ->
		@context.moveTo( 0, @lineY )
		@context.lineTo( @canvas.width, @lineY )
		@context.closePath()
		@context.stroke()
		pos = 
			start: 
				x: 0
				y: @lineY
			end: 
				x: @canvas.width
				y: @lineY

				
	drawTick: (x, length) ->
		@context.beginPath()
		@context.moveTo( x, @lineY - length/2 )
		@context.lineTo( x, @lineY + length/2 )
		@context.closePath()
		@context.stroke()
		pos = 
			start:
				x: x
				y: @lineY - length/2
			end:
				x: x
				y: @lineY + length/2
	
	classToTickmarkLength: (c) ->
		len = 10 if c is "hour" 
		len = 15 if c is "day"
		len = 20 if c is "week"
		len = 25 if c is "month"
		len
	
	draw: ->
		@context.clearRect(0, 0, @canvas.width, @canvas.height)
		this.drawLine()

		now = new Date()
		border = 50
		markMaker = new MarkMaker(@range, 100, now.getTime(), border, @canvas.width-border)
		
		# Draw hour tickmarks
		marks = markMaker.makeMarks( @firstHour, @nextHour, @classifier )
		
		i = 0
		loop
			break if i>=marks.length
			this.drawTick(marks[i].x, this.classToTickmarkLength(marks[i].class))
			i++
		true

	test: ->
		now = new Date()
		border = 50
		markMaker = new MarkMaker(@range, 100, now.getTime(), border, @canvas.width-border)
		alert(markMaker.rangeTtoRangeX(1000*60*60))
