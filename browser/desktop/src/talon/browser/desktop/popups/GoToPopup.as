package talon.browser.desktop.popups
{
	import flash.ui.Keyboard;

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.MeshBatch;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.extensions.TalonTextField;
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
		private static const LAST_OFFSET:String = "GoToPopup.LAST_OFFSET";
		private static const LAST_CURSOR:String = "GoToPopup.LAST_CURSOR";

		// Data
		private var _items:Vector.<String>;
		private var _query:String;
		private var _queryItems:Vector.<String>;

		// View
		private var _input:TalonFeatherTextInput;
		private var _labels:Vector.<TalonTextField>;
		private var _labelsOffset:int;
		private var _labelsCursor:int;

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

			// read prev state
			var lastQuery:String = _app.document.properties.getValueOrDefault(LAST_QUERY, String, "");
			var lastOffset:int = _app.document.properties.getValueOrDefault(LAST_OFFSET, int, 0);
			var lastCursor:int = _app.document.properties.getValueOrDefault(LAST_CURSOR, int, 0);

			// reset prev state
			_app.document.properties.setValue(LAST_QUERY, "");
			_app.document.properties.setValue(LAST_OFFSET, 0);
			_app.document.properties.setValue(LAST_CURSOR, 0);

			// reset
			_input.text = lastQuery;
			_input.selectRange(0, lastQuery.length);
			refresh(lastQuery, lastOffset, lastCursor);
		}

		private function initializeChildren():void
		{
			removeChildren(0, -1, true);
			var view:DisplayObjectContainer = manager.factory.createElement("GoToPopup") as DisplayObjectContainer;
			addChild(view);

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
			{
				_items = _app.document.factory.templateIds;
				refresh(_query);
			}
			else
				close();
		}

		private function onLabelTouch(e:TouchEvent):void
		{
			if (e.getTouch(e.target as DisplayObject, TouchPhase.ENDED))
			{
				var labelIndex:int = _labels.indexOf(e.currentTarget as TalonTextField);
				var itemIndex:int = _labelsOffset + labelIndex;
				var templateId:String = itemIndex < _queryItems.length ? _queryItems[itemIndex] : null;
				if (templateId) commit(templateId);
			}
		}

		private function onEnterPress():void
		{
			// Open selected query
			if (_queryItems.length) commit(_queryItems[_labelsCursor]);

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
			_app.document.properties.setValue(LAST_OFFSET, _labelsOffset);
			_app.document.properties.setValue(LAST_CURSOR, _labelsCursor);

			_app.templateId = templateId;
			close();
		}

		private function refresh(query:String = null, offset:int = 0, cursor:int = 0):void
		{
			_query = query || "";
			_queryItems = FuzzyUtil.fuzzyFilter(_query, _items);

			_labelsCursor = -1;
			_labelsOffset = -1;

			refreshList(offset, cursor);
		}

		private function refreshList(offset:int = 0, cursor:int = 0):void
		{
			// restrain

			var numLabels:int = _labels.length;
			var numItems:int = _queryItems.length;
			if (numItems == 0)
			{
				offset =  0;
				cursor = -1;
			}
			else
			{
				offset = (offset + numItems) % numItems;
				cursor = (cursor + numItems) % numItems;

				offset = Math.min(offset, cursor);
				offset = Math.max(offset, cursor - (numLabels-1));
			}

			// draw

			if (_labelsOffset != offset)
			{
				_labelsOffset = offset;
				updateTexts();
			}

			if (_labelsCursor != cursor)
			{
				_labelsCursor = cursor;
				updateCursor();
			}
		}

		// Cursor / List

		private function updateTexts():void
		{
			for (var i:int = 0; i < _labels.length; i++)
			{
				var label:TalonTextField = _labels[i];
				var labelStyle:MeshStyle = label.style;

				var itemIndex:int = _labelsOffset + i;
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

		private function updateCursor():void
		{
			for (var i:int = 0; i < _labels.length; i++)
			{
				if (_labelsCursor == _labelsOffset + i)
					_labels[i].node.classes.insert("selected");
				else
					_labels[i].node.classes.remove("selected");
			}
		}

		private function moveCursorToNext():void { refreshList(_labelsOffset, _labelsCursor + 1); }
		private function moveCursorToPrev():void { refreshList(_labelsOffset, _labelsCursor - 1); }
	}
}