package talon.enums
{
	public final class FillMode
	{
		public static const SCALE:String = "scale";
		public static const CLIP:String = "clip";
		public static const REPEAT:String = "repeat";

		/** Indicates whether the given fill mode string is valid. */
		public static function isValid(mode:String):Boolean
		{
			return mode == SCALE
				|| mode == CLIP
				|| mode == REPEAT;
		}
	}
}
