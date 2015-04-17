package {
	import flash.display.Sprite;

	import starling.core.Starling;

	[SWF(width="600", height="600")]
	public class Debug extends Sprite
	{
		public function Debug()
		{
			var starling:Starling = new Starling(Main, stage);
			starling.start();
		}
	}
}

import flash.geom.Rectangle;

import starling.core.RenderSupport;
import starling.display.DisplayObject;
import starling.display.Sprite;
import starling.textures.Texture;

import talon.starling.Filler;

class Main extends Sprite
{
	[Embed(source="DebugBitmap.png")] private static const BITMAP:Class;

	function Main()
	{
		var texture:Texture = Texture.fromEmbeddedAsset(BITMAP);
		var scale:DisplayObject = addChild(new Scale9(texture));
//		scale.x = scale.y = 32;
	}
}

class Scale9 extends Sprite
{
	private var _filler:Filler;

	public function Scale9(texture:Texture):void
	{
		_filler = new Filler();
		_filler.texture = texture;
		_filler.width = _filler.height = 64*6;
		_filler.grid = new Rectangle(64, 64, 64, 64);
//		_filler.grid = new Rectangle(0, 0, texture.width, texture.height);
	}

	public override function render(support:RenderSupport, parentAlpha:Number):void
	{
		_filler.render(support, parentAlpha);

		super.render(support, parentAlpha);
	}
}