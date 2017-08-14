package talon.browser.desktop.utils
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	public class GithubUpdater
	{
		private var _url:String;
		private var _versionNumber:String;
		
		public function GithubUpdater(repo:String = "maligan/talon", versionNumber:String = "0.0.0")
		{
			_url = "https://api.github.com/repos/" + repo + "/releases";
			_versionNumber = versionNumber;
		}
		
		public function check(prerelease:Boolean = true):Promise
		{
			var promise:Promise = new Promise();

			var request:URLRequest = new URLRequest(_url);
			var loader:URLLoader = new URLLoader(request);
			loader.addEventListener(Event.COMPLETE, onEvent);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onEvent);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onEvent);
			
			function onEvent(e:Event):void
			{
				loader.removeEventListener(Event.COMPLETE, onEvent);
				loader.removeEventListener(IOErrorEvent.IO_ERROR, onEvent);
				loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onEvent);
				
				if (e.type != Event.COMPLETE) promise.reject(new Error(ErrorEvent(e).text, ErrorEvent(e).errorID));
				else
				{
					try
					{
						var json:Array = JSON.parse(loader.data.toString()) as Array;
						var releases:Vector.<GithubRelease> = new <GithubRelease>[];

						for each (var releaseObject:Object in json)
						{
							var release:GithubRelease = new GithubRelease();
							release.url = releaseObject["html_url"];
							release.version = releaseObject["tag_name"].substr(1);
							release.prerelease = releaseObject["prerelease"];
							if (prerelease) releases.push(release);
						}
						
						releases.sort(compareGithubRelease);

						var latest:GithubRelease = releases.pop();
						if (latest != null && compare(latest.version, _versionNumber) > 0)
							promise.fulfill(latest.url);
						else
							promise.fulfill(null);
					}
					catch (error:Error)
					{
						promise.reject(error);
					}
				}
			}
			
			return promise;
		}

		private function compareGithubRelease(release1:GithubRelease, release2:GithubRelease):int
		{
			return compare(release1.version, release2.version);
		}
		
		private function compare(version1:String, version2:String):int
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
	}
}

class GithubRelease
{
	public var url:String;
	public var version:String;
	public var prerelease:Boolean;
}
