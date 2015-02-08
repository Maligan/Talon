package starling.extensions.talon.utils
{
	import starling.errors.AbstractClassError;

	public class BreakMode
	{
		public static const BEFORE:String = "before";
		public static const AFTER:String = "after";
		public static const BOTH:String = "both";

		/** Indicates whether the given break mode string is valid. */
		public static function isValid(mode:String):Boolean
		{
			return mode == BEFORE
				|| mode == AFTER
				|| mode == BOTH;
		}

		/** @private */
		public function BreakMode()
		{
			throw new AbstractClassError();
		}
	}
}
