
/*
	CanvasDrawing.coffee
	Joshua Marshall Moore
	12/18/2011
*/

var CanvasDrawing, MarkMaker;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

MarkMaker = (function() {

  function MarkMaker(range, nowX, nowT, minX, maxX) {
    this.range = range;
    this.nowX = nowX;
    this.nowT = nowT;
    this.minX = minX;
    this.maxX = maxX;
    this.timePerPixel = this.scale(this.prescale(this.range.value));
    this.minT = -1 * ((this.timePerPixel * (this.nowX - this.minX)) - this.nowT);
    this.maxT = -1 * ((this.timePerPixel * (this.nowX - this.maxX)) - this.nowT);
  }

  MarkMaker.prototype.prescale = function(val) {
    var retval;
    if (val > 69) {
      retval = 69;
    } else {
      retval = val;
    }
    return retval;
  };

  MarkMaker.prototype.scale = function(rangeValue) {
    var maxIn, maxOut, minIn, minOut, msPerSecond, msPerYear, scale;
    minIn = this.range.min;
    maxIn = this.range.max;
    msPerSecond = 1000;
    msPerYear = 1000 * 60 * 60 * 24 * 365;
    minOut = Math.log(msPerSecond);
    maxOut = Math.log(msPerYear);
    scale = (maxOut - minOut) / (maxIn - minIn);
    return Math.exp(minOut + scale * (rangeValue - minIn));
  };

  /*
  		converts a given time t into a position x, as long as @minT <= t <= @maxT
  */

  MarkMaker.prototype.tToX = function(t) {
    return Math.floor(-1 * (((this.nowT - t) / this.timePerPixel) - this.nowX));
  };

  /*
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
  */

  MarkMaker.prototype.makeMarks = function(first, nextIncrement, classifier) {
    var mark, results, t;
    results = new Array();
    t = first(this.minT);
    while (t <= this.maxT) {
      mark = {
        t: t,
        x: this.tToX(t),
        "class": classifier(t)
      };
      results.push(mark);
      t = nextIncrement(t);
    }
    return results;
  };

  MarkMaker.prototype.rangeTtoRangeX = function(dt) {
    return dt / this.timePerPixel;
  };

  /*
  		Given the first and nextIncrement function used in the makeMarkers function, 
  		as well as a minimum value for the distance between two marks, this fucntion
  		returns true if two markers distance is more or equal to the minimum distance,
  		and false otherwise.
  */

  MarkMaker.prototype.testSettings = function(first, nextIncrement, minDistance) {
    var x, x2;
    x = this.tToX(first(this.minT));
    x2 = this.tToX(nextIncrement(this.minT));
    return (x2 - x) >= minDistance;
  };

  return MarkMaker;

})();

CanvasDrawing = (function() {

  function CanvasDrawing(canvasID, rangeID) {
    this.draw = __bind(this.draw, this);    this.canvas = document.getElementById(canvasID);
    this.range = document.getElementById(rangeID);
    this.context = this.canvas.getContext("2d");
    this.lineY = 5 / 8 * this.canvas.height;
    this.nowX = 100;
    this.firstMinute = function(t) {
      var msPerMinute;
      msPerMinute = 1000 * 60;
      return Math.floor(t / msPerMinute) * msPerMinute;
    };
    this.nextMinute = function(currentMinute) {
      var msPerMinute;
      msPerMinute = 1000 * 60;
      return currentMinute + msPerMinute;
    };
    this.firstHour = function(t) {
      var msPerHour;
      msPerHour = 1000 * 60 * 60;
      return Math.floor(t / msPerHour) * msPerHour;
    };
    this.nextHour = function(currentHour) {
      var msPerHour;
      msPerHour = 1000 * 60 * 60;
      return currentHour + msPerHour;
    };
    this.firstDay = function(minT) {
      var d, msPerHour, t;
      msPerHour = 1000 * 60 * 60;
      t = Math.floor(minT / msPerHour) * msPerHour;
      d = new Date(t);
      while (d.getHours() !== 0) {
        t += msPerHour;
        d.setTime(t);
      }
      return t;
    };
    this.nextDay = function(currentDay) {
      var msPerDay, t;
      msPerDay = 1000 * 60 * 60 * 24;
      return t = currentDay + msPerDay;
    };
    this.firstMonth = function(minT) {
      var d, msPerDay, t;
      msPerDay = 1000 * 60 * 60 * 24;
      t = Math.floor(minT / msPerDay) * msPerDay;
      d = new Date(t);
      while (d.getDate() !== 1) {
        t += msPerDay;
        d.setTime(t);
      }
      return t;
    };
    this.nextMonth = function(currentMonth) {
      var d, msPerDay, t;
      msPerDay = 1000 * 60 * 60 * 24;
      t = currentMonth + msPerDay * 27;
      d = new Date(t);
      while (d.getDate() !== 1) {
        t += msPerDay;
        d.setTime(t);
      }
      return t;
    };
    this.classifier = function(t) {
      var c, d, msPerDay, msPerHour, msPerMinute;
      msPerMinute = 1000 * 60;
      msPerHour = 1000 * 60 * 60;
      msPerDay = 1000 * 60 * 60 * 24;
      d = new Date(t);
      if (t % msPerMinute === 0) c = "minute";
      if (t % msPerHour === 0) c = "hour";
      if (d.getHours() === 0 && t % msPerHour === 0) c = "day";
      if (d.getDay() === 0 && d.getHours() === 0) c = "week";
      if (d.getDate() === 1) c = "month";
      if (d.getMonth() === 0 && d.getDate() === 1 && d.getHours() === 0) {
        c = "year";
      }
      return c;
    };
    this.fitToWindow();
    $(window).resize(this.fitToWindow);
  }

  CanvasDrawing.prototype.getNowX = function() {
    return this.nowX;
  };

  CanvasDrawing.prototype.setNowX = function(val) {
    return this.nowX = val;
  };

  CanvasDrawing.prototype.getCanvas = function() {
    return this.canvas;
  };

  CanvasDrawing.prototype.drawLine = function() {
    this.context.moveTo(0, this.lineY);
    this.context.lineTo(this.canvas.width, this.lineY);
    this.context.closePath();
    this.context.stroke();
    return true;
  };

  CanvasDrawing.prototype.drawTick = function(x, length) {
    this.context.beginPath();
    this.context.moveTo(x, this.lineY - length / 2);
    this.context.lineTo(x, this.lineY + length / 2);
    this.context.closePath();
    this.context.stroke();
    return true;
  };

  CanvasDrawing.prototype.classToTickmarkLength = function(c) {
    var len;
    if (c === "minute") len = 10;
    if (c === "hour") len = 15;
    if (c === "day") len = 20;
    if (c === "week") len = 25;
    if (c === "month") len = 30;
    if (c === "year") len = 35;
    if (c === "now") len = 50;
    return len;
  };

  CanvasDrawing.prototype.monthNtoString = function(n) {
    var str;
    if (n === 0) str = "January";
    if (n === 1) str = "February";
    if (n === 2) str = "March";
    if (n === 3) str = "April";
    if (n === 4) str = "May";
    if (n === 5) str = "June";
    if (n === 6) str = "July ";
    if (n === 7) str = "August";
    if (n === 8) str = "September";
    if (n === 9) str = "October";
    if (n === 10) str = "November";
    if (n === 11) str = "December";
    return str;
  };

  CanvasDrawing.prototype.labelTickmark = function(mark) {
    var d, hour, minute, text;
    this.context.font = "10px sans-serif";
    d = new Date(mark.t);
    if (mark["class"] === "minute") {
      minute = d.getMinutes();
      text = minute.toString();
    }
    if (mark["class"] === "hour") {
      hour = d.getHours();
      text = hour.toString();
    }
    if (mark["class"] === "day" || mark["class"] === "week") {
      text = (d.getMonth() + 1).toString() + "/" + d.getDate().toString();
    }
    if (mark["class"] === "month") text = this.monthNtoString(d.getMonth());
    if (mark["class"] === "year") {
      text = d.getFullYear().toString() + "\n" + this.monthNtoString(d.getMonth());
    }
    if (mark["class"] === "now") {
      text = d.getHours().toString() + ":";
      if (d.getMinutes() < 10) {
        text += "0" + d.getMinutes();
      } else {
        text += d.getMinutes();
      }
    }
    return this.context.fillText(text, mark.x, this.lineY + this.classToTickmarkLength(mark["class"]));
  };

  CanvasDrawing.prototype.draw = function() {
    var border, i, markMaker, marks, minTickmarkDistance, now, nowMark;
    this.context.clearRect(0, 0, this.canvas.width, this.canvas.height);
    this.drawLine();
    now = new Date();
    border = 50;
    markMaker = new MarkMaker(this.range, this.nowX, now.getTime(), border, this.canvas.width - border);
    minTickmarkDistance = 10;
    if (markMaker.testSettings(this.firstMinute, this.nextMinute, minTickmarkDistance)) {
      marks = markMaker.makeMarks(this.firstMinute, this.nextMinute, this.classifier);
    } else if (markMaker.testSettings(this.firstHour, this.nextHour, minTickmarkDistance)) {
      marks = markMaker.makeMarks(this.firstHour, this.nextHour, this.classifier);
    } else if (markMaker.testSettings(this.firstDay, this.nextDay, minTickmarkDistance)) {
      marks = markMaker.makeMarks(this.firstDay, this.nextDay, this.classifier);
    } else if (markMaker.testSettings(this.firstMonth, this.nextMonth, minTickmarkDistance)) {
      marks = markMaker.makeMarks(this.firstMonth, this.nextMonth, this.classifier);
    } else {
      marks = [];
    }
    nowMark = {
      x: this.nowX,
      t: now.getTime(),
      "class": "now"
    };
    this.drawTick(nowMark.x, this.classToTickmarkLength(nowMark["class"]));
    this.labelTickmark(nowMark);
    i = 0;
    while (i < marks.length) {
      this.drawTick(marks[i].x, this.classToTickmarkLength(marks[i]["class"]));
      this.labelTickmark(marks[i]);
      i++;
    }
    return true;
  };

  CanvasDrawing.prototype.fitToWindow = function() {
    this.canvas.height = $(window).height();
    this.canvas.width = $(window).width();
    this.lineY = 5 / 8 * this.canvas.height;
    return true;
  };

  CanvasDrawing.prototype.test = function() {
    var i, markMaker, marks;
    this.context.clearRect(0, 0, this.canvas.width, this.canvas.height);
    markMaker = new MarkMaker(this.range, 100, (new Date()).getTime(), 50, this.canvas.width - 50);
    marks = markMaker.makeMarks(this.firstMonth, this.nextMonth, this.classifier);
    $("#output").text(marks.length);
    i = 0;
    while (i < marks.length) {
      this.drawTick(marks[i].x, this.classToTickmarkLength(marks[i]["class"]));
      this.labelTickmark(marks[i]);
      i++;
    }
    return true;
  };

  return CanvasDrawing;

})();

window.Timeline = (function() {

  function Timeline(canvasID, sliderID) {
    this.start = __bind(this.start, this);    this.canvasDrawing = new CanvasDrawing(canvasID, sliderID);
  }

  Timeline.prototype.start = function() {
    var interval;
    return interval = setInterval(this.canvasDrawing.draw, 60);
  };

  return Timeline;

})();
