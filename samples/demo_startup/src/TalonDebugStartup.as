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

	[SWF(backgroundColor="#444444")]
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

				node#container
				{
					gap: 4px;
					interline: 4px;
					padding: 4px;
					wrap: true;
				}

				/* Default button skin. */
				button:hover { backgroundImage: resource(over); }
				button:active { backgroundImage: resource(down); }
				button
				{
					backgroundImage: resource(up);
					background9Scale: 3px;
					cursor: button;

					halign: center;
					valign: center;
					clipping: true;

					fontName: Tahoma;
					fontSize: 11px;
					fontColor: #C9C9C9;
					padding: 0px 10px 2px 10px;

					minWidth: 20px;
					minHeight: 20px;
				}

			]]></literal>.valueOf();

			var config:XML =
					<node id="root" width="100%" height="100%">
						<node id="container" width="*">
							<button/>
							<button/>
							<button width="auto"><label text="Remove from parent" /></button>
							<button/>
							<button/>
							<button/>
						</node>
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
