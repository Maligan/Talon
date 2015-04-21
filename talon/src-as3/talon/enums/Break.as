package talon.enums
{
	public final class Break
	{
		public static const AUTO:String = "auto";
		public static const BEFORE:String = "before";
		public static const AFTER:String = "after";
		public static const BOTH:String = "both";

		/** Indicates whether the given break string is valid. */
		public static function isValid(mode:String):Boolean
		{
			return mode == BEFORE
				|| mode == AFTER
				|| mode == BOTH
				|| mode == AUTO
		}
	}
}