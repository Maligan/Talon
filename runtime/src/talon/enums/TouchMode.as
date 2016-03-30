package talon.enums
{
	public final class TouchMode
	{
		public static const NONE:String = "none";
		public static const LEAF:String = "leaf";
		public static const BRANCH:String = "branch";

		/** Indicates whether the given touch mode string is valid. */
		public static function isValid(mode:String):Boolean
		{
			return mode == NONE
				|| mode == LEAF
				|| mode == BRANCH;
		}
	}
}