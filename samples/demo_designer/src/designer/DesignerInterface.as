package designer
{
	import starling.display.DisplayObject;
	import starling.display.Sprite;

	public class DesignerInterface extends Sprite
	{
		[Embed(source="/../assets/interface.xml")]
		private static const INTERFACE:Class;

		public function DesignerInterface()
		{
		}

		public function setPrototype(view:DisplayObject):void
		{

		}

		public function resizeTo(width:int, height:int):void
		{

		}
	}
}