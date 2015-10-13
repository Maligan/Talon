package talon.browser.plugins.tools.types
{
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.utils.ByteArray;

	import starling.textures.AtfData;
	import starling.textures.Texture;

	import talon.browser.document.log.DocumentMessage;

	public class TextureAsset extends Asset
	{
		private var _id:String;
		private var _texture:Texture;

		//
		// Attach
		//
		override protected function initialize():void
		{
			var bytes:ByteArray = readFileBytesOrReport();
			if (bytes == null) return;

			var isATF:Boolean = AtfData.isAtfData(bytes);
			if (isATF)
			{
				addTexture(bytes);
			}
			else
			{
				taskBegin();

				decode(bytes, onComplete);

				function onComplete(result:*):void
				{
					if (document)
					{
						if (result) addTexture(result);
						else reportMessage(DocumentMessage.FILE_CONTAINS_WRONG_IMAGE_FORMAT, file.url);
					}

					taskEnd();
				}
			}
		}

		private function decode(bytes:ByteArray, complete:Function):void
		{
			if (bytes && bytes.length > 0)
			{
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
				loader.loadBytes(bytes);
			}
			else
			{
				onIOError();
			}

			function onComplete(e:*):void
			{
				complete(loader.content);
			}

			function onIOError(e:* = null):void
			{
				complete(null);
			}
		}

		private function addTexture(data:*):void
		{
			try
			{
				_id = document.factory.getResourceId(file.url);
				_texture = Texture.fromData(data);
				document.factory.addResource(_id, _texture);
			}
			catch (e:Error)
			{
				reportMessage(DocumentMessage.TEXTURE_ERROR, file.url, e.message);
			}
		}

		//
		// Detach
		//
		override protected function dispose():void
		{
			document.factory.removeResource(_id);
			_id = null;

			_texture && _texture.dispose();
			_texture = null;
		}
	}
}