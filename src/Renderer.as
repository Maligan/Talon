package
{
	import flash.display.MovieClip;
	import flash.geom.Rectangle;

	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Sprite;

	import starling.events.Event;
	import starling.extensions.talon.core.Box;

	import flash.display.StageAlign;
	import flash.display.StageScaleMode;

	import starling.extensions.talon.display.TalonComponentBase;

	public class Renderer extends MovieClip
	{
		private var _root:Sprite;

		public function Renderer()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onResize);

			new Starling(Sprite, stage);
			Starling.current.addEventListener(Event.ROOT_CREATED, onRootCreated);
			Starling.current.start();
		}

		private function onResize(e:*):void
		{
			Starling.current.stage.stageWidth = stage.stageWidth;
			Starling.current.stage.stageHeight = stage.stageHeight;
			Starling.current.viewPort = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
		}

		private function onRootCreated(e:Event):void
		{
			_root = Sprite(Starling.current.root);

			var info:XML = <box width="100" height="100" x="10" y="10" />;
			var element:DisplayObject = fromXML(info);
			_root.addChild(element);
		}

		private function fromXML(xml:XML):DisplayObject
		{
			var element:DisplayObject = new TalonComponentBase();

			if (element is TalonComponentBase)
			{
				var box:Box = TalonComponentBase(element).box;

				for each (var attribute:XML in xml.attributes())
				{
					var name:String = attribute.name();
					var value:String = attribute.valueOf();
					box.attributes[name] = value;
				}
			}

			return element;
		}
	}
}