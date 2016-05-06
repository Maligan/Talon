package talon.browser.desktop.popups
{
	import feathers.events.FeathersEventType;

	import flash.text.TextFormatAlign;
	import flash.ui.Keyboard;

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.MeshBatch;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.extensions.TalonTextField;
	import starling.utils.Color;

	import talon.browser.desktop.popups.widgets.TalonFeatherTextInput;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.AppPlatformEvent;
	import talon.browser.platform.popups.Popup;
	import talon.browser.platform.utils.FuzzyUtil;
	import talon.browser.platform.utils.MouseWheel;

	public class GoToPopup extends Popup
	{
		// Data
		private var _items:Array;
		private var _query:String;
		private var _queryItems:Array;
		private var _cursor:int;

		// View
		private var _input:TalonFeatherTextInput;
		private var _labels:Vector.<TalonTextField>;
		private var _labelsShift:int;

		// Controller
		private var _app:AppPlatform;
		private var _wheel:MouseWheel;

		protected override function initialize():void
		{
			var view:DisplayObjectContainer = manager.factory.create("GoToPopup");
			addChild(view);

			_app = data as AppPlatform;
			_app.addEventListener(AppPlatformEvent.DOCUMENT_CHANGE, onDocumentChange);

			var source:Vector.<String> = _app.document.factory.templateIds;
			_items = new Array();
			for each (var template:String in source) _items.push(template);

			// ---------------------------------------------------------------------------
			_labels = new <TalonTextField>[];

			for (var i:int = 0; i < view.numChildren; i++)
			{
				var child:DisplayObject = view.getChildAt(i);
				if (child is TalonTextField) _labels.push(child as TalonTextField);
				else if (child is TalonFeatherTextInput) _input = child as TalonFeatherTextInput;
			}

			for each (var field:TalonTextField in _labels)
			{
				field.isHtmlText = true;
				field.addEventListener(TouchEvent.TOUCH, onLabelTouch);
			}

			_input.isEditable = true;
			_input.restrict = null;
			_input.maxChars = 60;
			_input.setFocus();
			_input.textFormat.align = TextFormatAlign.LEFT;
			_input.paddingLeft = 8; // 2px GAP!

			_input.addEventListener(Event.CHANGE, function():void
			{
				_query = _input.text;
				refresh();
			});

			_input.addEventListener(FeathersEventType.FOCUS_OUT, function():void {
				// FIXME: Much CPU load
				_input.setFocus();
			});

			addEventListener(KeyboardEvent.KEY_UP, function():void {
				_input.text = _input.text.replace(/[^\w\d_]/g, "");
			});
			// ---------------------------------------------------------------------------

			refresh();

			// Keyboard control
			addKeyboardListener(Keyboard.UP, moveCursorToPrev);
			addKeyboardListener(Keyboard.DOWN, moveCursorToNext);
			addKeyboardListener(Keyboard.ENTER, onEnterPress);
			addKeyboardListener(Keyboard.ESCAPE, close);

			// Mouse wheel control
			_wheel = new MouseWheel(this, _app.starling);
			_wheel.addEventListener(Event.TRIGGERED, onMouseWheel);
		}

		public override function dispose():void
		{
			super.dispose();
			_wheel.dispose();
			_wheel = null;
			_app.removeEventListener(AppPlatformEvent.DOCUMENT_CHANGE, onDocumentChange);
			_app = null;
		}

		//
		// Handlers
		//

		private function onDocumentChange():void
		{
			if (_app.document)
				refresh();
			else
				close();
		}

		private function onLabelTouch(e:TouchEvent):void
		{
			if (e.getTouch(e.target as DisplayObject, TouchPhase.ENDED))
			{
				var labelIndex:int = _labels.indexOf(e.currentTarget as TalonTextField);
				var itemIndex:int = _labelsShift + labelIndex;
				var templateId:String = _queryItems[itemIndex];
				if (templateId) commit(templateId);
			}
		}

		private function onEnterPress():void
		{
			// Open selected query
			if (_queryItems.length) commit(_queryItems[_cursor]);

			// Notify user
			else manager.notify();
		}

		private function onMouseWheel(e:Event):void
		{
			var delta:int = int(e.data);
			if (delta<0) moveCursorToNext();
			else if (delta>0) moveCursorToPrev();
		}

		//
		// Misc
		//
		private function commit(templateId:String):void
		{
			close();
			_app.templateId = templateId;
		}

		private function refresh():void
		{
			_query ||= "";
			_queryItems = FuzzyUtil.fuzzyFilter(_query, _items);

			_input.text = _query;
			cursorReset();
			refreshListText();
		}

		//
		// Cursor / List
		//
		private function refreshListText():void
		{
			for (var i:int = 0; i < _labels.length; i++)
			{
				var itemIndex:int = _labelsShift + i;
				var item:String = _queryItems[itemIndex] || "";

				_labels[i].text = item;

				if (item)
				{
					// Validate text field (for initialize inner meshBatch)
					_labels[i].textBounds;

					var meshBatch:MeshBatch = _labels[i].getChildAt(0) as MeshBatch;

					var numChars:int = meshBatch.numVertices/4;
					if (numChars == item.length)
					{
						var prescription:Array = FuzzyUtil.getPrescription(_query, item);

						// Reset color
						meshBatch.color = Color.WHITE;

						// Set char color
						for (var j:int = 0; j < numChars; j++)
						{
							var type:String = prescription[j];
							if (type == "M")
							{
								meshBatch.setVertexColor(j*4+0, 0x00BFFF);
								meshBatch.setVertexColor(j*4+1, 0x00BFFF);
								meshBatch.setVertexColor(j*4+2, 0x00BFFF);
								meshBatch.setVertexColor(j*4+3, 0x00BFFF);
							}
						}
					}
				}
			}
		}

		private function refreshListHighlight():void
		{
			for (var i:int = 0; i < _labels.length; i++)
			{
				if (_cursor == _labelsShift + i)
					_labels[i].node.accessor.classes.insert("selected");
				else
					_labels[i].node.accessor.classes.remove("selected");
			}
		}

		private function cursorReset():void
		{
			_labelsShift = 0;
			_cursor = _queryItems.length == 0 ? -1 : 0;
			refreshListHighlight();
		}

		private function moveCursorToNext():void
		{
			if (_queryItems.length > 0)
			{
				_cursor = (_cursor + 1) % _queryItems.length;
				refreshLabelShift();
				refreshListHighlight();
			}
		}

		private function moveCursorToPrev():void
		{
			if (_queryItems.length > 0)
			{
				if (_cursor == 0)
					_cursor = _queryItems.length - 1;
				else
					_cursor = (_cursor - 1) % _queryItems.length;

				refreshLabelShift();
				refreshListHighlight();
			}
		}

		private function refreshLabelShift():void
		{
			var labelBeginIndex:int = _labelsShift;
			var labelEndIndex:int = _labelsShift + _labels.length - 1;

			if (_cursor > labelEndIndex)
			{
				_labelsShift = _cursor - _labels.length + 1;
				refreshListText();
			}
			else if (_cursor < labelBeginIndex)
			{
				_labelsShift = _cursor;
				refreshListText();
			}
		}
	}
}