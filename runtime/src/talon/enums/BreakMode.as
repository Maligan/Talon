package talon.enums
{
	public final class BreakMode
	{
		// TODO: Add NONE (none before, none after, none both?) type, which works like nbsp.
		//       Or make two-dimension attributes: breakBefore, breakAfter with values: AUTO, NONE, ALWAYS
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