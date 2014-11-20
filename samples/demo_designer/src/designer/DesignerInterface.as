package designer
{
	import starling.display.DisplayObject;
	import starling.display.Sprite;
	import starling.extensions.talon.display.TalonSprite;

	public class DesignerInterface extends Sprite
	{
		[Embed(source="/../assets/interface.xml")]
		private static const INTERFACE:Class;

		private var _container:TalonSprite;

		public function DesignerInterface()
		{
			_container = new TalonSprite();
			addChild(_container);
		}

		public function setPrototype(view:DisplayObject):void
		{
			_container.removeChildren();
			_container.addChild(view);
			resizeTo(stage.stageWidth, stage.stageHeight);
		}

		public function resizeTo(width:int, height:int):void
		{
			_container.node.bounds.setTo(0, 0, width, height);
			_container.node.commit();
		}
	}
}