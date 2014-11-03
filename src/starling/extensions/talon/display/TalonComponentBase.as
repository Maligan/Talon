package starling.extensions.talon.display
{
	import starling.display.DisplayObject;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.extensions.talon.core.Node;

	public class TalonComponentBase extends Sprite implements TalonComponent
	{
		private var _background:Quad;
		private var _box:Node;

		public function TalonComponentBase()
		{
			_box = new Node();
			_box.addEventListener(Event.CHANGE, onBoxChange);
			_box.addEventListener(Event.RESIZE, onBoxResize);

			_background = new Quad(100, 100, 0);
			addChild(_background);
		}

		public override function addChild(child:DisplayObject):DisplayObject
		{
			(child is TalonComponent) && box.children.push(TalonComponent(child).box);
			return super.addChild(child);
		}

		private function onBoxChange(e:Event):void
		{
			_background.color = parseInt(box.attributes.backgroundColor);
		}

		private function onBoxResize(e:Event):void
		{
			_background.x = box.layout.bounds.x;
			_background.y = box.layout.bounds.y;
			_background.width = box.layout.bounds.width;
			_background.height = box.layout.bounds.height;
		}

		public function get box():Node
		{
			return _box;
		}
	}
}