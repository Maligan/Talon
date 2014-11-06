package starling.extensions.talon.display
{
	import feathers.display.Scale9Image;
	import feathers.textures.Scale9Textures;

	import flash.geom.Rectangle;

	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.extensions.talon.core.Node;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.text.TextFieldAutoSize;
	import starling.textures.Texture;
	import starling.utils.HAlign;
	import starling.utils.VAlign;

	public class TalonComponentBase extends Sprite implements TalonComponent
	{
		[Embed(source="../../../../../assets/orange.png")]
		private static const BYTES:Class;
		private static const TEXTURE:Texture = Texture.fromEmbeddedAsset(BYTES);

		private var _background:Quad;
		private var _image:Scale9Image;
		private var _label:TextField;
		private var _node:Node;

		public function TalonComponentBase()
		{
			_node = new Node();
			_node.addEventListener(Event.CHANGE, onBoxChange);
			_node.addEventListener(Event.RESIZE, onBoxResize);

			_background = new Quad(100, 100, 0);
			_background.useHandCursor = true;
			addChild(_background);

			_label = new TextField(0, 0, "", BitmapFont.MINI, -1);
			_label.hAlign = HAlign.LEFT;
			_label.vAlign = VAlign.TOP;
			_label.color = 0xFFFF00;
			_label.autoSize = TextFieldAutoSize.BOTH_DIRECTIONS;
			_label.x = _label.y = 2;
			addChild(_label);

			addEventListener(TouchEvent.TOUCH, onTouch);
		}

		private function onTouch(e:TouchEvent):void
		{
			if (e.getTouch(_background, TouchPhase.HOVER) != null)
			{
				_background.color = 0x888888;
			}
			else if (e.getTouch(_background) == null)
			{
				_background.color = parseInt(node.getAttribute("backgroundColor"));
			}
			else if (e.getTouch(_background, TouchPhase.ENDED) != null)
			{
				trace("Click", _node.getAttribute("id"))
			}
		}

		public override function addChild(child:DisplayObject):DisplayObject
		{
			(child is TalonComponent) && node.addChild(TalonComponent(child).node);
			return super.addChild(child);
		}

		private function onBoxChange(e:Event):void
		{
			_background.visible = node.getAttribute("backgroundColor") != null;
			_background.color = parseInt(node.getAttribute("backgroundColor"));
			_label.text = node.getAttribute("id") ? ("#" + String(node.getAttribute("id")).toUpperCase()) : null;

			var image:String = node.getAttribute("backgroundImage");
			if (image != null)
			{
				_background.visible = false;

				if (_image == null)
				{
					var bounds:Rectangle = new Rectangle(0, 0, TEXTURE.width, TEXTURE.height);
					bounds.inflate(-7, -7);
					_image = new Scale9Image(new Scale9Textures(TEXTURE, bounds));
					addChild(_image);
				}
			}
		}

		private function onBoxResize(e:Event):void
		{
			x = Math.round(node.bounds.x);
			y = Math.round(node.bounds.y);
			_background.width = Math.ceil(node.bounds.width);
			_background.height = Math.ceil(node.bounds.height);

			if (_image)
			{
				_image.width = Math.ceil(node.bounds.width);
				_image.height = Math.ceil(node.bounds.height);
			}

//			clipRect = new Rectangle(0, 0, node.layout.bounds.width, node.layout.bounds.height);
		}

		public function get node():Node
		{
			return _node;
		}
	}
}