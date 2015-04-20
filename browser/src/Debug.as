package {
	import flash.display.Sprite;

	import starling.core.Starling;
	import starling.utils.HAlign;
	import starling.utils.VAlign;

	[SWF(width="600", height="600")]
	public class Debug extends Sprite
	{
		public function Debug()
		{
			var starling:Starling = new Starling(Main, stage);
			starling.showStatsAt(HAlign.RIGHT, VAlign.BOTTOM);
			starling.enableErrorChecking = false;
			starling.start();
		}
	}
}

import flash.geom.Rectangle;

import starling.core.RenderSupport;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.textures.Texture;

import talon.starling.TextureFiller;

class Main extends Sprite
{
	[Embed(source="Button.png")] private static const BITMAP:Class;

	function Main()
	{
		var texture:Texture = Texture.fromEmbeddedAsset(BITMAP);
		var scale:DisplayObject = addChild(new Scale9(texture));
		scale.x = scale.y = 10;
//		scale.rotation = 100;

	}
}

class Scale9 extends Sprite
{
	private var _filler:TextureFiller;

	public function Scale9(texture:Texture):void
	{
		_filler = new TextureFiller();
//		_filler.texture = texture;
		_filler.width = texture.width*3;
		_filler.height = texture.height*3;

		_filler.transparent = false;
		_filler.color = 0xFF0000;

		_filler.setScaleOffsets(50, 50, 50, 50);
	}

	public override function render(support:RenderSupport, parentAlpha:Number):void
	{
		_filler.render(support, parentAlpha);

		super.render(support, parentAlpha);
	}
}