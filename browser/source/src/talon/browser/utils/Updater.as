package talon.browser.utils
{
	import flash.desktop.Updater;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;

	[Event(type="flash.events.ProgressEvent", name="progress")]
	[Event(type="flash.events.Event", name="complete")]
	[Event(type="flash.events.Event", name="change")]
	public class Updater extends EventDispatcher
	{
		private static function compare(version1:String, version2:String):int
		{
			var split1:Array = version1.split(".");
			var split2:Array = version2.split(".");

			while (split1.length && split2.length)
			{
				var index1:int = parseInt(split1.shift());
				var index2:int = parseInt(split2.shift());
				if (index1 != index2) return index1 - index2;
			}

			if (split1.length) return -1;
			if (split2.length) return +1;

			return 0;
		}

		private var _url:String;
		private var _version:String;

		private var _onlyCheckNewVersion:Boolean;

		private var _updater:flash.desktop.Updater;
		private var _updateDescriptorLoader:URLLoader;
		private var _updateDescriptorNamespace:Namespace;
		private var _updateDescriptorVersion:String;
		private var _updateDescriptorDescription:String;
		private var _updateApplicationFileLoader:URLLoader;
		private var _updateApplicationFile:File;
		private var _updateStep:int;
		private var _updateStatus:String;

		public function Updater(url:String, currentVersion:String)
		{
			_url = url;
			_version = currentVersion;

			_updateStep = UpdateStep.NOP;

			_updateDescriptorLoader = new URLLoader();
			_updateDescriptorLoader.addEventListener(Event.COMPLETE, onUpdateDescriptorLoaded);
			_updateDescriptorLoader.addEventListener(IOErrorEvent.IO_ERROR, onUpdateDescriptorLoadError);
			_updateDescriptorLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onUpdateDescriptorLoadError);

			_updateApplicationFileLoader = new URLLoader();
			_updateApplicationFileLoader.dataFormat = URLLoaderDataFormat.BINARY;
			_updateApplicationFileLoader.addEventListener(ProgressEvent.PROGRESS, onUpdateApplicationProgress);
			_updateApplicationFileLoader.addEventListener(Event.COMPLETE, onUpdateApplicationLoaded);
			_updateApplicationFileLoader.addEventListener(IOErrorEvent.IO_ERROR, onUpdateApplicationLoadError);
			_updateApplicationFileLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onUpdateApplicationLoadError);
		}

		public function stop():void
		{

		}

		//
		// Step 1: Download update descriptor
		//
		public function execute(onlyCheckNewVersion:Boolean = false):void
		{
			if (_updateStep != UpdateStep.NOP) return;

			_onlyCheckNewVersion = onlyCheckNewVersion;

			// Check update support
			if (flash.desktop.Updater.isSupported == false)
			{
				complete(UpdateStatus.UPDATER_IS_NOT_SUPPORTED);
				return;
			}

			var descriptorRequest:URLRequest = new URLRequest(_url);
			_updateStep = UpdateStep.DOWNLOAD_DESCRIPTOR;
			_updateDescriptorLoader.load(descriptorRequest);
		}

		private function onUpdateDescriptorLoaded(e:Event):void
		{
			// Check valid XML
			var descriptor:XML = toXML(_updateDescriptorLoader.data);
			if (descriptor == null)
			{
				complete(UpdateStatus.UPDATE_DESCRIPTOR_WRONG_XML);
				return;
			}

			// Check version number
			_updateDescriptorNamespace = descriptor.namespace();
			_updateDescriptorVersion = descriptor._updateDescriptorNamespace::versionNumber.valueOf();
			_updateDescriptorDescription = descriptor._updateDescriptorNamespace::description.valueOf();
			var updateVersionIsLess:Boolean = compare(_updateDescriptorVersion, _version) <= 0;
			if (updateVersionIsLess)
			{
				complete(UpdateStatus.UPDATE_DESCRIPTOR_VERSION_IS_LESS_OR_EQUALS);
				return;
			}

			// Check version url
			var descriptorApplicationURL:String = descriptor._updateDescriptorNamespace::url.valueOf();
			if (descriptorApplicationURL == null)
			{
				complete(UpdateStatus.UPDATE_DESCRIPTOR_WRONG_APPLICATION_URL);
				return;
			}

			// Check _onlyCheckNewVersion
			if (_onlyCheckNewVersion)
			{
				complete(UpdateStatus.UPDATE_DESCRIPTOR_LOADED);
				return;
			}

			// Download file
			var descriptorApplicationRequest:URLRequest = new URLRequest(descriptorApplicationURL);
			_updateStep = UpdateStep.DOWNLOAD_APPLICATION;
			_updateApplicationFileLoader.load(descriptorApplicationRequest);
		}

		private function toXML(data:*):XML
		{
			try
			{
				return new XML(data);
			}
			catch (e:Error)
			{
				return null;
			}
		}

		private function onUpdateDescriptorLoadError(e:Event):void
		{
			complete(UpdateStatus.UPDATE_DESCRIPTOR_DOWNLOAD_ERROR);
		}

		//
		// Step 2: Download application
		//
		private function onUpdateApplicationProgress(e:ProgressEvent):void
		{
			dispatchEvent(e);
		}

		private function onUpdateApplicationLoaded(e:Event):void
		{
			var bytes:ByteArray = ByteArray(_updateApplicationFileLoader.data);
			if (bytes == null || bytes.length == 0)
			{
				complete(UpdateStatus.UPDATE_APPLICATION_DOWNLOADED_WRONG_BYTES);
				return;
			}

			_updateApplicationFile = File.createTempFile();
			var written:Boolean = writeBytesToFile(_updateApplicationFile, bytes);
			if (written == false)
			{
				complete(UpdateStatus.UPDATE_APPLICATION_WRITE_ERROR);
				return;
			}

			_updater = new flash.desktop.Updater();
			_updater.update(_updateApplicationFile, _updateDescriptorVersion);
			complete(UpdateStatus.UPDATER_STARTED);
		}

		private function writeBytesToFile(file:File, data:ByteArray):Boolean
		{
			var stream:FileStream = new FileStream();
			var success:Boolean = false;

			try
			{
				stream.open(file, FileMode.WRITE);
				stream.writeBytes(data);
				success = true;
			}
			finally
			{
				stream.close();
				return success;
			}
		}

		private function onUpdateApplicationLoadError(e:Event):void
		{
			complete(UpdateStatus.UPDATE_APPLICATION_DOWNLOAD_ERROR);
		}

		//
		// Utils
		//
		private function complete(status:String):void
		{
			_updateStep = UpdateStep.NOP;
			_updateStatus = status;

			dispatchEvent(new Event(Event.COMPLETE));
		}

		//
		// Properties
		//
		public function get lastStatus():String { return _updateStatus; }
		public function get lastUpdaterVersion():String { return _updateDescriptorVersion; }
		public function get lastUpdaterDescription():String { return _updateDescriptorDescription; }
	}
}

class UpdateStep
{
	public static const NOP:int = 0;
	public static const DOWNLOAD_DESCRIPTOR:int = 1;
	public static const DOWNLOAD_APPLICATION:int = 2;
}

class UpdateStatus
{
	public static const UPDATE_DESCRIPTOR_DOWNLOAD_ERROR:String = "UPDATE_DESCRIPTOR_DOWNLOAD_ERROR";
	public static const UPDATE_DESCRIPTOR_WRONG_XML:String = "UPDATE_DESCRIPTOR_WRONG_XML";
	public static const UPDATE_DESCRIPTOR_VERSION_IS_LESS_OR_EQUALS:String = "UPDATE_DESCRIPTOR_VERSION_IS_LESS_OR_EQUALS";
	public static const UPDATE_DESCRIPTOR_WRONG_APPLICATION_URL:String = "UPDATE_DESCRIPTOR_WRONG_APPLICATION_URL";
	public static const UPDATE_DESCRIPTOR_LOADED:String = "UPDATE_DESCRIPTOR_LOADED";

	public static const UPDATE_APPLICATION_DOWNLOAD_ERROR:String = "UPDATE_APPLICATION_DOWNLOAD_ERROR";
	public static const UPDATE_APPLICATION_DOWNLOADED_WRONG_BYTES:String = "UPDATE_APPLICATION_DOWNLOADED_WRONG_BYTES";
	public static const UPDATE_APPLICATION_WRITE_ERROR:String = "UPDATE_APPLICATION_WRITE_ERROR";

	public static const UPDATER_IS_NOT_SUPPORTED:String = "UPDATER_IS_NOT_SUPPORTED";
	public static const UPDATER_STARTED:String = "UPDATER_STARTED";
}