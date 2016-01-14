package talon
{
	import flash.display.MovieClip;
	import flash.geom.Rectangle;

	import starling.core.Starling;
	import starling.display.Mesh;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.textures.Texture;
	import starling.utils.Color;

	import talon.enums.FillMode;

	import talon.layout.Layout;
	import talon.starling.FillModeMesh;

	import talon.starling.TalonSprite;
	import talon.utils.Gauge;

	public class StartupTest extends MovieClip
	{
		private var _starling:Starling;
		private var _mesh:Mesh;

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
			background.setScale9Offsets(10, 20, 20, 10);
			background.verticalFillMode = FillMode.STRETCH;
			background.horizontalFillMode = FillMode.REPEAT;
			background.color = Color.RED;
			background.width = 100;
			background.height = 100;
//			background.texture = Texture.fromColor(25, 25, 0xFF0000);

			root.addChild(background);

//			var n1:TalonSprite = new TalonSprite();
//			var n2:TalonSprite = new TalonSprite();
//			var n3:TalonSprite = new TalonSprite();
//
//			n1.node.setAttribute(Attribute.LAYOUT, Layout.FLOW);
//			n2.node.width.setTo(50, Gauge.PERCENT);
//			n2.node.height.setTo(100, Gauge.PERCENT);
//			n2.node.setAttribute(Attribute.BACKGROUND_COLOR, "#FF0000");
//			n3.node.width.setTo(50, Gauge.PERCENT);
//			n3.node.height.setTo(100, Gauge.PERCENT);
//
//			n1.addChild(n2);
//			n1.addChild(n2);
//			n1.node.bounds.setTo(0, 0, _starling.stage.stageWidth, _starling.stage.stageHeight);
//
//			root.addChild(n1);
		}
	}
}