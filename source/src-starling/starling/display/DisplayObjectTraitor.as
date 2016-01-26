package starling.display
{
	import starling.filters.FragmentFilter;
	import starling.rendering.BatchToken;

	/** Provide access to starling DisplayObject internal fields. */
	[ExcludeClass]
	public class DisplayObjectTraitor
	{
		public static function getLastChildChangeFrameID(target:DisplayObject):uint { return target._lastChildChangeFrameID }
		public static function setLastChildChangeFrameID(target:DisplayObject, value:uint):void { target._lastChildChangeFrameID = value }

		public static function getParentOrSelfChangeFrameID(target:DisplayObject):uint { return target._lastParentOrSelfChangeFrameID }
		public static function setParentOrSelfChangeFrameID(target:DisplayObject, value:uint):void { target._lastParentOrSelfChangeFrameID = value }

		public static function getPushToken(target:DisplayObject):BatchToken { return target._pushToken }
		public static function setPushToken(target:DisplayObject, value:BatchToken):void { target._pushToken = value }

		public static function getPopToken(target:DisplayObject):BatchToken { return target._popToken }
		public static function setPopToken(target:DisplayObject, value:BatchToken):void { target._popToken = value }

		public static function getHasVisibleArea(target:DisplayObject):Boolean { return target._hasVisibleArea }
		public static function setHasVisibleArea(target:DisplayObject, value:Boolean):void { target._hasVisibleArea = value }

		public static function getFilter(target:DisplayObject):FragmentFilter { return target._filter }
		public static function setFilter(target:DisplayObject, value:FragmentFilter):void { target._filter = value }

		public static function getMask(target:DisplayObject):DisplayObject { return target._mask }
		public static function setMask(target:DisplayObject, value:DisplayObject):void { target._mask = value }
	}
}