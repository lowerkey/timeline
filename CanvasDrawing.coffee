
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
		return null if t < @minT
		return null if t > @maxT
		
		-1 * (((@nowT - t)/@timePerPixel) - @nowX)
		
		
	###
		makeMarks iterates over the range [first(minT), maxT], using the 
		t+=nextIncrement(t) function to create values for which the predicate(t) 
		function decides whether to create a mark or not. 
		
		first(t):
			calculates the first time step from the previously calculated @minT.
		
		nextIncrement(t): 
			give t calculates the next iteration of t.
		
		predicate(t): 
			returns true if a marker should be created for this iteration of t, 
			otherwise it returns false.
		
		The output is an array of {t, x} objects.
	###
	makeMarks: (first, nextIncrement, predicate) ->
		results = new Array()
		
		
		###
		first = first(@minT)
		next = nextIncrement(first)
		isHour = predicate(next)
		alert("minT: #{@minT}\nfirst:#{first}\nnext: #{next}\nisHour(next): #{isHour}")
		###
		
		t = first(@minT)
		loop
			# loop escape 
			if t > @maxT
				break
		
			# loop body
			if predicate t
				mark = 
					t: t
					x: this.tToX(t)
				
				results.push(mark)
				
			t = nextIncrement(t)
		
		results
		
class window.CanvasDrawing
	constructor: (canvasID, rangeID) ->
		@canvas = document.getElementById( canvasID )
		@range = document.getElementById( rangeID );
		
		@context = @canvas.getContext( "2d" )
		@lineY = 5/8 * @canvas.height
	
	
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
	
	
	draw: ->
		@context.clearRect(0, 0, @canvas.width, @canvas.height)
		this.drawLine()

		now = new Date()
		border = 50
		markMaker = new MarkMaker(@range, 100, now.getTime(), border, @canvas.width-border)
		
		# Draw hour tickmarks
		firstHour = (minT) ->
			msPerHour = 1000*60*60
			Math.floor(minT / msPerHour) * msPerHour
			
		nextHour = (currentHour) ->
			msPerHour = 1000*60*60
			currentHour + msPerHour
			
		isHour = (supposedHour) ->
			msPerHour = 1000*60*60
			supposedHour % msPerHour is 0
			
		marks = markMaker.makeMarks( firstHour, nextHour, isHour )
		marks.shift() if marks[0].x is null
		
		i = 0
		loop
			break if i>=marks.length
			
			this.drawTick(marks[i].x, 10)
			i++
		true
		
	run: ->
		# This line is giving me trouble
		@interval = setInterval(this.draw, 30)
		
		### 
			solution found so far: 
			external js:
			var canvasDrawing = new CanvasDrawing();
			var interval = setInterval("canvasDrawing.draw()", 30);
			// because var interval = setInterval(canvasDrawing.draw, 30) wouldn't work
		###
