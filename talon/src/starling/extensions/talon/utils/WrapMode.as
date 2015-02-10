package starling.extensions.talon.utils
{
	import starling.errors.AbstractClassError;

	public class WrapMode
	{
		public static const NEVER:String = "never";
		public static const AUTO:String = "auto";
		public static const MANUAL:String = "manual";

		/** Indicates whether the given break mode string is valid. */
		public static function isValid(mode:String):Boolean
		{
			return mode == NEVER
				|| mode == AUTO
				|| mode == MANUAL;
		}

		/** @private */
		public function WrapMode()
		{
			throw new AbstractClassError();
		}
	}
}