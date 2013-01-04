class TimeOfDayTools
{
	/** From a string "HH:MM:DD" (24hr time) to an Int, reflecting the number of seconds into the day */
	static public function stringToTime(str:String):TimeOfDay
	{
		var hour:Int = 0;
		var min:Int = 0;
		var sec:Int = 0;

		var re = ~/^([012]?[0-9]):([0-5]?[0-9]):([0-5]?[0-9])$/;
		if (re.match(str))
		{
			var hourStr = re.matched(1);
			var minStr = re.matched(2);
			var secStr = re.matched(3);

			hour = Std.parseInt(hourStr);
			min = Std.parseInt(minStr);
			sec = Std.parseInt(secStr);
		}

		return hour*3600 + min*60 + sec;
	}

	static inline public function getHours(t:TimeOfDay):Int
	{
		return Math.floor((t - (t % 3600)) / 3600);
	}

	static inline public function getMinutes(t:TimeOfDay):Int
	{
		// var secSinceHour = t % 3600;
		// var remainderSec = t % 60;
		// return (secSinceHour - remainderSec) / 60;
		return Math.floor(((t % 3600) - getSeconds(t)) / 60);
	}

	static inline public function getSeconds(t:TimeOfDay)
	{
		return t % 60;
	}


	static public function timeToDate(t:TimeOfDay, ?d:Date)
	{
		if (d == null) d = Date.now();

		var hour = getHours(t);
		var min = getMinutes(t);
		var sec = getSeconds(t);

		return new Date(d.getFullYear(), d.getMonth(), d.getDate(), hour, min, sec);
	}
}

typedef TimeOfDay = Int;

class TimeOfDayToolsTest 
{
	static function main()
	{
		trace(TimeOfDayTools.stringToTime("01:00:00"));		// 3600
		trace(TimeOfDayTools.stringToTime("23:59:59"));		// 86399
		trace(TimeOfDayTools.stringToTime("0:0:0")); 		// 0
		trace(TimeOfDayTools.stringToTime("12:034:30"));	// 0

		var t1 = 3675;

		trace (TimeOfDayTools.getHours(t1));				// 1
		trace (TimeOfDayTools.getMinutes(t1));				// 1
		trace (TimeOfDayTools.getSeconds(t1));				// 15

		var t2 = 3600;

		trace (TimeOfDayTools.timeToDate(t2));				// 2013-01-04 01:00:00
	}
}