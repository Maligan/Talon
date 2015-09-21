package browser
{
	import flash.desktop.NativeApplication;
	import flash.display.MovieClip;
	import flash.events.InvokeEvent;
	import flash.geom.Point;
	import flash.utils.getTimer;

	import starling.events.Event;

	import talon.utils.StringUtil;

	[SWF(frameRate="60")]
	public class AppLauncher extends MovieClip
	{
		private var _overlay:MovieClip;
		private var _controller:AppController;
		private var _invoke:String;
		private var _backgroundColor:SharedString;

		public function AppLauncher()
		{
			var str:String = new XML(
				<node><![CDATA[
				appWidth=530
				#CheckForUpdates
				titleCheck=Nach Updates suchen
				msgCheck=Zulassen, dass die Anwendung nach Updates sucht?
				btnCheck=Nach Updates suchen
				btnCancel=Abbrechen

				#CheckForUpdates - No updates available
				titleCheckNoUpdates=Keine Updates verf?gbar
				msgCheckNoUpdates=F?r die Anwendung sind keine Updates verf?gbar.
				btnClose=Schlie?en

				#CheckForUpdates - Connection Error
				titleCheckError=Updatefehler
				msgCheckError=Fehler beim Suchen nach Updates. Fehlernr. {0}

				#UpdateAvailable
				titleUpdate=Update verf?gbar
				msgUpdate=Eine aktualisierte Version der Anwendung kann aus dem Internet heruntergeladen werden.
				lblApplication=Anwendung:
				lblInstalledVersion=Installierte Version:
				lblAvailableVersion=Updateversion:
				btnDownload=Jetzt herunterladen
				btnDownloadLater=Sp?ter herunterladen
				lnkReleaseNotes=Versionshinweise

				#DownloadProgress
				titleProgress=Downloadfortschritt...
				msgProgress=Update wird heruntergeladen

				#DownloadError
				titleDownloadError=Download fehlgeschlagen
				msgDownloadError=Beim Herunterladen des Updates ist ein Fehler aufgetreten. Fehlernr. {0}

				#InstallUpdate
				titleInstall=Update installieren
				msgInstall=Das Update f?r die Anwendung wurde heruntergeladen und kann installiert werden.
				btnInstall=Jetzt installieren
				btnInstallLater=Nach dem Neustart

				#UnexpectedError
				titleUnexpectedError=Unerwarteter Fehler
				msgUnexpectedError=Ein unerwarteter Fehler ist aufgetreten. Fehlernr. {0}

				#File - Update Available
				titleFileUpdate=Update verf?gbar
				msgFileUpdate=Die \
				Datei enth?lt eine aktualisierte Version der Anwendung. Installieren?
				lblFile=Dat\
				ei:


				#File - No updates available
				titleFileNoUpdate=Kein Update verf?gbar
				msgFileNoUpdate=Die Datei enth?lt keine neuere Version der Anwendung.

				#File - Error
				ti tleFileError=Dateifehler
				msgFileError=Bei Validieren der Updatedatei ist ein Fehler aufgetreten. Fehlernr. {0}

				#Title window
				titleWindow=Aktualisieren:
				]]></node>).valueOf();

			var count:int = 10000;

			var prop:Object = StringUtil.parseProperties(str);


//			trace(test(parse, str, count));
//			trace(test(StringUtil.parseProperties, str, count));

			_backgroundColor = new SharedString("backgroundColor", AppConstants.SETTING_BACKGROUND_DEFAULT);
			stage ? initialize() : addEventListener(Event.ADDED_TO_STAGE, initialize);
		}

		private function test(func:Function, str:String, count:int):int
		{
			var timer:uint = getTimer();

			for (var i:int = 0; i < count; i++)
				func(str);

			return getTimer() - timer;
		}


		/** Simple Properties file format parser. */
		private function parse(string:String):Object
		{
			var result:Object = new Object();
			var values:Array = string.split(/[\n\r]/);
			var pattern:RegExp = /\s*([\w\.]+)\s*\=\s*(.*)\s*$/;

			for each (var line:String in values)
			{
				var property:Array = pattern.exec(line);
				if (property)
				{
					var key:String = property[1];
					var value:String = property[2];
					result[key] = value;
				}
			}

			return result;
		}


		private function initialize(e:* = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, initialize);

			stage.color = AppConstants.SETTING_BACKGROUND_STAGE_COLOR[_backgroundColor.value];
			stage.nativeWindow.minSize = new Point(200, 100);
			stage.addEventListener(Event.RESIZE, onResize);

//			NativeApplication.nativeApplication.setAsDefaultApplication(AppConstants.DESIGNER_FILE_EXTENSION);
			NativeApplication.nativeApplication.addEventListener (InvokeEvent.INVOKE, onInvoke);

			// For native drag purpose
			_overlay = new MovieClip();
			addChild(_overlay);
			onResize(null);

			_controller = new AppController(this);
			_controller.settings.addPropertyListener(AppConstants.SETTING_BACKGROUND, onBackgroundChanged);
		}

		private function onBackgroundChanged():void
		{
			_backgroundColor.value = _controller.settings.getValueOrDefault(AppConstants.SETTING_BACKGROUND, String, AppConstants.SETTING_BACKGROUND_DEFAULT);
		}

		private function onResize(e:*):void
		{
			_overlay.graphics.clear();
			_overlay.graphics.beginFill(0, 0);
			_overlay.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			_overlay.graphics.endFill();
		}

		private function onInvoke(e:InvokeEvent):void
		{
			if (e.arguments.length > 0)
			{
				_invoke = e.arguments[0];
				_controller && _controller.invoke(_invoke);
			}
		}
	}
}

import flash.net.SharedObject;

class SharedString
{
	private var _sharedObject:SharedObject;

	public function SharedString(key:String, initial:String)
	{
		_sharedObject = SharedObject.getLocal(key);

		if (_sharedObject.data["value"] == undefined)
		{
			_sharedObject.data["value"] = initial;
		}
	}

	public function get value():String { return _sharedObject.data["value"]; }

	public function set value(string:String):void
	{
		try
		{
			_sharedObject.data["value"] = string;
			_sharedObject.flush();
		}
		catch (e:Error)
		{
			// NOPE
		}
	}
}
