package
{
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	import starling.core.Starling;
	import starling.display.Sprite;

	import starling.events.Event;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;

	import starling.extensions.talon.display.TalonNode;
	import starling.extensions.talon.display.TalonLabel;
	import starling.extensions.talon.utils.TalonFactory;
	import starling.textures.Texture;

	public class TalonDebugStartup extends MovieClip
	{
		[Embed(source="../assets/up.png")] private static const UP_BYTES:Class;
		[Embed(source="../assets/over.png")] private static const OVER_BYTES:Class;
		[Embed(source="../assets/down.png")] private static const DOWN_BYTES:Class;

		private var _document:Sprite;

		private var _talon:TalonNode;

		public function TalonDebugStartup()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onResize);

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

				#leaders
				{
					backgroundColor: gray;
				}


				#leaders:hover
				{
					backgroundColor: olive;
					fontSize: 20px;
				}

				#leaders *
				{
					backgroundColor: blue;
					width: 10px;
					height: 10px;
				}

				*
				{
					fontName: Calibri;
					fontColor: maroon;
				}

				.tmp .brown
				{
					backgroundColor: olive;
					width: 100%;
					height: 128px;
				}

				#4d *
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
				}

			]]></literal>.valueOf();

			var config:XML =
				<node id="root" layout="flow" orientation="vertical" valign="center" halign="center" gap="4px">
					<node layout="flow" class="tmp" orientation="vertical" width="50%" padding="0px 8px" gap="4px" fontSize="24px">
						<label text="Header" width="100%" />
						<node id="2d" width="100%" height="48px" backgroundColor="gray" />
						<node id="3d" class="brown nerd" width="100%" height="128px" />
						<node id="4d" layout="flow" orientation="horizontal" gap="4px" width="100%" height="48px" fontSize="10px">
							<button />
							<button backgroundChromeColor="#AAAAFF" />
							<button />
						</node>
					</node>
					<node id="leaders" width="256px" height="48px">
						<node id="tmp" />
						<label text="Hardcore!" />
					</node>
					<node id="mother_ship" width="256px" height="48px" backgroundColor="blue" />
				</node>;


			var builder:TalonFactory = new TalonFactory();
			builder.addLibraryPrototype("root", config);
			builder.addLibraryStyleSheet(css);
			builder.addLibraryResource("/img/up.png", Texture.fromEmbeddedAsset(UP_BYTES));
			builder.addLibraryResource("/img/over.png", Texture.fromEmbeddedAsset(OVER_BYTES));
			builder.addLibraryResource("/img/down.png", Texture.fromEmbeddedAsset(DOWN_BYTES));

			_talon = builder.build("root") as TalonNode;
			_document.addChild(_talon);
			onResize(null)
		}
	}
}