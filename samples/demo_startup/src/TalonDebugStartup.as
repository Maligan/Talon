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
				button:hover { backgroundImage: /img/over.png; }
				button:active { backgroundImage: /img/down.png; }
				button
				{
					backgroundImage: /img/up.png;
					background9Scale: 8px;
					backgroundChromeColor: #AAFFAA;
					cursor: button;

					halign: center;
					valign: center;
					padding: 0.5em 1em;
					clipping: true;
					layout: none;

					fontName: Helvetica;
					fontSize: 18px;
					fontColor: white;

					width: 48px;
					height: 48px;
					minWidth: 48px;
					minHeight: 48px;
				}

			]]></literal>.valueOf();

			var config:XML =
				<node id="root" layout="absolute" padding="10px">
						<node id="container" anchor="auto 100% 100% auto" gap="4px" orientation="horizontal">
							<button/>
						</node>

						<node anchor="auto auto 100% 0%" gap="4px" orientation="horizontal">
							<button onclick="add"><label text="Add"/></button>
							<button onclick="remove"><label text="Remove"/></button>
						</node>
				</node>;

			var button:XML = <button onclick="remove_me"><label text="I'm Button!" /></button>;

			_factory = new TalonFactory();
			_factory.addLibraryPrototype("root", config);
			_factory.addLibraryPrototype("button", button);

			_factory.addLibraryStyleSheet(css);
			_factory.addLibraryResource("/img/up.png", Texture.fromEmbeddedAsset(UP_BYTES));
			_factory.addLibraryResource("/img/over.png", Texture.fromEmbeddedAsset(OVER_BYTES));
			_factory.addLibraryResource("/img/down.png", Texture.fromEmbeddedAsset(DOWN_BYTES));

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
