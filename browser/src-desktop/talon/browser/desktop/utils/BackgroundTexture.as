package talon.browser.desktop.utils
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.utils.ByteArray;

	import starling.extensions.TalonFactory;
	import starling.textures.Texture;
	import starling.utils.Color;

	public class BackgroundTexture
	{
		public static function fromObject(object:Object):BackgroundTexture
		{
			var result:BackgroundTexture = new BackgroundTexture();
			result._name = object["name"];
			result._color = object["color"];
			result._texture = object["texture"];
			return result;
		}
		
		public static function fromFile(file:File, talon:TalonFactory):BackgroundTexture
		{
			var regex:RegExp = /([^\?\/\\]+?)(?:\.([\w\-]+))?(?:\?.*)?$/;
			var matches:Array = regex.exec(unescape(file.url));
			var name:String = (matches && matches.length > 0) ? matches[1] : "UNKNOWN";

			var result:BackgroundTexture = new BackgroundTexture();
			result._name = name;
			result._texture = name;
			result._file = file;
			result._talon = talon;
			return result;
		}

		
		private var _name:String;
		private var _color:uint;
		private var _texture:String;

		private var _file:File;
		private var _talon:TalonFactory;

		private var _promise:Promise;

		public function initialize():Promise
		{
			if (_promise == null)
			{
				var self:BackgroundTexture = this;

				_promise = new Promise();
				
				// From file
				if (_file)
				{
					var bytes:ByteArray = FileUtil.readBytes(_file);
					
					if (bytes.length == 0)
					{
						_promise.reject();
					}
					else
					{
						var loader:Loader = new Loader();
						loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoad);
						loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoad);
						loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoad);
						loader.loadBytes(bytes);
					}
					
					function onLoad(e:Event):void
					{
						loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLoad);
						loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoad);
						loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoad);
						
						if (e.type == Event.COMPLETE)
						{
							try {
								var bitmapData:BitmapData = Bitmap(loader.content).bitmapData;
								var texture:Texture = Texture.fromBitmapData(bitmapData);
								_talon.addResource(_name, texture);
								_color = getAverageColor(bitmapData);
							} catch (e:Error) { }
						}

						_promise.fulfill(self);
					}
				}
				
				// From assets
				else
				{
					_promise.fulfill(self);
				}
			}
			
			return _promise;
		}

		private function getAverageColor(bitmap:BitmapData):uint
		{
			var red:Number = 0;
			var green:Number = 0;
			var blue:Number = 0;

			for (var x:int = 0; x < bitmap.width; x++)
			{
				for (var y:int = 0; y < bitmap.height; y++)
				{
					var color:uint = bitmap.getPixel(x, y);
					red += Color.getRed(color);
					green += Color.getGreen(color);
					blue += Color.getBlue(color);
				}
			}

			var k:Number = 1/(bitmap.width*bitmap.height);
			return Color.rgb(red*k, green*k, blue*k)
		}

		public function get name():String { return _name; }
		public function get texture():String { return _texture; }
		public function get color():uint { return _color; }
	}
}
