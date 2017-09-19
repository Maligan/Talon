package talon.browser.desktop.utils
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;

	public class TexturePacker
	{
		private var _processes:Vector.<NativeProcess> = new <NativeProcess>[];
		
		private var _exec:File;
		private var _args:Array;
		private var _temp:File;
		private var _data:String;

		public function TexturePacker(exec:File)
		{
			_processes = new <NativeProcess>[];
			_exec = exec;
		}
		
		public function init(temp:File, data:String, args:String):void
		{
			_temp = temp;
			_data = data;
			_args = args ? args.split(" ") : [];
		}

		/** Return Vector.<Files> into fulfill() or Error into reject(). */
		public function exec(files:Vector.<File>):Promise
		{
			var promise:Promise = new Promise();

			// Errors
			if (files.length == 0)
			{
				promise.fulfill(new <File>[]);
				return promise;
			}
			
			if (!NativeProcess.isSupported)
			{
				promise.reject(new Error("AIR_CAN'T_START_PROCESS"));
				return promise;
			}
			
			if (!_exec.exists)
			{
				promise.reject(new Error("TEXTURE_PACKER_BIN_NOT_FOUND"));
				return promise;
			}
			
			// Prepare
			var processInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			
			try { processInfo.executable = _exec; }
			catch (e:Error) { promise.reject(e); return promise }
			
			processInfo.arguments.push("--data", _temp.nativePath + File.separator + _data);
			processInfo.arguments.push.apply(null, _args);

			for each (var file:File in files)
				processInfo.arguments[processInfo.arguments.length] = file.nativePath;

			// Start
			var processError:String = "";
			var process:NativeProcess = new NativeProcess();
			process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onProcessError);
			process.addEventListener(NativeProcessExitEvent.EXIT, onProcessExit);
			process.addEventListener(NativeProcessExitEvent.EXIT, onProcessExit);

			try { process.start(processInfo); _processes.push(process) }
			catch (e:Error) { promise.reject(e); }

			function onProcessError(e:ProgressEvent):void
			{
				processError += process.standardError.readUTFBytes(process.standardError.bytesAvailable);
			}

			function onProcessExit(e:NativeProcessExitEvent):void
			{
				var indexOf:int = _processes.indexOf(process);
				_processes.removeAt(indexOf);
				
				if (e.exitCode != 0)
				{
					promise.reject(new Error(processError, e.exitCode));
				}
				else
				{
					var files:Vector.<File> = null;
					
					try { files = Vector.<File>(_temp.getDirectoryListing()) }
					catch (e:Error) { promise.reject(e); return; }

					promise.fulfill(files);
				}
			}

			return promise;
		}
		
		public function stop():void
		{
			for each (var process:NativeProcess in _processes)
				process.exit(true);
		}
	}
}
