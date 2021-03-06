package talon.enums
{
	public final class Orientation
	{
		public static const HORIZONTAL:String = "horizontal";
		public static const VERTICAL:String = "vertical";

		/** Indicates whether the given orientation string is valid. */
		public static function isValid(orientation:String):Boolean
		{
			return orientation == HORIZONTAL
				|| orientation == VERTICAL;
		}
	}
}