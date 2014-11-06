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

	import starling.extensions.talon.display.TalonComponent;

	import starling.extensions.talon.display.TalonComponentBase;
	import starling.extensions.talon.core.StyleSheet;
	import starling.extensions.talon.layout.Layout;
	import starling.extensions.talon.layout.StackLayout;

	public class TalonDebugStartup extends MovieClip
	{
		private var _root:Sprite;

		private var _style:StyleSheet;
		private var _talon:TalonComponentBase;

		public function TalonDebugStartup()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onResize);

			Layout.registerLayoutAlias("none", new Layout());
			Layout.registerLayoutAlias("stack", new StackLayout());

			var style:String = " .red { backgroundColor: 0xFF0000; } .tmp .brown { backgroundImage: /orange.png; backgroundColor: 0x964B00; width: 100%; height: 128px } #2d { backgroundImage: /orange.png } .my, .tag { margin: auto; padding: 10px 10px 10px }";
			_style = new StyleSheet();
			_style.parse(style);

//			var node:Node = new Node();
//			node.attributes.minHeight = "100px";
//			node.attributes.paddingBottom = "10px";
//			node.width.parse("auto");
//			node.attributes.width = "auto";

			new Starling(Sprite, stage);
			Starling.current.addEventListener(Event.ROOT_CREATED, onRootCreated);
			Starling.current.start();
			Starling.current.showStats = true;
		}

		private function onResize(e:*):void
		{
			Starling.current.stage.stageWidth = stage.stageWidth;
			Starling.current.stage.stageHeight = stage.stageHeight;
			Starling.current.viewPort = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);

			if (_talon != null)
			{
				_talon.node.bounds.setTo(0, 0, stage.stageWidth, stage.stageHeight);
				_talon.node.commit();
			}
		}

		private function onRootCreated(e:Event):void
		{
			_root = Sprite(Starling.current.root);


			var main:XML =
				<node layout="stack" id="root" width="100%" height="100%" padding="16px" orientation="vertical" halign="center" valign="center" gap="4px">

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

					<node layout="stack" orientation="vertical" halign="right" width="100%" height="64px">
						<node id="right" width="50%" height="64px" backgroundColor="0x666666" />
					</node>

					<node layout="stack" orientation="vertical" halign="center" width="100%" height="64px">
						<node id="center" width="50%" height="64px" backgroundColor="0x666666" />
					</node>

					<node layout="stack" orientation="vertical" halign="left" width="100%" height="64px">
						<node id="left" width="50%" height="64px" backgroundColor="0x666666" />
					</node>

					<node id="footer" width="100%" height="*" backgroundColor="0x666666" />

				</node>;

			var panel:XML =
				<node id="root" layout="stack" orientation="vertical" valign="center" halign="center" gap="4px">
					<node id="play" width="50%" height="48px" backgroundColor="0x888899" />
					<node layout="stack" class="tmp" orientation="vertical" width="50%" padding="0px 8px" gap="4px">
						<node id="2d" class="brown" />
						<node id="3d" class="brown" />
						<node id="4d" layout="stack" orientation="horizontal" gap="4px" width="100%" height="48px">
							<node id="prev" width="*" height="100%" backgroundImage="0x888888" />
							<node id="next" width="*" height="100%" backgroundImage="0x888888" />
							<node id="next" width="*" height="100%" backgroundImage="0x888888" />
						</node>
					</node>
					<node id="leaders" width="256px" height="48px" backgroundColor="0x888899" />
					<node id="mother ship" width="256px" height="48px" backgroundColor="0xFF000" />
				</node>;

			_talon = fromXML(panel) as TalonComponentBase;
			_root.addChild(_talon);

			onResize(null)
		}

		private function fromXML(xml:XML):DisplayObject
		{
			var element:DisplayObject = new TalonComponentBase();

			if (element is TalonComponent)
			{
				var node:Node = TalonComponent(element).node;

				for each (var attribute:XML in xml.attributes())
				{
					var name:String = attribute.name();
					var value:String = attribute.valueOf();
					node.setAttribute(name, value);
				}

				node.setAttribute("type", xml.name());
				node.setStyleSheet(_style);
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