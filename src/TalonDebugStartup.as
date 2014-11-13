package
{
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	import starling.core.Starling;
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
			_document = Sprite(Starling.current.root);

			var css:String =
			<literal><![CDATA[

				root
				{
					fontName: Calibri;
					fontColor: maroon;
				}

				#buttons *
				{
					width: *;
					height: 100%;
				}

				/* Default button skin. */
				button:hover { backgroundImage: /img/over.png; }
				button:active { backgroundImage: /img/down.png; }
				button
				{
					backgroundImage: /img/up.png;
					background9Scale: 8px;
					backgroundChromeColor: #AAFFAA;
					cursor: button;

					fontName: mini;
					fontSize: 8px;
				}

			]]></literal>.valueOf();

			var config:XML =
				<node id="root" valign="center" halign="center" gap="4px">
					<node layout="flow" class="tmp" orientation="vertical" width="50%" padding="0px 8px" gap="4px" fontSize="24px">
						<label id="header" text="Header" width="100%" />
						<node width="100%" height="48px" backgroundColor="gray" />
						<node class="brown nerd" width="100%" height="128px" />
						<node id="buttons" layout="flow" orientation="horizontal" gap="4px" width="100%" height="48px" fontSize="10px">
							<button><label id="mini" text="MINI TEXT" /></button>
							<button />
						</node>
					</node>
					<node fontName="Consolas" id="leaders" width="256px" height="48px">
						<node id="tmp" />
						<label text="Hardcore!" />
					</node>
					<node id="mother_ship" width="256px" height="48px" backgroundColor="blue" />
				</node>;


			var factory:TalonFactory = new TalonFactory();
			factory.addLibraryPrototype("root", config);
			factory.addLibraryStyleSheet(css);
			factory.addLibraryResource("/img/up.png", Texture.fromEmbeddedAsset(UP_BYTES));
			factory.addLibraryResource("/img/over.png", Texture.fromEmbeddedAsset(OVER_BYTES));
			factory.addLibraryResource("/img/down.png", Texture.fromEmbeddedAsset(DOWN_BYTES));

			_talon = factory.build("root") as TalonSprite;
			_document.addChild(_talon);
			onResize(null)
		}
	}
}
