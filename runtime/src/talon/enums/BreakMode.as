package talon.enums
{
	public final class BreakMode
	{
		public static const NONE:String = "none";
		public static const SOFT:String = "soft";
		public static const HARD:String = "hard";

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

		public static function isBreakBefore(mode:String):Boolean
		{
			return mode == BEFORE
				|| mode == BOTH;
		}

		public static function isBreakAfter(mode:String):Boolean
		{
			return mode == AFTER
				|| mode == BOTH;
		}
	}
}