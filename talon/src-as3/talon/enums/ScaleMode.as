package talon.enums
{
	public final class ScaleMode
	{
		public static const NONE:String = "none";
		public static const STRETCH:String = "stretch";
		public static const ZOOM:String = "zoom";
		public static const LETTERBOX:String = "letterbox";

		/** Indicates whether the given scale mode string is valid. */
		public static function isValid(mode:String):Boolean
		{
			return mode == NONE
				|| mode == STRETCH
				|| mode == ZOOM
				|| mode == LETTERBOX;
		}
	}
}
