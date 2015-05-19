package talon.utils
{
	import starling.filters.BlurFilter;
	import starling.filters.ColorMatrixFilter;
	import starling.filters.FragmentFilter;

	import talon.Attribute;

	[ExcludeClass]
	public class QueryUtil
	{
		public static function queryResource(attribute:Attribute, key:String):*
		{
			return attribute.node.getResource(key);
		}

		public static function queryBrightnessFilter(attribute:Attribute, brightness:String):FragmentFilter
		{
			var value:Number = parseFloat(brightness);
			if (value != value) throw new ArgumentError("Bad filter value: " + value);

			var filter:ColorMatrixFilter = new ColorMatrixFilter();
			filter.adjustBrightness(value);
			return filter;
		}

		public static function queryBlurFilter(attribute:Attribute, blurX:String, blurY:String):FragmentFilter
		{
			return new BlurFilter(parseFloat(blurX), parseFloat(blurY), 1);
		}

		public static function queryGlowFilter(attribute:Attribute, color:String, blur:String):FragmentFilter
		{
			return BlurFilter.createGlow(StringUtil.parseColor(color), 1, parseFloat(blur), 1)
		}

		public static function queryDropShadow(attribute:Attribute, distance:String, angle:String, color:String, alpha:String, blur:String):FragmentFilter
		{
			return BlurFilter.createDropShadow(parseFloat(distance), parseFloat(angle), StringUtil.parseColor(color), parseFloat(alpha), parseFloat(blur));
		}
	}
}