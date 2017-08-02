package talon.browser.desktop.filetypes
{
	import flash.display.Loader;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.utils.ByteArray;

	import starling.textures.AtfData;
	import starling.textures.Texture;

	import talon.browser.platform.document.log.DocumentMessage;

	public class TextureAsset extends Asset
	{
		private var _id:String;
		private var _texture:Texture;
		private var _resources:Object;

		//
		// Attach
		//
		override protected function activate():void
		{
			var bytes:ByteArray = readFileBytesOrReportAndNull();
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

				function onComplete(result:*, reason:String):void
				{
					if (document)
					{
						if (result) addTexture(result);
						else reportMessage(DocumentMessage.FILE_CONTAINS_WRONG_IMAGE_FORMAT, file.path, reason);
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
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onError);
				loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
				loader.loadBytes(bytes);
			}
			else
			{
				onError();
			}

			function onComplete(e:*):void
			{
				complete(loader.content, null);
			}

			function onError(e:ErrorEvent = null):void
			{
				if (e is IOErrorEvent) complete(null, IOErrorEvent(e).text);
				else if (e is SecurityErrorEvent) complete(null, SecurityErrorEvent(e).text);
				else complete(null, "Texture bytes is null");
			}
		}

		private function addTexture(data:*):void
		{
			try
			{
				_id = document.factory.getResourceId(file.path);
				_texture = Texture.fromData(data);
				_resources = {};
				_resources[_id] = _texture;
				document.factory.appendResources(_resources);
			}
			catch (e:Error)
			{
				reportMessage(DocumentMessage.TEXTURE_ERROR, file.path, e.message);
			}
		}

		//
		// Detach
		//
		override protected function deactivate():void
		{
			document.factory.removeResources(_resources);

			_id = null;
			_resources = null;

			_texture && _texture.dispose();
			_texture = null;
		}
	}
}