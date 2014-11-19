package
{
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Sprite;

	import starling.events.Event;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;

	import starling.extensions.talon.core.Gauge;

	import starling.extensions.talon.core.Node;

	import starling.extensions.talon.display.TalonSprite;
	import starling.extensions.talon.display.TalonTextField;
	import starling.extensions.talon.utils.TalonFactory;
	import starling.textures.Texture;

	public class TalonDebugStartup extends MovieClip
	{
		[Embed(source="../assets/up.png")] private static const UP_BYTES:Class;
		[Embed(source="../assets/over.png")] private static const OVER_BYTES:Class;
		[Embed(source="../assets/down.png")] private static const DOWN_BYTES:Class;

		private var _document:Sprite;
		private var _talon:TalonSprite;

		public function TalonDebugStartup()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onResize);

			var node:Node = new Node();
			node.setStyleSheet(null);
			node.setResources(null);

			new Starling(Sprite, stage);
			Starling.current.addEventListener(Event.ROOT_CREATED, onRootCreated);
			Starling.current.start();
			Starling.current.showStats = false;
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

		private var _factory:TalonFactory;

		private function onRootCreated(e:Event):void
		{
			_document = Sprite(Starling.current.root);

			var css:String =
			<literal><![CDATA[

				/* Default button skin. */
				button:hover { backgroundImage: resource(over); }
				button:active { backgroundImage: resource(down); }
				button
				{
					backgroundImage: resource(up);
					background9Scale: 8px;
					backgroundChromeColor: #AAFFAA;
					cursor: button;

					halign: center;
					valign: center;
					padding: 1em;
					clipping: true;

					fontName: Helvetica;
					fontSize: 18px;
					fontColor: white;

					minWidth: 48px;
					minHeight: 0px;
				}

			]]></literal>.valueOf();

			var config:XML =
				<node id="menu" halign="center" valign="center" gap="4px" orientation="vertical">
					<label class="header" width="*" text="Steam Age"/>
					<button id="challenge" onclick="challenge"> <label text="Challenge"/> </button>
					<button id="leaders" onclick="leaders"> <label text="Leaders"/> </button>
					<button id="mothership" onclick="mothership"> <label text="Mother Ship"/> </button>
				</node>;


			var button:XML = <button onclick="remove_me"><label text="I'm Button!" /></button>;

			_factory = new TalonFactory();
			_factory.addLibraryPrototype("root", config);
			_factory.addLibraryPrototype("button", button);

			_factory.addLibraryStyleSheet(css);
			_factory.addLibraryResource("up", Texture.fromEmbeddedAsset(UP_BYTES));
			_factory.addLibraryResource("over", Texture.fromEmbeddedAsset(OVER_BYTES));
			_factory.addLibraryResource("down", Texture.fromEmbeddedAsset(DOWN_BYTES));

			_talon = _factory.build("root") as TalonSprite;
			_document.addChild(_talon);
			_document.addEventListener(Event.TRIGGERED, onTriggered);
			onResize(null)
		}

		private function onTriggered(e:Event):void
		{
			var container:DisplayObjectContainer = _talon.getChildByName("container") as DisplayObjectContainer;

			if (e.data == "add")
			{
				container.addChild(_factory.build("button", false, false));
				onResize(null)
			}
			else if (e.data == "remove")
			{
				if (container.numChildren == 0) return;
				container.removeChildAt(container.numChildren - 1);
				onResize(null)
			}
			else if (e.data == "remove_me")
			{
				container.removeChild(e.target as DisplayObject);
				onResize(null)
			}
		}
	}
}
