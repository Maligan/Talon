package
{
	import flash.display.MovieClip;
	import flash.geom.Rectangle;

	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Sprite;

	import starling.events.Event;
	import starling.extensions.talon.core.Node;

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
				_talon.node.layout.bounds.setTo(0, 0, stage.stageWidth, stage.stageHeight);
				_talon.node.layout.commit();
			}
		}

		private function onRootCreated(e:Event):void
		{
			_root = Sprite(Starling.current.root);


			var main:XML =
				<node layout="stack" id="root" width="100%" height="100%" padding="16px 64px 0 0" orientation="vertical" halign="right" valign="center" gap="4px">

					<node id="begin" width="100%" height="64px" backgroundColor="0x666666" />

					<node layout="stack" width="100%" height="64px" orientation="horizontal" halign="center" gap="4px">
						<node id="icon1" width="*" height="64px" backgroundColor="0x555555" />
						<node id="icon2" width="64" height="64px" backgroundColor="0x666666" />

						<node layout="stack" orientation="vertical" width="64" height="64px" backgroundColor="0x777777">
							<node id="j" width="100%" height="*" backgroundColor="0x886666"/>
							<node id="j2" width="100%" height="*" backgroundColor="0x668866"/>
							<node id="j3" width="100%" height="*" backgroundColor="0x666688"/>
						</node>

						<node id="icon4" width="64" height="64px" backgroundColor="0x888888" />
						<node id="icon4" width="*" height="64px" backgroundColor="0x999999" />
					</node>

					<node id="end" width="50%" height="64px" backgroundColor="0x666666" />

					<node id="back1" layout="stack" orientation="vertical" halign="center" width="100%" height="64px">
						<node id="loop" width="50%" height="64px" backgroundColor="0x666666" />
					</node>

					<node id="back2" layout="stack" orientation="vertical" halign="left" width="100%" height="64px">
						<node id="loop" width="50%" height="64px" backgroundColor="0x666666" />
					</node>

				</node>;

			var panel:XML =
				<node layout="stack" width="100%" height="100%" orientation="vertical" valign="center" gap="4px">
				</node>;

				_talon = fromXML(main) as TalonComponentBase;
			_root.addChild(_talon);

			onResize(null)
		}

		private function fromXML(xml:XML):DisplayObject
		{
			var element:DisplayObject = new TalonComponentBase();

			if (element is TalonComponentBase)
			{
				var box:Node = TalonComponentBase(element).node;
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