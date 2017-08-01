package talon.browser.platform.document.log
{
	public class DocumentMessageCollection
	{
		private var _messages:Vector.<DocumentMessage> = new <DocumentMessage>[];

		public function addMessage(message:DocumentMessage):void
		{
			if (_messages.indexOf(message) == -1)
				_messages.push(message);
		}
		
		public function removeMessagesByNumber(number:int):void
		{
			var i:int = 0;
			
			while (i < _messages.length)
			{
				if (_messages[i].number == number)
					_messages.removeAt(i);
				else
					i++
			}
		}

		public function removeMessage(message:DocumentMessage):void
		{
			var indexOf:int = _messages.indexOf(message);
			if (indexOf != -1) _messages.removeAt(indexOf);
		}

		public function getMessageAt(index:int):DocumentMessage
		{
			return _messages[index];
		}

		public function get numMessages():int
		{
			return _messages.length;
		}
	}
}