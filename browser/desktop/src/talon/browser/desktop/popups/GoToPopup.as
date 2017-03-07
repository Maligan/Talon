package talon.browser.desktop.popups
{
	import feathers.events.FeathersEventType;

	import flash.ui.Keyboard;

	import starling.core.Starling;

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.MeshBatch;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.extensions.TalonTextFieldElement;
	import starling.styles.MeshStyle;

	import talon.browser.desktop.popups.widgets.TalonFeatherTextInput;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.AppPlatformEvent;
	import talon.browser.platform.popups.Popup;
	import talon.browser.platform.utils.FuzzyUtil;
	import talon.browser.platform.utils.MouseWheel;

	public class GoToPopup extends Popup
	{
		private static const LAST_QUERY:String = "GoToPopup.LAST_QUERY";

		// Data
		private var _items:Vector.<String>;
		private var _query:String;
		private var _queryItems:Vector.<String>;
		private var _cursor:int;

		// View
		private var _input:TalonFeatherTextInput;
		private var _labels:Vector.<TalonTextFieldElement>;
		private var _labelsShift:int;

		// Controller
		private var _app:AppPlatform;
		private var _wheel:MouseWheel;

		protected override function initialize():void
		{
			initializeChildren();

			_app = data as AppPlatform;
			_app.addEventListener(AppPlatformEvent.DOCUMENT_CHANGE, onDocumentChange);
			_items = _app.document.factory.templateIds;

			// Keyboard control
			addKeyboardListener(Keyboard.UP, moveCursorToPrev);
			addKeyboardListener(Keyboard.DOWN, moveCursorToNext);
			addKeyboardListener(Keyboard.ENTER, onEnterPress);
			addKeyboardListener(Keyboard.ESCAPE, close);

			// Mouse wheel control
			_wheel = new MouseWheel(this, _app.starling);
			_wheel.addEventListener(Event.TRIGGERED, onMouseWheel);

			var lastQuery:String = _app.document.properties.getValueOrDefault(LAST_QUERY, String, "");
			_app.document.properties.setValue(LAST_QUERY, "");
			_input.text = lastQuery;
			_input.selectRange(0, lastQuery.length);
			refresh(lastQuery);
		}

		private function initializeChildren():void
		{
			removeChildren(0, -1, true);
			var view:DisplayObjectContainer = manager.factory.createElement("GoToPopup") as DisplayObjectContainer;
			addChild(view);

			_labels = new <TalonTextFieldElement>[];

			for (var i:int = 0; i < view.numChildren; i++)
			{
				var child:DisplayObject = view.getChildAt(i);
				if (child is TalonTextFieldElement) _labels.push(child as TalonTextFieldElement);
				else if (child is TalonFeatherTextInput) _input = child as TalonFeatherTextInput;
			}

			for each (var field:TalonTextFieldElement in _labels)
			{
				field.isHtmlText = true;
				field.addEventListener(TouchEvent.TOUCH, onLabelTouch);
			}

			_input.isEditable = true;
			_input.restrict = null;
			_input.maxChars = 60;
			_input.setFocus();

			_input.addEventListener(Event.CHANGE, function():void
			{
				refresh(cleanUp(_input.text));
			});

			addEventListener(KeyboardEvent.KEY_UP, function():void
			{
				_input.text = cleanUp(_input.text);
			});

			function cleanUp(text:String):String
			{
				return text.replace(/[^\w\d_]/g, "");
			}
		}

		public override function dispose():void
		{
			_wheel.dispose();
			_wheel = null;
			_app.removeEventListener(AppPlatformEvent.DOCUMENT_CHANGE, onDocumentChange);
			_app = null;
			super.dispose();
		}

		// Handlers

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
				var labelIndex:int = _labels.indexOf(e.currentTarget as TalonTextFieldElement);
				var itemIndex:int = _labelsShift + labelIndex;
				var templateId:String = itemIndex < _queryItems.length ? _queryItems[itemIndex] : null;
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

		// Misc

		private function commit(templateId:String):void
		{
			_app.document.properties.setValue(LAST_QUERY, _query);
			_app.templateId = templateId;
			close();
		}

		private function refresh(query:String = null):void
		{
			_query = query || "";
			_queryItems = FuzzyUtil.fuzzyFilter(_query, _items);

			cursorReset();
			refreshListText();
		}

		// Cursor / List

		private function refreshListText():void
		{
			for (var i:int = 0; i < _labels.length; i++)
			{
				var label:TalonTextFieldElement = _labels[i];
				var labelStyle:MeshStyle = label.style;

				var itemIndex:int = _labelsShift + i;
				var item:String = itemIndex < _queryItems.length ? _queryItems[itemIndex] : "";

				label.batchable = false;

				// Invalidation & composition (via textBounds)
				label.text = null;
				label.text = item;
				label.textBounds;

				if (item)
				{
					var prescription:Array = FuzzyUtil.getPrescription(_query.toLocaleLowerCase(), item.toLocaleLowerCase());

					// Set char color
					for (var j:int = 0; j < item.length; j++)
					{
						var type:String = prescription[j];
//						if (type == "M")
						{
							labelStyle.setVertexColor(j*4+0, 0x00BFFF);
							labelStyle.setVertexColor(j*4+1, 0x00BFFF);
							labelStyle.setVertexColor(j*4+2, 0x00BFFF);
							labelStyle.setVertexColor(j*4+3, 0x00BFFF);
						}
					}

					MeshBatch(labelStyle.target).setVertexDataChanged();
				}
			}
		}

		private function refreshListHighlight():void
		{
			for (var i:int = 0; i < _labels.length; i++)
			{
				if (_cursor == _labelsShift + i)
					_labels[i].node.classes.insert("selected");
				else
					_labels[i].node.classes.remove("selected");
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