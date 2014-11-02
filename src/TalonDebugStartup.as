package
{
	import flash.display.MovieClip;
	import flash.geom.Rectangle;

	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Sprite;

	import starling.events.Event;
	import starling.extensions.talon.core.Box;

	import flash.display.StageAlign;
	import flash.display.StageScaleMode;

	import starling.extensions.talon.core.Gauge;

	import starling.extensions.talon.display.TalonComponent;

	import starling.extensions.talon.display.TalonComponentBase;

	public class TalonDebugStartup extends MovieClip
	{
		private var _root:Sprite;
		private var _talon:TalonComponentBase;

		public function TalonDebugStartup()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onResize);


			var box:Box = new Box();
//			box.addEventListener(Event.CHANGE, onChange);

//			box.margin.parse("10px 10px 5px 7px");
//			box.margin.top.parse("6px");
			box.margin.parse("10px 9px")
			box.attributes.margin = "8px";
			box.attributes.marginBottom = "2px";

			trace(box.margin)


			function onChange(e:Event):void
			{
				trace("Changed", e.data, box[e.data]);
			}

			return;

			new Starling(Sprite, stage);
			Starling.current.addEventListener(Event.ROOT_CREATED, onRootCreated);
			Starling.current.start();
		}

		private function onResize(e:*):void
		{
			Starling.current.stage.stageWidth = stage.stageWidth;
			Starling.current.stage.stageHeight = stage.stageHeight;
			Starling.current.viewPort = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);

			if (_talon != null)
			{
				_talon.box.layout.bounds.setTo(0, 0, stage.stageWidth/3*2, stage.stageHeight/3*2);
				_talon.box.layout.commit();
			}
		}

		private function onRootCreated(e:Event):void
		{
			_root = Sprite(Starling.current.root);

			var info:XML =
				<box id="root" layout="stack" stackGap="3px" stackDirection="bottom" width="200" height="200" x="0" y="0" backgroundColor="0x00FF00">
					<box id="child1" layout="none" width="20%" valign="left" height="20%" backgroundColor="0x440000" />
					<box id="child2" layout="none" width="20%" valign="right" height="20%" backgroundColor="0x880000" />
					<box id="child3" layout="none" width="1*"  valign="center" height="*"   backgroundColor="0xFF0000" />
				</box>;

			_talon = fromXML(info) as TalonComponentBase;
			_root.addChild(_talon);

			onResize(null)
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

			if (element is DisplayObjectContainer)
			{
				var container:DisplayObjectContainer = DisplayObjectContainer(element);
				for each (var childXML:XML in xml.children())
				{
					var childElement:DisplayObject = fromXML(childXML);
					container.addChild(childElement);
				}
			}

			return element;
		}
	}
}