package starling.extensions.talon.utils
{
	import starling.extensions.talon.core.Attribute;
	import starling.filters.BlurFilter;
	import starling.filters.ColorMatrixFilter;
	import starling.filters.FragmentFilter;

	public class QueryUtil
	{
		public static function queryResource(attribute:Attribute, key:String):*
		{
			return attribute.node.getResource(key);
		}

		public static function queryBrightnessFilter(attribute:Attribute, brightness:String):FragmentFilter
		{
			var value:Number = parseFloat(brightness);
			if (value != value) throw new ArgumentError("Bad filter origin: " + value);

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
	}
}