package talon.enums
{
	import starling.errors.AbstractClassError;

	public class BindMode
	{
		public static const ONCE:String = "once";
		public static const ONE_WAY:String = "oneway";
		public static const TWO_WAY:String = "twoway";

		/** Indicates whether the given bind mode string is valid. */
		public static function isValid(mode:String):Boolean
		{
			return mode == ONCE
				|| mode == ONE_WAY
				|| mode == TWO_WAY;
		}

		/** @private */
		public function BindMode()
		{
			throw new AbstractClassError();
		}
	}
}