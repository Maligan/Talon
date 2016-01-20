package talon
{
	import flash.display.MovieClip;
	import flash.geom.Rectangle;

	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.textures.Texture;
	import starling.utils.Align;
	import starling.utils.Color;

	import talon.enums.FillMode;
	import talon.starling.FillModeMesh;

	[SWF(width="640", height="480")]
	public class StartupTest extends MovieClip
	{
		[Embed(source="texture.png")]
		private var _textureClass:Class;

		private var _starling:Starling;

		public function StartupTest()
		{
			_starling = new Starling(Sprite, stage);
			_starling.addEventListener(Event.ROOT_CREATED, initialize);
			_starling.start();

			stage.addEventListener(Event.RESIZE, onResize);
		}

		private function onResize(e:*):void
		{
			_starling.viewPort = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
			_starling.stage.stageWidth = stage.stageWidth;
			_starling.stage.stageHeight = stage.stageHeight;
		}

		private function initialize():void
		{
			_starling.stage.color = Color.WHITE;
			var root:Sprite = _starling.root as Sprite;

			var background:FillModeMesh = new FillModeMesh();
			background.color = Color.WHITE;
			background.setScale9Offsets(32, 32, 32, 32);

			background.verticalFillMode = FillMode.NONE;
			background.horizontalFillMode = FillMode.STRETCH;

			background.verticalAlign = Align.BOTTOM;
			background.horizontalAlign = Align.RIGHT;

			background.texture = Texture.fromEmbeddedAsset(_textureClass);
			background.width = background.texture.width*1.75;
			background.height = background.texture.width*1.75;

			root.addChild(background);
		}
	}
}