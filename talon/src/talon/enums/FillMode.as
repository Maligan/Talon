package talon.enums
{
	public final class FillMode
	{
		public static const NONE:String = "none";
		public static const SCALE:String = "scale";
		public static const REPEAT:String = "repeat";

		/** Indicates whether the given fill mode string is valid. */
		public static function isValid(mode:String):Boolean
		{
			return mode == SCALE
				|| mode == NONE
				|| mode == REPEAT;
		}
	}
}