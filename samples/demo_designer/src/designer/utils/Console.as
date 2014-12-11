package designer.utils
{
    import flash.display.*;
    import flash.events.*;
    import flash.filters.GlowFilter;
    import flash.geom.ColorTransform;
    import flash.net.SharedObject;
    import flash.system.Capabilities;
    import flash.text.*;
    import flash.ui.Keyboard;
    import flash.utils.setTimeout;

	/** Debug console utility. @author Alexandr Frolov. */
    public class Console extends Sprite
    {
		private static const FONT_NAME:String = "Consolas";
		private static const FONT_SIZE:int = 12;
		private static const FONT_COLOR:uint = 0x00E566;
		private static const TEXT_FORMAT:TextFormat = new TextFormat(FONT_NAME, FONT_SIZE, FONT_COLOR);
		private static const TEXT_FILTERS:Array = [new GlowFilter(FONT_COLOR, 0.3, 3, 3)];

		private static const MARKER:String = "> ";

		private static const BACKGROUND_TEXTURE:BitmapData = function():BitmapData
		{
			var bitmapData:BitmapData = new BitmapData(1, 2);
			bitmapData.setPixel(0, 0, 0);
			bitmapData.setPixel(0, 1, 0x121212);
			return bitmapData;
		}();

		private var commands:Object;
		
		private var historySharedObject:SharedObject;
		private var history:Array;
		private var historyIndex:int;

		private var consoleWidth:uint;
		private var consoleHeight:uint;

		private var background:Shape;
		private var input:TextField;
		private var output:TextField;
		private var marker:TextField;

		private var promptCallback:Function;

		public function Console()
		{
			initialize();
			createChildren();
			hide();
		}

		private function initialize():void
		{
			commands = new Object();
			addCommand("help", cmdConsoleHelp, "Print help information", "command-name");
			addCommand("cls", cmdConsoleClearScreen, "Clears the screen");
			addCommand("close", cmdConsoleClose, "Close console");
			
			historyIndex = -1;
			try
			{
				historySharedObject = SharedObject.getLocal("console");
				history = historySharedObject.data["history"] || new Array();
			}
			catch (e:Error)
			{
				history = new Array();
			}
		}

		//
		// Children methods
		//
		private function createChildren():void
		{
			background = new Shape();
			background.alpha = 0.8;
			addChild(background);

			output = new TextField();
			output.multiline = true;
			output.wordWrap = true;
			output.defaultTextFormat = TEXT_FORMAT;
			output.filters = TEXT_FILTERS;
			addChild(output);

			marker = new TextField();
			marker.autoSize = TextFieldAutoSize.LEFT;
			marker.selectable = false;
			marker.wordWrap = false;
			marker.defaultTextFormat = TEXT_FORMAT;
			marker.filters = TEXT_FILTERS;
			marker.text = MARKER;
			addChild(marker);

			input = new TextField();
			input.type = TextFieldType.INPUT;
			input.defaultTextFormat = TEXT_FORMAT;
			input.filters = TEXT_FILTERS;
			input.selectable = true;
			input.height = marker.height;
			input.restrict = "A-Za-z0-9 ._,':{}\"\\-+\*\$;[]()?";
			input.tabEnabled = false;
			addChild(input);

			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
			addEventListener(MouseEvent.CLICK, onClick);
		}

		private function arrange():void
		{
			// Output
			output.width = consoleWidth;
			output.height = consoleHeight - input.height;

			// Input
			arrangeInput();

			// Background
			with (background.graphics)
			{
				clear();
				beginBitmapFill(BACKGROUND_TEXTURE);
				drawRect(0, 0, consoleWidth, consoleHeight);
				endFill();
			}
		}

		private function arrangeInput():void
		{
			input.y = Math.min(output.height, Math.round(output.textHeight));
			marker.y = input.y;
			input.x = marker.width - 4; // 2px - harcoded textfield margin
			input.width = width - input.x;
		}

		//
		// Event handlers
		//
		private function onAddedToStage(e:Event):void
		{
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false, int.MAX_VALUE);
			stage.addEventListener(Event.RESIZE, onStageResize, false, int.MAX_VALUE);
			resizeTo(stage.stageWidth, stage.stageHeight);
		}

		private function onRemovedFromStage(e:Event):void
		{
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.removeEventListener(Event.RESIZE, onStageResize);
		}

		private function onStageResize(e:Event):void
		{
			resizeTo(stage.stageWidth, stage.stageHeight);
		}

		private function onClick(e:Event):void
		{
			if (output.selectionBeginIndex == output.selectionEndIndex)
			{
				focus();
			}
		}

		private function onKeyDown(e:KeyboardEvent):void
		{
			switch (e.keyCode)
			{
				case Keyboard.BACKQUOTE:
					visible ? hide() : show();
					break;
				case Keyboard.L:
					e.ctrlKey && clear();
					break;
				case Keyboard.U:
					e.ctrlKey && (input.text = "");
					break;
				case Keyboard.D:
					e.ctrlKey && hide();
					break;
				case Keyboard.C:
					e.ctrlKey && promptCallback != null && prompt("", null);
					break;
				case Keyboard.UP:
				case Keyboard.DOWN:
					if (history.length != 0)
					{
						historyIndex = historyIndex + (e.keyCode == Keyboard.UP ? +1 : -1);
						historyIndex = Math.max(historyIndex, 0);
						historyIndex = Math.min(historyIndex, history.length - 1);
						input.text = history[historyIndex];
						stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
					}
					break;
				case Keyboard.ENTER:
					var query:String = input.text;
					input.text = "";
					if (query.length != 0)
					{
						process(query);
					}
					break;
				case Keyboard.SPACE:
					// For not clear selection on autocompeting
					input.setSelection(input.text.length, input.text.length);
					break;
				case Keyboard.TAB:

					var args:Array;

					// Unhandled cases
					if (promptCallback != null) return;
					if (input.text.length == 0) return;
					args = input.text.split(" "); 
					if (args.length != 1) return;

					// Autocompelte results
					var resultText:String;
					var resultSelectionBeginIndex:int;
					var resultSelectionEndIndex:int;

					// Input parameters
					var arg0:String = args[0];
					var hasSelection:Boolean = input.selectionBeginIndex != input.selectionEndIndex;
					var base:String = hasSelection ? arg0.substring(0, input.selectionBeginIndex) : arg0;
					var variants:Array = new Array();

					// Searh autocompete variants
					for (var commandName:String in commands)
					{
						if (commandName.indexOf(base) == 0)
						{
							variants.push(commandName);
						}
					}

					// Try use one of variant 
					if (variants.length == 1)
					{
						resultText = variants[0];
						resultSelectionBeginIndex = resultSelectionEndIndex = resultText.length;
					}
					else if (variants.length > 0)
					{
						// Define next autocomplete variant
						variants.sort();
						var index:int = variants.indexOf(arg0);
						var next:int = (variants.length + index + (e.shiftKey ? -1 : +1)) % variants.length;
						resultText = variants[next];
						resultSelectionBeginIndex = base.length;
						resultSelectionEndIndex = resultText.length;

						// Print all variants if it is first autocompletion
						if (index == -1)
						{
							println("Variants:");

							for each (commandName in variants)
							{
								println("\t" + commandName);	
							}
						}
					}

					// Apply result
					if (resultText != null)
					{
						input.text = resultText;
						input.setSelection(resultSelectionBeginIndex, resultSelectionEndIndex);
					}

					break;
			}
		}

		public function process(query:String):void
		{
			//
			// Define prompt executor
			//
			if (promptCallback != null) 
			{
				// Need remove callback and text after call prompt function
				var disposePrompt:Boolean = true;

				try 
				{
					var result:* = promptCallback.call(null, query);
					disposePrompt = result == undefined || result == true;
				}
				catch (error:Error)
				{
					println(Capabilities.isDebugger ? error.getStackTrace() : error.message);
				}
				finally
				{
					if (disposePrompt)
					{
						promptCallback = null;
						marker.text = MARKER;
						arrangeInput();
					}

					return;
				}
			}

			//
			// Push to history
			//
			pushToHistory(query);
			
			//
			// Write to self
			//
			println(MARKER + query);

			//
			// Execute command
			//
			var commandName:String = query.split(" ")[0];
			var command:ConsoleCommand = commands[commandName];

			if (command == null) 
			{
				println("\'" + commandName + "\' is not recognized as command. Type \'help\' for more information.");
			}
			else 
			{
				try 
				{
					command.executor.length == 0
						? command.executor()
						: command.executor(query);
				}
				catch (error:Error)
				{
					println(Capabilities.isDebugger ? error.getStackTrace() : error.message);
					println("Usage: " + getCommandUsage(command));
				}
			}
		}
		
		private function pushToHistory(query:String):void
		{
			var index:int = history.indexOf(query);
			
			if (index != -1) 
			{
				history.splice(index, 1);
				history.unshift(query);
			}
			else 
			{
				history.unshift(query);
			}
			
			historyIndex = -1;
			
			try
			{
				if (historySharedObject != null)
				{
					historySharedObject.data["history"] = history;
					historySharedObject.flush()
				}
			} 
			catch (e:Error)
			{
				// NOP
			}
		}
		
		private function onEnterFrame(e:Event):void
		{
			// Move cursor to the end of text
			input.setSelection(input.text.length, input.text.length);
			stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		}

		//
		// Executors for default commands
		//
		private function cmdConsoleClearScreen(query:String):void
		{
			clear();
		}

		private function cmdConsoleClose(query:String):void
		{
			hide();
		}

		private function cmdConsoleHelp(query:String):void
		{
			//
			// Current command help
			//
			var command:ConsoleCommand;
			var commandName:String;
			var args:Array = query.split(" ");

			if (args.length > 1) 
			{
				commandName = args[1];
				command = commands[commandName];
				if (command != null) 
				{
					println("Usage: " + getCommandUsage(command));
					println(command.description);
				}
				else 
				{
					println("\'" + commandName + "\' is not recognized as command. Type \'help\' for more information.");
				}
			}
			else
			{
				println("For more information on specific command type \'help [command-name]\'");

				//
				// All commands help
				//
				var commandNamesArray:Array = new Array();

				for (commandName in commands) 
				{
					commandNamesArray.push(commandName);
				}

				commandNamesArray.sort();

				for each (commandName in commandNamesArray)
				{
					command = commands[commandName];
					println("\t" + commandName + " - " + command.description);
				}
			}
		}

		private function getCommandUsage(command:ConsoleCommand):String
		{
			var usage:String = command.name;

			for each (var param:String in command.params) 
			{
				usage = usage + (" [" + param + "]");
			}

			return usage;
		}

		//
		// Console control methods
		//
		public function addCommand(name:String, executor:Function, description:String, ...params):void
		{
			if (commands[name] == null) 
			{
				commands[name] = new ConsoleCommand(name, executor, description, Vector.<String>(params));
			}
		}

		public function removeCommand(name:String):void
		{
			delete commands[name];
		}

		public function resizeTo(width:uint, height:uint):void
		{
			consoleWidth = width;
			consoleHeight = height;
			arrange();
		}

		public function focus():void
		{
			if (stage != null) 
			{
				stage.focus = input;
			}
		}

		public function show():void
		{
			visible = true;
			mouseChildren = true;
			mouseEnabled = true;
			focus();
			dispatchEvent(new Event(Event.OPEN))
		}

		public function hide():void
		{
			visible = false;
			mouseChildren = false;
			mouseEnabled = false;
			if (stage) stage.focus = null;
			dispatchEvent(new Event(Event.CLOSE))
		}

		public function clear():void
		{
			output.text = "";
			arrange();
		}

		public function println(...args):void
		{
			print.apply(this, args);
			print("\n");
		}

		public function print(...args):void
		{
			output.appendText(args.join(" "));
			output.scrollV = output.numLines;
			arrangeInput();
		}

		public function prompt(promptText:String, promptHandler:Function):void
		{
			marker.text = promptText + MARKER;
			promptCallback = promptHandler;
			arrangeInput();
			show();
		}

		public function confirm(question:String, callback:Function, defaultAnswer:int = 0):void
		{
			println(question);
			prompt("yes/no", delegate(null, confirmCallback, callback));

			if (defaultAnswer != 0) 
			{
				input.text = defaultAnswer > 0 ? "yes" : "no";
				input.setSelection(0, input.text.length);
			}
		}

		private function confirmCallback(callback:Function, inputText:String):void
		{
			callback.call(null, inputText == "yes" || inputText == "y");
		}
    }
}

class ConsoleCommand
{
	public var name:String;
	public var executor:Function;
	public var description:String;
	public var params:Vector.<String>;

	public function ConsoleCommand(name:String, executor:Function, description:String, params:Vector.<String> = null)
	{
		this.name = name;
		this.executor = executor;
		this.description = description || "";
		this.params = params || new Vector.<String>();
	}
}

function delegate(thisArg:*, method:Function, ...methodArgs):Function
{
	return function (...rest):*
	{
		return method.apply(thisArg, methodArgs.concat(rest));
	}
}
