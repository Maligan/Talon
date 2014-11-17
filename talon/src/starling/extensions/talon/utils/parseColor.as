package starling.extensions.talon.utils
{
	import starling.utils.Color;

	public function parseColor(str:String):Number
	{
		if (str == null) return NaN;
		if (str.indexOf("#") == 0) return parseInt(str.substr(1), 16);
		if (Color[str.toUpperCase()] is uint) return Color[str.toUpperCase()];
		return NaN;
	}
}