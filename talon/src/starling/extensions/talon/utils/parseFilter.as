package starling.extensions.talon.utils
{
	import starling.filters.ColorMatrixFilter;
	import starling.filters.FragmentFilter;

	/** Maps css filters to starling fragment filter. */
	public function parseFilter(string:String):FragmentFilter
	{
		var pattern:RegExp = /(\w+)\(([\d.]+\))/;
		var split:Array = pattern.exec(string);

		if (split)
		{
			var type:String = split[1];
			var value:Number = parseFloat(split[2]);
			if (value != value) throw new ArgumentError("Bad filter value: " + value);

			if (type == "brightness")
			{
				var filter:ColorMatrixFilter = new ColorMatrixFilter();
				filter.adjustBrightness(value);
				return filter;
			}

		}

		return null;
	}
}
