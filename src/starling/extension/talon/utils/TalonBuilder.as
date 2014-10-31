package starling.extension.talon.utils
{
	import flash.utils.ByteArray;
	import starling.display.DisplayObject;
	import starling.extension.talon.core.StyleSheet;

	public class TalonBuilder
	{
		public static function fromArchive(bytes:ByteArray, onComplete:Function):void
		{

		}

		public static function fromXML(library:XML):TalonBuilder
		{
			return new TalonBuilder();
		}

		public function TalonBuilder()
		{
		}

		public function getResult(id:String):DisplayObject
		{
			return null;
		}

		//
		// Linkage
		//
		public function setLinkage(tag:String, displayObjectClass:Class):void
		{

		}

		//
		// Library
		//
		public function addLibraryTexture(id:String, texture:*):void
		{

		}

		public function addLibraryTexturesFromAtlas(atlas:*):void
		{

		}

		public function addLibraryStyleSheet(css:StyleSheet):void
		{

		}

		public function addLibraryConstant(id:String, value:String):void
		{

		}
	}
}
